component extends="coldbox.system.testing.BaseTestCase" {

    /**
     * The pokemon in a custom pokedex, as structs of pokemonid, name, gender, costume, costumetype
     *
     * @customid custom pk
     */
    public array function getMembers(required numeric customid) {
        return queryExecute(
            "
            SELECT pokemon.id AS pokemonid, pokemon.name, pokemon.gender, pokemon.costume, COALESCE(pokemon.costumetype, '') AS costumetype
            FROM custompokedex
            INNER JOIN pokemon ON pokemon.id = custompokedex.pokemonid
            WHERE custompokedex.customid = :customid
            ORDER BY pokemon.id ASC
            ",
            {customid: {value: arguments.customid, cfsqltype: "integer"}},
            {returnType: "array"}
        );
    }

    /**
     * The ids of the pokemon in a custom pokedex, ascending
     *
     * @customid custom pk
     */
    public array function getMemberIds(required numeric customid) {
        return getMembers(arguments.customid).map((member) => member.pokemonid);
    }

    public numeric function getMostRecentCreated() {
        return queryExecute(
            "
            SELECT MAX(id) AS id
            FROM custom
            "
        ).id;
    }

    public void function deleteByName(required string name) {
        var customid = queryExecute(
            "
            SELECT id
            FROM custom
            WHERE name = :name
            ",
            {name: {value: arguments.name, cfsqltype: "varchar"}}
        ).id;

        if(customid.len()) {
            queryExecute(
                "
                DELETE FROM custompokedex
                WHERE customid = :customid
                ",
                {customid: {value: customid, cfsqltype: "integer"}}
            );

            queryExecute(
                "
                DELETE FROM custom
                WHERE id = :customid
                ",
                {customid: {value: customid, cfsqltype: "integer"}}
            );
        }

        return;
    }

}
