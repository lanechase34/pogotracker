component singleton accessors="true" {

    // Find the exclusive pokemon that only left trainer has and right trainer does not
    public array function findExclusive(
        required component leftTrainer,
        required component rightTrainer,
        required boolean shiny,
        component generation,
        component custom
    ) {
        var conditionL  = 'and pokedexL.caught = true';
        var conditionR  = 'and pokedexR.caught = true';
        var whereClause = 'where pokemon.tradable = true and pokedexR.pokemon is null';

        if(arguments.shiny) {
            conditionL = ' and pokedexL.shiny = true';
            conditionR = ' and pokedexR.shiny = true';
            whereClause &= ' and pokemon.shiny = true';
        }

        var params = {'leftTrainer': arguments.leftTrainer, 'rightTrainer': arguments.rightTrainer};

        if(!isNull(arguments.generation)) {
            whereClause &= ' and pokemon.generation = :generation';
            params.insert('generation', arguments.generation);
        }

        var customClause = '';
        if(!isNull(arguments.custom)) {
            customClause = 'inner join pokemon.custompokedex as custompokedex with custompokedex.custom = :custom';
            params.insert('custom', arguments.custom);
        }

        return ormExecuteQuery(
            '
            select pokemon
            from pokemon as pokemon
            #customClause#
            inner join pokemon.pokedex as pokedexL 
                with pokedexL.trainer = :leftTrainer
                #conditionL#
            left outer join pokemon.pokedex as pokedexR
                with pokedexR.trainer = :rightTrainer
                #conditionR#
            #whereClause#
            order by pokemon.number asc
            ',
            params
        );
    }

}
