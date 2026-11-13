component singleton accessors="true" {

    property name="trainerCache" inject="cachebox:trainerCache";
    property name="utilService"  inject="services.util";

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
        date begins     = now(),
        date ends       = now(),
        string link     = "",
        boolean commday = false
    ) {
        var newCustom = entityNew(
            "custom",
            {
                "name"   : arguments.name,
                "trainer": arguments.trainer,
                "public" : arguments.public,
                "begins" : arguments.begins,
                "ends"   : arguments.ends,
                "link"   : arguments.link,
                "commday": arguments.commday
            }
        );
        entitySave(newCustom);
        ormFlush();

        clearMineCache(trainerid = arguments.trainer.getId(), public = arguments.public);
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
        var custom    = getFromId(arguments.customid);
        var wasPublic = custom.getPublic();
        custom.setName(arguments.name);
        custom.setPublic(arguments.public);
        entitySave(custom);
        ormFlush();

        // Going public or private changes everyone's list
        clearMineCache(trainerid = custom.getTrainer().getId(), public = wasPublic || arguments.public);
        clearCustomRegisteredCache(arguments.customid);
        return;
    }

    public any function getFromId(required numeric id) {
        return entityLoadByPK("custom", arguments.id);
    }

    /**
     * Returns a struct of the pokemon ids in a custom pokedex
     *
     * @customid custom pk
     *
     * @return { pokemonid: true }
     */
    public struct function getCustomPokedexIds(required numeric customid) {
        return queryExecute(
            "
            SELECT pokemonid 
            FROM custompokedex 
            WHERE customid = :customid
            ",
            {customid: {value: arguments.customid, cfsqltype: "integer"}},
            {returntype: "array"}
        ).reduce((ids, row) => {
            ids["#row.pokemonid#"] = true;
            return ids;
        }, {});
    }

    /**
     * Creates the custom pokedex by adding new pokemon and removing ones that were deleted
     *
     * @custom  the custom entity
     * @pokemon array of pokemon ids
     */
    public void function createCustomPokedex(required component custom, required array pokemon) {
        var customid = {value: arguments.custom.getId(), cfsqltype: "integer"};
        var wanted   = arguments.pokemon.map((pokemonid) => val(pokemonid));

        // Add the wanted pokemon not already in this custom pokedex - joining pokemon drops ids that don't exist
        if(wanted.len()) {
            queryExecute(
                "
                INSERT INTO custompokedex (customid, pokemonid, created, updated)
                SELECT :customid, pokemon.id, now(), now()
                FROM pokemon
                WHERE pokemon.id IN (:ids)
                ON CONFLICT (customid, pokemonid) DO NOTHING
                ",
                {
                    customid: customid,
                    ids     : {
                        value    : wanted.toList(),
                        cfsqltype: "integer",
                        list     : true
                    }
                }
            );
        }

        // Delete the records that were removed
        if(wanted.len()) {
            queryExecute(
                "DELETE FROM custompokedex WHERE customid = :customid AND pokemonid NOT IN (:ids)",
                {
                    customid: customid,
                    ids     : {
                        value    : wanted.toList(),
                        cfsqltype: "integer",
                        list     : true
                    }
                }
            );
        }
        else {
            queryExecute("DELETE FROM custompokedex WHERE customid = :customid", {customid: customid});
        }

        entityReload(custom);
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
        var cacheKey = "#arguments.trainer.getId()#|custom.getMine";
        var options  = {};
        if(!isNull(arguments.offset)) {
            options.insert("offset", arguments.offset);
            cacheKey &= "|offset=#arguments.offset#";
        }
        if(!isNull(arguments.count)) {
            options.insert("maxResults", arguments.count);
            cacheKey &= "|count=#arguments.count#";
        }

        var custom = trainerCache.get(cacheKey);
        if(isNull(custom)) {
            // Custom pokedex list where you are the creator, or the pokedex is public
            custom = ormExecuteQuery(
                "
                from custom as custom
                where custom.commday = false
                and (
                    custom.trainer = :trainer
                    or custom.public = true
                )
                order by custom.id desc, custom.name asc
                ",
                {"trainer": arguments.trainer},
                false,
                options
            );

            trainerCache.set(cacheKey, custom, 5, 5);
        }

        return custom;
    }

    /**
     * Get a custom pokedex by id that is public OR created by the trainer
     *
     * @id      customid
     * @trainer trainer
     */
    public any function get(required numeric id, required component trainer) {
        return ormExecuteQuery(
            "
            from custom as custom
            where custom.id = :id
            and (custom.trainer = :trainer or custom.public = true)
            ",
            {"id": arguments.id, "trainer": arguments.trainer}
        );
    }

    /**
     * Delete the supplied custom pokedex
     * Deletes the custom entity and sub customPokedex entities
     *
     * @custom custom object
     */
    public void function delete(required component custom) {
        var customid  = arguments.custom.getId();
        var trainerid = arguments.custom.getTrainer().getId();
        var public    = arguments.custom.getPublic();

        var customPokedex = arguments.custom.getCustomPokedex();
        if(!isNull(customPokedex)) {
            customPokedex.each((customPokedex) => {
                entityDelete(customPokedex);
            });
            ormFlush();
        }

        entityDelete(arguments.custom);
        ormFlush();

        clearMineCache(trainerid = trainerid, public = public);
        clearCustomRegisteredCache(customid);
        return;
    }

    /**
     * Clear custom.getMine for whoever can see the pokedex - every trainer when it is public, otherwise only its creator
     *
     * @trainerid creator
     * @public    whether the pokedex is (or was) public
     */
    private void function clearMineCache(required numeric trainerid, required boolean public) {
        if(arguments.public) {
            trainerCache.clearByKeySnippet("\|custom\.getMine(\||$)", true);
        }
        else {
            trainerCache.clearByKeySnippet("^#arguments.trainerid#\|custom\.getMine(\||$)", true);
        }
    }

    /**
     * Clear every trainer's cached registered list for one custom pokedex
     * Anchored on the end of the key so custom 1 doesn't also clear custom 12, 13...
     *
     * @customid custom pk
     */
    public void function clearCustomRegisteredCache(required numeric customid) {
        trainerCache.clearByKeySnippet("\|pokedex\.getCustomRegistered\|custom=#arguments.customid#$", true);
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
        var fromWhere = "
            FROM custom
            WHERE custom.commday = false
                AND custom.name ILIKE :search
                AND (custom.trainerid = :trainerid OR custom.public = true)
        ";
        var params = {
            trainerid: {value: arguments.trainer.getId(), cfsqltype: "integer"},
            search   : {value: utilService.likeContains(arguments.search), cfsqltype: "varchar"}
        };

        // One row past the page - if it comes back there is another page
        params.limit  = {value: arguments.pageSize + 1, cfsqltype: "integer"};
        params.offset = {value: (arguments.page - 1) * arguments.pageSize, cfsqltype: "integer"};

        var customs = queryExecute(
            "
            SELECT custom.id, custom.name
            #fromWhere#
            ORDER BY custom.id DESC, custom.name ASC
            LIMIT :limit
            OFFSET :offset
            ",
            params,
            {returntype: "array"}
        );

        var more = customs.len() > arguments.pageSize;
        if(more) {
            customs.deleteAt(customs.len());
        }

        return {
            results: customs.map((custom) => {
                return {id: custom.id, text: custom.name};
            }),
            pagination: {more: more}
        };
    }

}
