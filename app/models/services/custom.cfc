component singleton accessors="true" {

    property name="trainerCache"   inject="cachebox:trainerCache";
    property name="pagination"     inject="services.pagination";
    property name="pokedexService" inject="services.pokedex";
    property name="utilService"    inject="services.util";

    // A custom pokedex row with its creator's username
    variables.CUSTOM_SELECT = "
        SELECT custom.id, custom.created, custom.updated, custom.name, custom.link, custom.public, custom.begins,
            custom.ends, custom.commday, custom.trainerid, trainer.username
        FROM custom
        INNER JOIN trainer ON trainer.id = custom.trainerid
    ";

    /**
     * Create the custom pokedex
     *
     * @trainerid creator's trainer pk
     * @name      name of custom pokedex
     * @isPublic  t/f visible to every trainer
     * @begins    leekduck event begin datetime
     * @ends      leekduck event end datetime
     * @link      leekduck link
     */
    public numeric function create(
        required numeric trainerid,
        required string name,
        required boolean isPublic,
        date begins     = now(),
        date ends       = now(),
        string link     = "",
        boolean commday = false
    ) {
        var customid = queryExecute(
            "
            INSERT INTO custom (name, trainerid, public, begins, ends, link, commday)
            VALUES (:name, :trainerid, :public, :begins, :ends, :link, :commday)
            RETURNING id
            ",
            {
                name     : {value: arguments.name, cfsqltype: "varchar"},
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                public   : {value: arguments.isPublic ? true : false, cfsqltype: "boolean"},
                begins   : {value: arguments.begins, cfsqltype: "timestamp"},
                ends     : {value: arguments.ends, cfsqltype: "timestamp"},
                link     : {value: arguments.link, cfsqltype: "varchar"},
                commday  : {value: arguments.commday ? true : false, cfsqltype: "boolean"}
            }
        ).id;

        clearMineCache(trainerid = arguments.trainerid, isPublic = arguments.isPublic);
        return customid;
    }

    /**
     * Update an event's dates and leekduck link
     *
     * @customid custom pk
     * @begins   event begin datetime
     * @ends     event end datetime
     * @link     leekduck link
     */
    public void function updateEvent(
        required numeric customid,
        required date begins,
        required date ends,
        required string link
    ) {
        queryExecute(
            "UPDATE custom SET begins = :begins, ends = :ends, link = :link WHERE id = :customid",
            {
                begins  : {value: arguments.begins, cfsqltype: "timestamp"},
                ends    : {value: arguments.ends, cfsqltype: "timestamp"},
                link    : {value: arguments.link, cfsqltype: "varchar"},
                customid: {value: arguments.customid, cfsqltype: "integer"}
            }
        );
        return;
    }

    /**
     * One custom pokedex (see toCustom), null when there is no such custom pokedex
     *
     * @id custom pk
     */
    public any function getFromId(required numeric id) {
        var custom = findCustoms("custom.id = :id", {id: {value: arguments.id, cfsqltype: "integer"}});
        return utilService.firstRow(custom);
    }

    /**
     * The custom pokedex for a leekduck event link (matched ignoring case), null when there is none
     *
     * @link leekduck event link
     */
    public any function findByLink(required string link) {
        // link <> '' matches the partial unique index so it is used
        var custom = findCustoms(
            "UPPER(custom.link) = :link AND custom.link <> ''",
            {link: {value: uCase(arguments.link), cfsqltype: "varchar"}}
        );
        return utilService.firstRow(custom);
    }

    /**
     * Custom pokedexes matching the where clause, as structs
     *
     * @whereSQL condition on the custom table, with named params
     * @params   query params for whereSQL
     * @orderBy  order by clause
     * @limitSQL limit/offset clause, with named params
     */
    private array function findCustoms(
        required string whereSQL,
        required struct params,
        string orderBy  = "custom.id ASC",
        string limitSQL = ""
    ) {
        return queryExecute(
            "
            #variables.CUSTOM_SELECT# 
            WHERE #arguments.whereSQL# 
            ORDER BY #arguments.orderBy# 
            #arguments.limitSQL#
            ",
            arguments.params,
            {returnType: "array"}
        ).map((row) => toCustom(row));
    }

    /**
     * A custom pokedex row as the views use it - its columns, the creator's username,
     * and formattedbegins/formattedends (mmm d, yyyy, falling back to when it was created)
     *
     * @row CUSTOM_SELECT row
     */
    private struct function toCustom(required struct row) {
        var custom             = arguments.row;
        custom.formattedbegins = dateFormat(isDate(custom.begins ?: "") ? custom.begins : custom.created, "mmm d, yyyy");
        custom.formattedends   = dateFormat(isDate(custom.ends ?: "") ? custom.ends : custom.created, "mmm d, yyyy");
        return custom;
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
            {returnType: "array"}
        ).reduce((ids, row) => {
            ids["#row.pokemonid#"] = true;
            return ids;
        }, {});
    }

    /**
     * Creates the custom pokedex by adding new pokemon and removing ones that were deleted
     *
     * @custom  the custom pokedex (getFromId)
     * @pokemon array of pokemon ids
     */
    public void function createCustomPokedex(required struct custom, required array pokemon) {
        transaction {
            writeCustomPokedexRows(customid = arguments.custom.id, pokemon = arguments.pokemon);
        }

        // After the change, so a read in between can't cache the old entries
        pokedexService.clearCustomRegisteredCache(arguments.custom.id);
        return;
    }

    /**
     * Create or edit a trainer's custom pokedex - the custom row and its pokemon are saved together or not at all
     * An edit locks the custom row first, so two saves of the same custom pokedex run one after the other
     *
     * @trainerid creator's trainer pk
     * @name      name of custom pokedex
     * @isPublic  t/f visible to every trainer
     * @pokemon   array of pokemon ids
     * @customid  custom pk to edit, 0 creates a new one
     *
     * @return the custom pk
     */
    public numeric function saveCustomPokedex(
        required numeric trainerid,
        required string name,
        required boolean isPublic,
        required array pokemon,
        numeric customid = 0
    ) {
        var wasPublic     = false;
        var savedCustomid = arguments.customid;

        transaction {
            if(savedCustomid) {
                var locked = queryExecute(
                    "SELECT public FROM custom WHERE id = :customid FOR UPDATE",
                    {customid: {value: savedCustomid, cfsqltype: "integer"}}
                );
                if(!locked.recordCount) {
                    throw(type = "EntityNotFound", message = "Custom pokedex #savedCustomid# does not exist");
                }
                wasPublic = locked.public;

                queryExecute(
                    "UPDATE custom SET name = :name, public = :public WHERE id = :customid",
                    {
                        name    : {value: arguments.name, cfsqltype: "varchar"},
                        public  : {value: arguments.isPublic ? true : false, cfsqltype: "boolean"},
                        customid: {value: savedCustomid, cfsqltype: "integer"}
                    }
                );
            }
            else {
                savedCustomid = queryExecute(
                    "
                    INSERT INTO custom (name, trainerid, public, begins, ends, link, commday)
                    VALUES (:name, :trainerid, :public, :begins, :ends, '', false)
                    RETURNING id
                    ",
                    {
                        name     : {value: arguments.name, cfsqltype: "varchar"},
                        trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                        public   : {value: arguments.isPublic ? true : false, cfsqltype: "boolean"},
                        // Same as create() - a trainer's custom pokedex isn't an event, so it begins and ends now
                        begins   : {value: now(), cfsqltype: "timestamp"},
                        ends     : {value: now(), cfsqltype: "timestamp"}
                    }
                ).id;
            }

            writeCustomPokedexRows(customid = savedCustomid, pokemon = arguments.pokemon);
        }

        // Going public or private changes everyone's list
        clearMineCache(trainerid = arguments.trainerid, isPublic = wasPublic || arguments.isPublic);
        pokedexService.clearCustomRegisteredCache(savedCustomid);
        return savedCustomid;
    }

    /**
     * Add the wanted pokemon to a custom pokedex and remove the rest
     * Runs inside the caller's transaction
     *
     * @customid custom pk
     * @pokemon  array of pokemon ids
     */
    private void function writeCustomPokedexRows(required numeric customid, required array pokemon) {
        var customidParam = {value: arguments.customid, cfsqltype: "integer"};
        var wanted        = arguments.pokemon.map((pokemonid) => val(pokemonid));

        // Nothing wanted - clear the custom pokedex
        if(!wanted.len()) {
            queryExecute("DELETE FROM custompokedex WHERE customid = :customid", {customid: customidParam});
            return;
        }

        var params = {
            customid: customidParam,
            ids     : {
                value    : wanted.toList(),
                cfsqltype: "integer",
                list     : true
            }
        };

        // Add the wanted pokemon not already in this custom pokedex - joining pokemon drops ids that don't exist
        queryExecute(
            "
            INSERT INTO custompokedex (customid, pokemonid)
            SELECT :customid, pokemon.id
            FROM pokemon
            WHERE pokemon.id IN (:ids)
            ON CONFLICT (customid, pokemonid) DO NOTHING
            ",
            params
        );

        // Delete the records that were removed
        queryExecute("DELETE FROM custompokedex WHERE customid = :customid AND pokemonid NOT IN (:ids)", params);
    }

    /**
     * Returns list of custom pokedex available to the trainer
     * Trainer is either the creator or the custom is public
     */
    public array function getMine(
        required numeric trainerid,
        numeric offset,
        numeric pageSize
    ) {
        var params   = {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}};
        var limitSQL = "";
        if(!isNull(arguments.offset)) {
            params.offset = {value: arguments.offset, cfsqltype: "integer"};
        }
        if(!isNull(arguments.pageSize)) {
            limitSQL &= " LIMIT :pageSize";
            params.pageSize = {value: arguments.pageSize, cfsqltype: "integer"};
        }
        if(!isNull(arguments.offset)) {
            limitSQL &= " OFFSET :offset";
        }

        return trainerCache.getOrSet(
            getMineCacheKey(argumentCollection = arguments),
            // Custom pokedex list where you are the creator, or the pokedex is public
            () => findCustoms(
                whereSQL = "custom.commday = false AND (custom.trainerid = :trainerid OR custom.public = true)",
                params   = params,
                orderBy  = "custom.id DESC, custom.name ASC",
                limitSQL = limitSQL
            ),
            5,
            5
        );
    }

    /**
     * Cache key for the list getMine loads - clearMineCache matches its start
     *
     * @trainerid trainer pk
     * @offset    (optional) rows skipped
     * @pageSize  (optional) rows returned
     */
    private string function getMineCacheKey(
        required numeric trainerid,
        numeric offset,
        numeric pageSize
    ) {
        var cacheKey = "#arguments.trainerid#|custom.getMine";
        if(!isNull(arguments.offset)) {
            cacheKey &= "|offset=#arguments.offset#";
        }
        if(!isNull(arguments.pageSize)) {
            cacheKey &= "|pageSize=#arguments.pageSize#";
        }
        return cacheKey;
    }

    /**
     * Delete the supplied custom pokedex
     * Deletes the custom row and its custompokedex rows
     *
     * @custom the custom pokedex (getFromId)
     */
    public void function deleteCustom(required struct custom) {
        var customid = {value: arguments.custom.id, cfsqltype: "integer"};
        transaction {
            queryExecute("DELETE FROM custompokedex WHERE customid = :customid", {customid: customid});
            queryExecute("DELETE FROM custom WHERE id = :customid", {customid: customid});
        }

        clearMineCache(trainerid = arguments.custom.trainerid, isPublic = arguments.custom.public);
        pokedexService.clearCustomRegisteredCache(arguments.custom.id);
        return;
    }

    /**
     * Clear custom.getMine for whoever can see the pokedex - every trainer when it is public, otherwise only its creator
     *
     * @trainerid creator
     * @isPublic  whether the pokedex is (or was) public
     */
    private void function clearMineCache(required numeric trainerid, required boolean isPublic) {
        if(arguments.isPublic) {
            trainerCache.clearByKeySnippet("\|custom\.getMine(\||$)", true);
        }
        else {
            trainerCache.clearByKeySnippet("^#arguments.trainerid#\|custom\.getMine(\||$)", true);
        }
    }

    /**
     * Paginated search of the trainer's custom pokedex list
     *
     * @trainerid searching trainer pk
     * @search    search term, can be empty
     * @page      current page
     * @pageSize  page size
     */
    public any function searchMyCustom(
        required numeric trainerid,
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
        var params       = pagination.selectPageParams(arguments.page, arguments.pageSize);
        params.trainerid = {value: arguments.trainerid, cfsqltype: "integer"};
        params.search    = {value: utilService.likeContains(arguments.search), cfsqltype: "varchar"};

        var customs = queryExecute(
            "
            SELECT custom.id, custom.name
            #fromWhere#
            ORDER BY custom.id DESC, custom.name ASC
            LIMIT :pageRows
            OFFSET :offset
            ",
            params,
            {returnType: "array"}
        );

        return pagination.toSelectPage(
            customs,
            arguments.pageSize,
            (custom) => {
                return {id: custom.id, text: custom.name};
            }
        );
    }

}
