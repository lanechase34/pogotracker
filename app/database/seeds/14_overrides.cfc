component extends="base" {

    function run(qb, mockdata) {
        var pokedexOverrides = super.getPokedexOverrides();

        queryExecute(
            "
            INSERT INTO overrides (name, override)
            VALUES (:name, CAST(:override AS jsonb))
            ",
            {
                name    : {value: "envpokedexoverrides", cfsqltype: "varchar"},
                override: {value: serializeJSON(pokedexOverrides), cfsqltype: "varchar"}
            }
        );
    }

}
