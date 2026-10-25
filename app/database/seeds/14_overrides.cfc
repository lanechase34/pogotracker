component extends="base" {

    function run(qb, mockdata) {
        var pokedexOverrides = super.getPokedexOverrides();

        queryExecute(
            '
            insert into overrides (name, override)
            values (:name, cast(:override as jsonb))
            ',
            {
                name    : {value: 'envpokedexoverrides', cfsqltype: 'varchar'},
                override: {value: serializeJSON(pokedexOverrides), cfsqltype: 'other'}
            }
        );
    }

}
