component singleton accessors="true" {

    property name="async"           inject="asyncManager@coldbox";
    property name="trainerCache"    inject="cachebox:trainerCache";
    property name="pagination"      inject="services.pagination";
    property name="imageExtension"  inject="coldbox:setting:imageExtension";
    property name="securityLevels"  inject="coldbox:setting:securityLevels";
    property name="permissions"     inject="coldbox:setting:permissions";
    property name="defaultSettings" inject="coldbox:setting:defaultSettings";
    property name="statsService"    inject="services.stats";

    property name="datatableCols" type="array";
    property name="iconMap"       type="array";
    property name="iconGoals"     type="array";

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

        // Pokedex goals that unlock profile icons - need is a count, or "all" for every species in the region
        setIconGoals([
            {
                region  : "Kanto",
                progress: "caught",
                need    : 38,
                icons   : ["Ivysaur", "Charmeleon", "Wartortle"]
            },
            {
                region  : "Kanto",
                progress: "caught",
                need    : 76,
                icons   : ["Venusaur", "Blastoise", "Charizard"]
            },
            {
                region  : "Kanto",
                progress: "caught",
                need    : 114,
                icons   : ["Articuno", "Zapdos", "Moltres"]
            },
            {
                region  : "Kanto",
                progress: "caught",
                need    : "all",
                icons   : ["Mewtwo"]
            },
            {
                region  : "Kanto",
                progress: "shiny",
                need    : 76,
                icons   : ["Mew"]
            },
            {
                region  : "Kanto",
                progress: "shiny",
                need    : "all",
                icons   : ["Shiny Mew"]
            },
            {
                region  : "Johto",
                progress: "caught",
                need    : 75,
                icons   : ["Lugia", "Ho-Oh"]
            },
            {
                region  : "Johto",
                progress: "caught",
                need    : "all",
                icons   : ["Celebi"]
            },
            {
                region  : "Johto",
                progress: "shiny",
                need    : "all",
                icons   : ["Shiny Celebi"]
            },
            {
                region  : "Unown",
                progress: "caught",
                need    : "all",
                icons   : ["Unown"]
            },
            {
                region  : "Hoenn",
                progress: "caught",
                need    : "all",
                icons   : ["Deoxys"]
            },
            {
                region  : "Hoenn",
                progress: "shiny",
                need    : "all",
                icons   : ["Shiny Deoxys"]
            }
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
     * Load a trainer by id
     * A struct of the trainer's columns - never the password, salt, or verification/reset codes - plus
     * settings (struct), iconpath, iconalttext and formattedfriendcode
     * Throws TrainerNotFound when there is no such trainer
     *
     * @trainerid pk of trainer
     */
    public struct function getFromId(required numeric trainerid) {
        var forTrainerid = arguments.trainerid;
        var trainer      = trainerCache.getOrSet(getCacheKey(forTrainerid), () => {
            var rows = queryExecute(
                "
                SELECT id, created, updated, username, email, lastlogin, securitylevel, friendcode, icon, verified,
                    sessionversion, settings, commentbanned
                FROM trainer
                WHERE id = :trainerid
                ",
                {trainerid: {value: forTrainerid, cfsqltype: "integer"}},
                {returnType: "array"}
            );
            if(!rows.len()) {
                throw(type = "TrainerNotFound", message = "Trainer #forTrainerid# does not exist");
            }

            var loaded                 = rows[1];
            var settings               = isJSON(loaded.settings ?: "") ? deserializeJSON(loaded.settings) : {};
            loaded.settings            = isStruct(settings) ? settings : {};
            loaded.securitylevel       = val(loaded.securitylevel);
            loaded.sessionversion      = val(loaded.sessionversion);
            loaded.iconpath            = buildIconPath(loaded.icon ?: "");
            loaded.iconalttext         = buildIconAltText(loaded.icon ?: "");
            loaded.formattedfriendcode = formatFriendCode(loaded.friendcode ?: "");
            return loaded;
        });

        // A copy - callers changing it must not change the cached trainer
        return duplicate(trainer);
    }

    /**
     * Find a trainer by email
     *
     * @email trainer's email (unique per trainer)
     *
     * @return trainer struct (getFromId) or null
     */
    public any function findByEmail(required string email) {
        var found = queryExecute(
            "SELECT id FROM trainer WHERE email = :email",
            {email: {value: normalizeEmail(arguments.email), cfsqltype: "varchar"}}
        );
        if(!found.recordCount) return;
        return getFromId(found.id);
    }

    /**
     * The form every email is stored and looked up in - trimmed and lowercase
     *
     * @email user entered email
     */
    public string function normalizeEmail(required string email) {
        return lCase(trim(arguments.email));
    }

    /**
     * The form every username is stored in - trimmed, case kept for display
     *
     * @username user entered username
     */
    public string function normalizeUsername(required string username) {
        return trim(arguments.username);
    }

    /**
     * Friend code shown in groups of four - 123456789012 -> 1234-5678-9012
     *
     * @friendcode 12 digit friend code
     */
    public string function formatFriendCode(required string friendcode) {
        if(!len(arguments.friendcode)) return "";
        return reReplace(arguments.friendcode, "([0-9]{4})", "\1-", "all").left(-1);
    }

    /**
     * The permissions a trainer has (user, trusted, admin, developer)
     * Permissions map to a minimum security level
     * Unverified trainers have no permissions until they verify their email
     *
     * @trainer trainer struct (getFromId)
     */
    public array function getPermissionNames(required struct trainer) {
        if(!(arguments.trainer.verified ?: false)) return [];
        var securityLevel = val(arguments.trainer.securitylevel ?: 0);
        return getPermissions().keyArray().filter((name) => securityLevel >= getPermissions()[name]);
    }

    /**
     * True if this trainer has any of the permissions (user, trusted, admin, developer)
     *
     * @trainer    trainer struct (getFromId)
     * @permission permission name or list
     */
    public boolean function hasPermission(required struct trainer, required any permission) {
        var granted = getPermissionNames(arguments.trainer);
        return listToArray(arguments.permission).some((name) => granted.findNoCase(trim(name)) > 0);
    }

    /**
     * Security levels that can be given through a profile update - everything below developer
     * Developer is never assignable from the app, it can only be set in the database
     *
     * @return struct of level -> display name
     */
    public struct function getAssignableLevels() {
        var developerLevel = getPermissions().developer;
        return getSecurityLevels().filter((level) => val(level) < developerLevel);
    }

    /**
     * Current level and xp progress from the trainer's latest stat
     * Cached per trainer until clearCache (tracking a stat clears it)
     *
     * @trainerid trainer pk
     */
    public struct function getCurrentLevel(required numeric trainerid) {
        var forTrainerid = arguments.trainerid;
        var level        = trainerCache.getOrSet(getLevelCacheKey(forTrainerid), () => loadCurrentLevel(forTrainerid));
        return duplicate(level);
    }

    /**
     * Level and progress for the trainer's latest recorded xp
     */
    private struct function loadCurrentLevel(required numeric trainerid) {
        // No stat recorded yet
        var latestStat = statsService.getLatestStat(arguments.trainerid);
        if(isNull(latestStat)) {
            return {
                level      : "--",
                totalxp    : "",
                dateTracked: createDate(2000, 1, 1)
            };
        }

        // Total XP from the latest recorded stat
        var totalxp = latestStat.xp;

        // Select the current level and the next level
        var levelData = queryExecute(
            "
            SELECT curr.level, curr.requiredxp AS currlevelxp, next.requiredxp AS nextlevelxp
            FROM level AS curr
            LEFT JOIN level AS next ON next.level = curr.level + 1
            WHERE :totalxp >= curr.requiredxp
            ORDER BY curr.level DESC
            LIMIT 1
            ",
            {totalxp: {value: totalxp, cfsqltype: "bigint"}}
        );

        var result = {
            level      : levelData.level,
            totalxp    : numberFormat(totalxp, ","),
            dateTracked: dateFormat(latestStat.created, "short")
        };

        // Calculate progress to the next level
        if(!isNull(levelData.nextlevelxp) && levelData.nextlevelxp.len()) {
            var xpIntoLevel   = totalxp - levelData.currlevelxp;
            var xpToNextLevel = levelData.nextlevelxp - levelData.currlevelxp;

            result.currxp      = xpIntoLevel;
            result.nextlevelxp = xpToNextLevel;
            result.progress    = round(xpIntoLevel / xpToNextLevel, 2) * 100;
        }

        return result;
    }

    /**
     * Profile icons the trainer has unlocked by completing pokedex goals
     *
     * @trainerid trainer pk
     */
    public array function getUnlockedIcons(required numeric trainerid) {
        // Per region: base species, how many have a released shiny, and how many of each this trainer has registered
        var progress = queryExecute(
            "
            SELECT generation.region,
                COUNT(pokemon.id) AS caughttotal,
                COUNT(pokemon.id) FILTER (WHERE pokemon.shiny = true) AS shinytotal,
                COUNT(pokedex.id) FILTER (WHERE pokedex.caught = true) AS caught,
                COUNT(pokedex.id) FILTER (WHERE pokedex.shiny = true AND pokemon.shiny = true) AS shiny
            FROM pokemon
            INNER JOIN generation ON generation.generation = pokemon.generation
            LEFT JOIN pokedex ON pokedex.pokemonid = pokemon.id AND pokedex.trainerid = :trainerid
            WHERE pokemon.form = false
                AND pokemon.costume = false
                AND pokemon.mega = false
                AND pokemon.giga = false
            GROUP BY generation.region
            ",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}},
            {returnType: "array"}
        ).reduce((result, row) => {
            result[row.region] = row;
            return result;
        }, {});

        var icons = getIconGoals().reduce((result, goal) => {
            if(!progress.keyExists(goal.region)) return result;
            var region = progress[goal.region];
            var need   = goal.need == "all" ? region["#goal.progress#total"] : goal.need;

            return need > 0 && region[goal.progress] >= need ? result.append(goal.icons, true) : result;
        }, []);

        if(hasPermission(getFromId(arguments.trainerid), "developer")) {
            icons.append("Wobbuffet");
        }

        return icons;
    }

    /**
     * Add any settings added to settings.defaultSettings since the trainer's settings were saved
     *
     * @trainerid trainer pk
     * @settings  the trainer's saved settings
     *
     * @return the trainer's settings with the defaults filled in
     */
    public struct function fillDefaultSettings(required numeric trainerid, required struct settings) {
        var filledSettings = duplicate(arguments.settings);
        var state          = {missing: false};

        getDefaultSettings().each((key, value) => {
            if(!filledSettings.keyExists(key)) {
                filledSettings[key] = duplicate(value);
                state.missing       = true;
            }
            else if(isStruct(value) && isStruct(filledSettings[key])) {
                value.each((propname, propvalue) => {
                    if(!filledSettings[key].keyExists(propname)) {
                        filledSettings[key][propname] = propvalue;
                        state.missing                 = true;
                    }
                });
            }
        });

        if(state.missing) {
            updateSettings(arguments.trainerid, filledSettings);
        }
        return filledSettings;
    }

    /**
     * Web path to a trainer's profile icon image
     *
     * @icon the trainer's icon column
     */
    public string function buildIconPath(required string icon) {
        return "/includes/images/icons/#arguments.icon##variables.imageExtension#";
    }

    /**
     * Alt text for a trainer's profile icon image
     *
     * @icon the trainer's icon column
     */
    public string function buildIconAltText(required string icon) {
        return "#ucFirst(arguments.icon)# profile icon";
    }

    /**
     * Author details shown beside a trainer's blog or comment - empty when there is no trainer
     *
     * @username the trainer's username, empty when there is no trainer
     * @icon     the trainer's icon
     */
    public struct function buildAuthor(string username = "", string icon = "") {
        if(!len(arguments.username)) {
            return {};
        }
        return {
            username   : arguments.username,
            iconpath   : buildIconPath(arguments.icon),
            iconalttext: buildIconAltText(arguments.icon)
        };
    }

    /**
     * Evict the cached trainer and their cached level so the next load reads the database
     * Call after anything that changes the trainer, their settings, or their stats
     *
     * @trainerid pk of trainer
     */
    public void function clearCache(required numeric trainerid) {
        trainerCache.clear(getCacheKey(arguments.trainerid));
        trainerCache.clear(getLevelCacheKey(arguments.trainerid));
        return;
    }

    /**
     * Whether the icon can be picked - the base icons, plus the trainer's unlocked icons
     * The trainer's current icon always passes, so keeping it never fails
     *
     * @icon      icon name (the file name without its extension)
     * @trainerid (optional) pk of the trainer the icon is for - omit when registering (base icons only)
     */
    public boolean function isAllowedIcon(required string icon, numeric trainerid) {
        var wanted  = lCase(trim(arguments.icon));
        var allowed = duplicate(getIconMap());

        if(!isNull(arguments.trainerid)) {
            if(wanted == lCase(getFromId(arguments.trainerid).icon ?: "")) {
                return true;
            }
            allowed.append(getUnlockedIcons(arguments.trainerid), true);
        }

        // Icon names can have spaces ("Shiny Mew") - their files don't (shinymew)
        return allowed.some((name) => lCase(replace(name, " ", "", "all")) == wanted);
    }

    /**
     * Cache key for the trainer getFromId loads
     *
     * @trainerid pk of trainer
     */
    private string function getCacheKey(required numeric trainerid) {
        return "trainer.getFromId|trainerid=#arguments.trainerid#";
    }

    /**
     * Cache key for the level getCurrentLevel loads
     *
     * @trainerid pk of trainer
     */
    private string function getLevelCacheKey(required numeric trainerid) {
        return "#arguments.trainerid#|trainer.getCurrentLevel";
    }

    /**
     * Datatable getter for the trainer table
     */
    public struct function getTable(
        required numeric records,
        required numeric offset,
        required string search   = "",
        required string orderCol = "",
        required string orderDir = ""
    ) {
        var fromSQL = "FROM trainer";
        var filters = pagination.buildFilters(searchColumns = ["trainer.username", "trainer.email"], search = search);

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
            baseWhere     = filters.baseWhere,
            whereSQL      = filters.whereSQL,
            whereParams   = filters.whereParams,
            totalCacheKey = "trainer.totalRecords",
            cacheMinutes  = 5,
            fetchRows     = (pageParams) => queryExecute(
                "
                SELECT trainer.id, COALESCE(trainer.icon, '') AS icon, trainer.username, trainer.email,
                    trainer.verified, trainer.securitylevel, trainer.lastlogin
                #fromSQL#
                #filters.whereSQL#
                #orderBy#
                LIMIT :records
                OFFSET :offset
                ",
                pageParams,
                {returnType: "array"}
            )
        );

        var securityLevels = getSecurityLevels();

        return {
            data: page.rows.map((row) => {
                return {
                    trainerid    : row.id,
                    edit         : "",
                    icon         : buildIconPath(row.icon),
                    iconAltText  : buildIconAltText(row.icon),
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
     * @trainerid trainer pk
     * @settings  settings struct
     */
    public void function updateSettings(required numeric trainerid, required struct settings) {
        queryExecute(
            "UPDATE trainer SET settings = CAST(:settings AS jsonb) WHERE id = :trainerid",
            {
                settings : {value: serializeJSON(arguments.settings), cfsqltype: "varchar"},
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"}
            }
        );
        clearCache(arguments.trainerid);
        return;
    }

    /**
     * Stamps the trainer's last login
     * The logged in user object shows it straight away, the database row is written in the background
     *
     * @user the logged in user (objects.userObj)
     */
    public void function updateLastLogin(required component user) {
        var loginTime = now();
        var trainerid = arguments.user.getId();

        arguments.user.setLastLogin(loginTime);

        async.newFuture(() => {
            queryExecute(
                "UPDATE trainer SET lastlogin = :lastlogin WHERE id = :trainerid",
                {
                    lastlogin: {value: loginTime, cfsqltype: "timestamp"},
                    trainerid: {value: trainerid, cfsqltype: "integer"}
                }
            );
        });
    }

}
