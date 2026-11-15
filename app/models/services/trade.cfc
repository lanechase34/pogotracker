component singleton accessors="true" {

    /**
     * Find the exclusive pokemon that only left trainer has and right trainer does not
     *
     * @leftTrainerid  trainer pk
     * @rightTrainerid trainer pk
     * @shiny          t/f
     * @generation     generation struct (generationService)
     * @custom         custom pokedex (customService.getFromId/get)
     *
     * @return pokemon rows (id, number, name, sprite, costume, costumetype), by number
     */
    public array function findExclusive(
        required numeric leftTrainerid,
        required numeric rightTrainerid,
        required boolean shiny,
        struct generation,
        struct custom
    ) {
        // Column is never user supplied, only one of two literals
        var flag        = arguments.shiny ? "shiny" : "caught";
        var whereClause = "WHERE pokemon.tradable = true AND pokedexr.id IS NULL";
        if(arguments.shiny) {
            whereClause &= " AND pokemon.shiny = true";
        }

        var params = {
            lefttrainerid : {value: arguments.leftTrainerid, cfsqltype: "integer"},
            righttrainerid: {value: arguments.rightTrainerid, cfsqltype: "integer"}
        };

        if(!isNull(arguments.generation)) {
            whereClause &= " AND pokemon.generation = :generation AND pokemon.costume = false";
            params.generation = {
                value    : arguments.generation.generation,
                cfsqltype: "decimal",
                scale    : 1
            };
        }

        var customClause = "";
        if(!isNull(arguments.custom)) {
            customClause    = "INNER JOIN custompokedex ON custompokedex.pokemonid = pokemon.id AND custompokedex.customid = :customid";
            params.customid = {value: arguments.custom.id, cfsqltype: "integer"};
        }

        return queryExecute(
            "
            SELECT pokemon.id, pokemon.number, pokemon.name, pokemon.sprite, pokemon.costume,
                COALESCE(pokemon.costumetype, '') AS costumetype
            FROM pokemon
            #customClause#
            INNER JOIN pokedex AS pokedexl
                ON pokedexl.pokemonid = pokemon.id AND pokedexl.trainerid = :lefttrainerid AND pokedexl.#flag# = true
            LEFT JOIN pokedex AS pokedexr
                ON pokedexr.pokemonid = pokemon.id AND pokedexr.trainerid = :righttrainerid AND pokedexr.#flag# = true
            #whereClause#
            ORDER BY pokemon.number ASC, pokemon.id ASC
            ",
            params,
            {returnType: "array"}
        );
    }

}
