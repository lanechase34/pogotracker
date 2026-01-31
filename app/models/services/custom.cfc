component singleton accessors="true" {

    property name="cacheService"   inject="services.cache";
    property name="pokemonService" inject="services.pokemon";

    /**
     * Create the custom pokedex entity
     *
     * @trainer trainer creator
     * @name    name of custom pokedex
     * @public  t/f 
     * @begins  leekduck event begin datetime
     * @ends    leekduck event end datetime
     * @link    leekduck link
     */
    public numeric function create(
        required component trainer,
        required string name,
        required boolean public,
        date begins = now(),
        date ends   = now(),
        string link = ''
    ) {
        var newCustom = entityNew(
            'custom',
            {
                'name'   : arguments.name,
                'trainer': arguments.trainer,
                'public' : arguments.public,
                'begins' : arguments.begins,
                'ends'   : arguments.ends,
                'link'   : arguments.link
            }
        );
        entitySave(newCustom);
        ormFlush();

        // Clear the custom list cache
        cacheService.clear('#arguments.trainer.getId()#|custom.getMine');
        return newCustom.getId();
    }

    /**
     * Update existing custom pokedex 
     */
    public void function update(
        required numeric customid,
        required string name,
        required boolean public
    ) {
        var custom = getFromId(arguments.customid);
        custom.setName(arguments.name);
        custom.setPublic(arguments.public);
        entitySave(custom);
        ormFlush();

        cacheService.clear('#session.trainerid#|custom.getMine');
        cacheService.clear('|pokedex.getCustomRegistered|custom=#arguments.customid#');
        return;
    }

    public any function getFromId(required numeric id) {
        return entityLoadByPK('custom', arguments.id);
    }

    /**
     * Creates the custom pokedex by adding new pokemon and removing ones that were deleted
     *
     * @custom  the custom entity
     * @pokemon array of pokemon ids
     */
    public void function createCustomPokedex(required component custom, required array pokemon) {
        var abstractedPokemon = {}; // Keeps track of pokemon that should exist in this custom pokedex

        // Find which records to add
        arguments.pokemon.each((pokemonid) => {
            abstractedPokemon['#pokemonid#'] = true;
            var currPokemon                  = pokemonService.getFromId(pokemonid);

            // If the custom pokedex entry doesn't exist, create
            if(
                isNull(
                    entityLoad(
                        'custompokedex',
                        {'custom': custom, 'pokemon': currPokemon},
                        true
                    )
                )
            ) {
                var customPokedex = entityNew('custompokedex', {'custom': custom, 'pokemon': currPokemon});
                entitySave(customPokedex);
            }
        });

        // Find which records to delete
        if(!isNull(arguments.custom.getCustomPokedex())) {
            arguments.custom
                .getCustomPokedex()
                .each((pokedex) => {
                    var currPokemon = pokedex.getPokemon();
                    if(!abstractedPokemon.keyExists(currPokemon.getId())) {
                        entityDelete(pokedex);
                    }
                });
        }

        ormFlush();
        return;
    }

    /**
     * Returns list of custom pokedex available to the trainer
     * Trainer is either the creator or the custom is public
     */
    public array function getMine(
        required component trainer,
        numeric offset,
        numeric count
    ) {
        var cacheKey = '#arguments.trainer.getId()#|custom.getMine';
        var options  = {};
        if(!isNull(arguments.offset)) {
            options.insert('offset', arguments.offset);
            cacheKey &= '|offset=#arguments.offset#';
        }
        if(!isNull(arguments.count)) {
            options.insert('maxResults', arguments.count);
            cacheKey &= '|count=#arguments.count#';
        }

        var custom = cacheService.get(cacheKey);
        if(isNull(custom)) {
            // Custom pokedex list where you are the creator, or the pokedex is public
            custom = ormExecuteQuery(
                '
                from custom as custom
                where custom.trainer = :trainer
                or custom.public = true
                order by custom.id desc, custom.name asc
                ',
                {'trainer': arguments.trainer},
                false,
                options
            );

            cacheService.put(cacheKey, custom, 5, 5);
        }

        return custom;
    }

    public any function get(required numeric id, required component trainer) {
        return ormExecuteQuery(
            '
            from custom as custom
            where custom.id = :id
            and (custom.trainer = :trainer or custom.public = true)
            ',
            {'id': arguments.id, 'trainer': arguments.trainer}
        );
    }

    public any function getCreated(required numeric id, required component trainer) {
        return entityLoad(
            'custom',
            {'id': arguments.id, 'trainer': arguments.trainer},
            true
        );
    }

    /**
     * Delete the supplied custom pokedex
     * Deletes the custom entity and sub customPokedex entities
     *
     * @custom 
     */
    public void function delete(required component custom) {
        arguments.custom
            .getCustomPokedex()
            .each((customPokedex) => {
                entityDelete(customPokedex);
            });
        ormFlush();

        entityDelete(arguments.custom);
        ormFlush();
        cacheService.clear('#session.trainerid#|custom.getMine');
        return;
    }

    /**
     * Paginated search of the trainer's custom pokedex list
     *
     * @trainer  trainer cfc searching
     * @search   search term, can be empty
     * @page     current page
     * @pageSize page size
     */
    public any function searchMyCustom(
        required component trainer,
        required string search,
        required numeric page,
        numeric pageSize = 10
    ) {
        var customList = ormExecuteQuery(
            '
            from custom as custom
            where upper(custom.name) like :search
            and (
                custom.trainer = :trainer
                or custom.public = true
            )
            order by custom.id desc, custom.name asc
            ',
            {trainer: arguments.trainer, search: '%#uCase(arguments.search)#%'},
            {offset: (arguments.page - 1) * pageSize, maxResults: pageSize}
        );

        var customListCount = ormExecuteQuery(
            '
            select count(custom.id)
            from custom as custom
            where upper(custom.name) like :search
            and (
                custom.trainer = :trainer
                or custom.public = true
            )
            ',
            {trainer: arguments.trainer, search: '%#uCase(arguments.search)#%'}
        );

        var result = {results: [], pagination: {more: customListCount[1] > arguments.page * pageSize}};
        customList.each((custom) => {
            result.results.append({id: custom.getId(), text: custom.getName()});
        });

        return result;
    }

}
