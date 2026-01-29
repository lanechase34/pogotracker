component extends="coldbox.system.testing.BaseTestCase" {

    function init() {
        pokedexService = getInstance('services.pokedex');
        pokemonService = getInstance('services.pokemon');
    }

    /**
     * Count the number of registered pokemon in the supplied pokedex
     *
     * @pokedex array pokedex
     * @shiny   t/f
     */
    public numeric function countRegistered(required array pokedex, boolean shiny = false) {
        var count = 0;
        pokedex.each((entry) => {
            if(!isNull(entry[2]) && (!shiny || (shiny && entry[2].getShiny()))) {
                count += 1;
            }
        });
        return count;
    }

    /**
     * Registers count pokemon from the supplied generation
     *
     * @count      count
     * @generation generation
     * @info       getGenerationInfo()
     */
    public void function registerRandom(
        required numeric count,
        required numeric generation,
        required struct info,
        required component trainer
    ) {
        for(var i = 1; i <= arguments.count; i++) {
            while(true) {
                currPokemon = pokemonService.getFromId(info.ids[randRange(1, len(arguments.info.ids))]);
                // Has to be unique pokemon
                check       = entityLoad(
                    'pokedex',
                    {'trainer': trainer, 'pokemon': currPokemon},
                    true
                );

                if(isNull(check)) {
                    pokedexService.register(
                        trainer     = trainer,
                        pokemon     = currPokemon,
                        caught      = true,
                        shiny       = false,
                        hundo       = false,
                        shadow      = false,
                        shadowshiny = false
                    );
                    break;
                }
            }
        }
    }

    /**
     * Returns all pk and numbers for the given generation
     *
     * @generation 
     */
    public struct function getGenerationInfo(required numeric generation) {
        var info = queryExecute(
            '
            select 
                string_agg(cast(id as text), '','') as idList, 
                string_agg(cast(number as text), '','') as numberList
            from pokemon
            where generation = :generation
            and mega = false
            and giga = false
            ',
            {generation: {value: arguments.generation, cfsqltype: 'numeric'}}
        );

        var generation = queryExecute(
            '
            select region
            from generation
            where generation = :generation
            ',
            {generation: {value: arguments.generation, cfsqltype: 'numeric'}}
        )

        return {
            numbers: listToArray(info.numberList, ','),
            ids    : listToArray(info.idList, ','),
            region : generation.region
        };
    }

}
