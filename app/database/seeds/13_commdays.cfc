component extends="base" {

    function run(qb, mockdata) {
        var pastCommunityDays = deserializeJSON(fileRead('resources/commdays.json'));

        pastCommunityDays.each((commDay) => {
            // 1. Get the comm day featured pokemon
            var pokemonid = getByNameAndGender(
                name   = toUTF8(commDay.name),
                gender = commDay.keyExists('gender') ? commDay.gender : ''
            );

            // 2. Get all the comm day's evolutions
            var evolutionIds = getEvolutionChainIds(pokemonid = pokemonid);

            // 3. Create the event
            var eventName = commDay.KeyExists('eventname') ? '#commDay.name# #commDay.eventname#' : '#commDay.name# Community Day';
            var customid  = createEventRecord(
                name   = eventName,
                begins = parseDateTime(commDay.date),
                ends   = parseDateTime(commDay.date)
            );

            // 4. Create the event spawns
            evolutionIds.append(pokemonid)
            insertEventSpawns(customid = customid, pokemon = evolutionIds);
        });
    }

    /**
     * Get a pokemon reco by name a gender
     *
     * @name   pokemon name
     * @gender pokemon gender
     */
    private numeric function getByNameAndGender(required string name, required string gender) {
        return queryExecute(
            '
            SELECT id
            FROM pokemon
            WHERE name = :name
                AND gender = :gender
                AND costume = :costume
                AND costumetype = :costumetype
            ',
            {
                name       : {value: name, cfsqltype: 'varchar'},
                gender     : {value: gender, cfsqltype: 'varchar'},
                costume    : {value: false, cfsqltype: 'boolean'},
                costumetype: {value: '', cfsqltype: 'varchar'}
            }
        ).id;
    }

    /**
     * Get the ids of all pokemon this pokemon evolves into, directly or transitively
     *
     * @pokemonid pokemon id
     */
    private array function getEvolutionChainIds(required numeric pokemonid) {
        var results = queryExecute(
            '
            WITH RECURSIVE evolution_chain AS (
                SELECT evolutionid, special
                FROM evolution
                WHERE pokemonid = :pokemonid

                UNION ALL

                SELECT e.evolutionid, e.special
                FROM evolution e
                INNER JOIN evolution_chain ec ON e.pokemonid = ec.evolutionid
            )
            SELECT DISTINCT evolutionid
            FROM evolution_chain
            WHERE special = false
            ',
            {pokemonid: {value: pokemonid, cfsqltype: 'integer'}}
        );

        return valueArray(results, 'evolutionid');
    }

    /**
     * Create a custom event record
     *
     * @trainerid trainer id creating the event
     * @name      event name
     * @begins    event start datetime
     * @ends      event end datetime
     */
    private numeric function createEventRecord(
        required string name,
        required date begins,
        required date ends
    ) {
        var result = queryExecute(
            '
        INSERT INTO custom (name, public, begins, ends, trainerid, created, updated, commday)
        VALUES (:name, true, :begins, :ends, :trainerid, now(), now(), true)
        RETURNING id
        ',
            {
                name     : {value: name, cfsqltype: 'varchar'},
                begins   : {value: begins, cfsqltype: 'timestamp'},
                ends     : {value: ends, cfsqltype: 'timestamp'},
                trainerid: {value: 1, cfsqltype: 'integer'}
            }
        );

        return result.id;
    }

    /**
     * Insert pokemon ids as event spawns for a custom event, skipping ones already present
     *
     * @customid custom event id
     * @pokemon  array of pokemon ids to spawn in this event
     */
    private void function insertEventSpawns(required numeric customid, required array pokemon) {
        pokemon.each((pokemonid) => {
            queryExecute(
                '
                INSERT INTO custompokedex (customid, pokemonid, created, updated)
                SELECT :customid, :pokemonid, now(), now()
                WHERE NOT EXISTS (
                    SELECT 1 FROM custompokedex
                    WHERE customid = :customid
                    AND pokemonid = :pokemonid
                )
                ',
                {customid: {value: customid, cfsqltype: 'integer'}, pokemonid: {value: pokemonid, cfsqltype: 'integer'}}
            );
        });

        return;
    }

}
