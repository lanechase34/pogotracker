component singleton accessors="true" {

    property name="async"          inject="asyncManager@coldbox";
    property name="trainerCache"   inject="cachebox:trainerCache";
    property name="pagination"     inject="services.pagination";
    property name="imageExtension" inject="coldbox:setting:imageExtension";
    property name="securityLevels" inject="coldbox:setting:securityLevels";
    property name="utilService"    inject="services.util";

    property name="datatableCols" type="array";
    property name="iconMap"       type="array";

    public void function init() {
        setIconMap([
            "Bulbasaur",
            "Squirtle",
            "Charmander",
            "Chikorita",
            "Totodile",
            "Cyndaquil",
            "Treecko",
            "Mudkip",
            "Torchic",
            "Substitute"
        ]);

        setDatatableCols([
            "",
            "trainer.icon",
            "trainer.username",
            "trainer.email",
            "trainer.verified",
            "trainer.securitylevel",
            "trainer.lastlogin"
        ]);
    }

    /**
     * Load a trainer entity by id
     *
     * @trainerid pk of trainer
     */
    public component function getFromId(required numeric trainerid) {
        var cacheKey = getCacheKey(arguments.trainerid);
        var trainer  = trainerCache.get(cacheKey);
        if(isNull(trainer)) {
            trainer = entityLoadByPK("trainer", arguments.trainerid);
            if(isNull(trainer)) {
                throw(type = "TrainerNotFound", message = "Trainer #arguments.trainerid# does not exist");
            }
            // Make sure relationships are loaded before being cached
            trainer.getIconPath();
            trainer.getIconAltText();
            trainerCache.set(cacheKey, trainer);
        }
        return trainer;
    }

    /**
     * Evict the cached trainer so the next getFromId reloads it (and its memoized settings/level)
     * Call after anything that changes the trainer, their settings, or their stats
     *
     * @trainerid pk of trainer
     */
    public void function clearCache(required numeric trainerid) {
        trainerCache.clear(getCacheKey(arguments.trainerid));
        return;
    }

    /**
     * Whether the icon can be picked - the base icons, plus the trainer's unlocked icons
     * The trainer's current icon always passes, so keeping it never fails
     *
     * @icon    icon name (the file name without its extension)
     * @trainer (optional) trainer the icon is for - omit when registering (base icons only)
     */
    public boolean function isAllowedIcon(required string icon, component trainer) {
        var wanted  = lCase(trim(arguments.icon));
        var allowed = duplicate(getIconMap());

        if(!isNull(arguments.trainer)) {
            if(wanted == lCase(arguments.trainer.getIcon())) {
                return true;
            }
            allowed.append(arguments.trainer.getUnlockedIcons(), true);
        }

        // Icon names can have spaces ("Shiny Mew") - their files don't (shinymew)
        return allowed.some((name) => lCase(replace(name, " ", "", "all")) == wanted);
    }

    private string function getCacheKey(required numeric trainerid) {
        return "trainer.getFromId|trainerid=#arguments.trainerid#";
    }

    /**
     * Datatable getter for the trainer table
     */
    public struct function get(
        required numeric records,
        required numeric offset,
        required string search   = "",
        required string orderCol = "",
        required string orderDir = ""
    ) {
        var fromSQL     = "FROM trainer";
        var whereSQL    = "";
        var whereParams = {};
        if(search.len()) {
            whereSQL           = "WHERE #pagination.searchSQL(["trainer.username", "trainer.email"])#";
            whereParams.search = {value: utilService.likeContains(search), cfsqltype: "varchar"};
        }

        var orderBy = pagination.orderBy(
            columns     = getDatatableCols(),
            orders      = [{column: orderCol, dir: orderDir}],
            defaultSort = "trainer.id ASC",
            tiebreak    = "trainer.id ASC",
            nullsLast   = true
        );

        var page = pagination.paginate(
            records       = records,
            offset        = offset,
            fromSQL       = fromSQL,
            baseWhere     = "",
            whereSQL      = whereSQL,
            whereParams   = whereParams,
            totalCacheKey = "trainer.totalRecords",
            cacheMinutes  = 5,
            fetchRows     = (pageParams) => queryExecute(
                "
                SELECT trainer.id, COALESCE(trainer.icon, '') AS icon, trainer.username, trainer.email,
                    trainer.verified, trainer.securitylevel, trainer.lastlogin
                #fromSQL#
                #whereSQL#
                #orderBy#
                LIMIT :records
                OFFSET :offset
                ",
                pageParams,
                {returntype: "array"}
            )
        );

        var securityLevels = getSecurityLevels();

        return {
            data: page.rows.map((row) => {
                return {
                    trainerid    : row.id,
                    edit         : "",
                    icon         : "/includes/images/icons/#row.icon##getImageExtension()#",
                    iconAltText  : "#ucFirst(row.icon)# profile icon",
                    username     : row.username,
                    email        : row.email,
                    verified     : row.verified,
                    securitylevel: securityLevels[row.securitylevel],
                    lastlogin    : isDate(row.lastlogin) ? dateTimeFormat(row.lastlogin, "mmm-dd-yyyy HH:nn:ss") : "---"
                };
            }),
            recordsTotal   : page.recordsTotal,
            recordsFiltered: page.recordsFiltered
        };
    }

    /**
     * Updates the trainer's json settings structure
     *
     * @trainer  trainer entity
     * @settings settings struct
     */
    public void function updateSettings(required component trainer, required struct settings) {
        // settings is a jsonb column written directly by setSettings - no orm save needed
        arguments.trainer.setSettings(arguments.settings);
        return;
    }

    /**
     * Stamps the trainer's last login
     *
     * @trainer trainer entity
     */
    public void function updateLastLogin(required component trainer) {
        var loginTime = now();
        var trainerid = arguments.trainer.getId();

        arguments.trainer.setLastLogin(loginTime);

        async.newFuture(() => {
            queryExecute(
                "update trainer set lastlogin = :lastlogin where id = :trainerid",
                {
                    lastlogin: {value: loginTime, cfsqltype: "timestamp"},
                    trainerid: {value: trainerid, cfsqltype: "integer"}
                }
            );
        });
    }

}
