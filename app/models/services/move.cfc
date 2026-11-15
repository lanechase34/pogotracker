component singleton accessors="true" {

    property name="cache" inject="cachebox:appCache";

    // Columns a move row is read with - the query must select from move
    variables.MOVE_COLUMNS = "
        move.id, move.nameid, move.name, move.type, move.damage, move.energy, move.turns, move.buffself,
        move.buffchance, COALESCE(move.buffeffect, '') AS buffeffect
    ";

    public string function getMoveColumns() {
        return variables.MOVE_COLUMNS;
    }

    /**
     * A move row as the app uses it - its columns plus
     * damageperenergy, damageperturn, energyperturn ("--" when they can't be worked out),
     * buff (blank when it has none), typeimg and typeimgalttext
     *
     * @row a row selected with move columns
     */
    public struct function toMove(required struct row) {
        var move             = arguments.row;
        move.damageperenergy = move.energy == 0 ? "--" : round(move.damage / move.energy, 2);
        move.damageperturn   = !move.turns ? "--" : round(move.damage / move.turns, 2);
        move.energyperturn   = !move.turns ? "--" : round(move.energy / move.turns, 2);
        move.buff            = move.buffchance == 0
         ? ""
         : "#move.buffchance * 100#% chance | #move.buffeffect# #move.buffself ? "Self" : "Opponent"#";
        move.typeimg        = "/includes/images/typeicon/#lCase(move.type)#.webp";
        move.typeimgalttext = "#ucFirst(move.type)# type icon";
        return move;
    }

    /**
     * Whether a move is a dynamax only "plus" move - these are never imported or attached to a pokemon
     * pvpoke ids them NAME_PLUS (named "Name+"), pokemondb and the overrides write them NAME+
     *
     * @nameid move id, as pvpoke, the scrape or an override has it
     */
    public boolean function isDynamaxOnly(required string nameid) {
        return reFind("(\+|_PLUS)$", trim(arguments.nameid)) > 0;
    }

    /**
     * Create the move, or update it when one with the nameid exists (unq_move_nameid)
     *
     * @moveProperties nameid, name, type, damage, energy, turns, buffSelf, buffChance, buffEffect
     */
    public void function upsertMove(required struct moveProperties) {
        var props = arguments.moveProperties;
        queryExecute(
            "
            INSERT INTO move (nameid, name, type, damage, energy, turns, buffself, buffchance, buffeffect)
            VALUES (:nameid, :name, :type, :damage, :energy, :turns, :buffself, :buffchance, :buffeffect)
            ON CONFLICT (nameid) DO UPDATE SET
                name       = excluded.name,
                type       = excluded.type,
                damage     = excluded.damage,
                energy     = excluded.energy,
                turns      = excluded.turns,
                buffself   = excluded.buffself,
                buffchance = excluded.buffchance,
                buffeffect = excluded.buffeffect
            ",
            {
                nameid: {value: props.nameid, cfsqltype: "varchar"},
                name  : {value: props.name, cfsqltype: "varchar"},
                type  : {value: props.type, cfsqltype: "varchar"},
                damage: {
                    value    : props.damage,
                    cfsqltype: "decimal",
                    scale    : 2
                },
                energy: {
                    value    : props.energy,
                    cfsqltype: "decimal",
                    scale    : 2
                },
                turns: {
                    value    : props.turns,
                    cfsqltype: "decimal",
                    scale    : 2
                },
                buffself  : {value: props.buffSelf ? true : false, cfsqltype: "boolean"},
                buffchance: {
                    value    : props.buffChance,
                    cfsqltype: "decimal",
                    scale    : 4
                },
                buffeffect: {value: props.buffEffect ?: "", cfsqltype: "varchar"}
            }
        );
        return;
    }

    /**
     * Every fast move (turns > 0), by name
     */
    public array function getAllFastMoves() {
        return cache.getOrSet(
            getFastMovesCacheKey(),
            () => findMoves("move.turns > 0"),
            720,
            720
        );
    }

    /**
     * Every charge move (turns = 0), by name
     */
    public array function getAllChargeMoves() {
        return cache.getOrSet(
            getChargeMovesCacheKey(),
            () => findMoves("move.turns = 0"),
            720,
            720
        );
    }

    /**
     * Evict the cached fast and charge move lists so the next load reads the database
     * Call after anything that changes the moves
     */
    public void function clearCache() {
        cache.clear(getFastMovesCacheKey());
        cache.clear(getChargeMovesCacheKey());
        return;
    }

    /**
     * Cache key for the move list getAllFastMoves loads
     */
    private string function getFastMovesCacheKey() {
        return "move.getAllFastMoves";
    }

    /**
     * Cache key for the move list getAllChargeMoves loads
     */
    private string function getChargeMovesCacheKey() {
        return "move.getAllChargeMoves";
    }

    /**
     * Moves matching the where clause, by name (see toMove)
     */
    private array function findMoves(required string whereSQL, struct params = {}) {
        return queryExecute(
            "
            SELECT #variables.MOVE_COLUMNS# 
            FROM move 
            WHERE #arguments.whereSQL# 
            ORDER BY move.name ASC, move.id ASC
            ",
            arguments.params,
            {returnType: "array"}
        ).map((row) => toMove(row));
    }

    /**
     * Every move keyed by its nameid, in one query - for imports that look up many moves
     *
     * @return {nameid: move (see toMove)}
     */
    public struct function getMovesByNameId() {
        return findMoves("true").reduce((result, move) => {
            result[move.nameid] = move;
            return result;
        }, {});
    }

    /**
     * Add the moves the pokemon doesn't have yet, in one statement - a move it already has (unq_pokemonmove_pokemonid_moveid) is left as is
     * Rows go in the order given, so pokemonmove.id keeps the moves' order
     *
     * @pokemon pokemon struct
     * @moves   array of {move (struct), shadow, legacy}
     */
    public void function updatePokemonMoves(required struct pokemon, required array moves) {
        if(!arguments.moves.len()) return;

        var params = {pokemonid: {value: arguments.pokemon.id, cfsqltype: "integer"}};
        var rows   = [];
        arguments.moves.each((move, i) => {
            rows.append("(:pokemonid, :moveid#i#, :shadow#i#, :legacy#i#)");
            params["moveid#i#"] = {value: move.move.id, cfsqltype: "integer"};
            params["shadow#i#"] = {value: move.shadow ? true : false, cfsqltype: "boolean"};
            params["legacy#i#"] = {value: move.legacy ? true : false, cfsqltype: "boolean"};
        });

        queryExecute(
            "
            INSERT INTO pokemonmove (pokemonid, moveid, shadow, legacy)
            VALUES #rows.toList(", ")#
            ON CONFLICT (pokemonid, moveid) DO NOTHING
            ",
            params
        );
        return;
    }

}
