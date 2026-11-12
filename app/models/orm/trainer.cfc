component persistent="true" extends="base" {

    // columns
    property name="username" ormtype="string" length="30";
    property name="email"    ormtype="string" length="100";
    property name="password" ormtype="string" length="128";
    property name="salt"     ormtype="salt"   length="128";
    property name="lastlogin"     ormtype="timestamp";
    property name="securitylevel" ormtype="integer";
    property name="friendcode" ormtype="string" length="12";
    property name="icon"       ormtype="string" length="25";
    property name="verified" ormtype="boolean" default="0";
    property name="verificationCode" ormtype="string" length="128";
    property name="verificationSentDate" ormtype="timestamp" default="";
    property name="resetCode" ormtype="string" length="128";
    property name="resetSentDate"  ormtype="timestamp" default="";
    property name="sessionVersion" ormtype="integer"   default="0";

    // relations
    property name="pokedex"      fieldtype="one-to-many" cfc="pokedex"      lazy="true";
    property name="custom"       fieldtype="one-to-many" cfc="custom"       lazy="true";
    property name="friend"       fieldtype="one-to-many" cfc="friend"       lazy="true";
    property name="blog"         fieldtype="one-to-many" cfc="blog"         lazy="true";
    property name="audit"        fieldtype="one-to-many" cfc="audit"        lazy="true";
    property name="trainermedal" fieldtype="one-to-many" cfc="trainermedal" lazy="true";
    property name="comment"      fieldtype="one-to-many" cfc="comment"      lazy="true";
    property name="persist"      fieldtype="one-to-many" cfc="persist"      lazy="true";
    property name="stat" fieldtype="one-to-many" cfc="stat" lazy="true" orderBy="created desc";

    /**
     * True if this trainer has any of the permissions (user, trusted, admin, developer)
     * Permissions map to a minimum security level
     * Unverified trainers have no permissions until they verify their email
     *
     * @permission permission name or list
     */
    boolean function hasPermission(required permission) {
        if(!(getVerified() ?: false)) return false;

        var permissions   = application.cbController.getSetting("permissions");
        var securityLevel = val(getSecurityLevel() ?: 0);

        return listToArray(arguments.permission).some((name) => {
            name = trim(name);
            return permissions.keyExists(name) && securityLevel >= permissions[name];
        });
    }

    /**
     * Roles and permissions are the same thing here
     */
    boolean function hasRole(required role) {
        return hasPermission(arguments.role);
    }

    // methods
    string function getFormattedFriendCode() {
        return reReplace(getFriendCode(), "([0-9]{4})", "\1-", "all").left(-1);
    }

    /**
     * Most recent stat row
     */
    any function getLatestStat() {
        var latest = ormExecuteQuery(
            "from stat where trainer.id = :trainerid order by created desc",
            {"trainerid": getId()},
            {maxResults: 1}
        );
        if(!latest.len()) {
            return;
        }
        return latest[1];
    }

    /**
     * Current level and xp progress from the latest stat
     * Not memoized - stats are recorded from several places and it's only shown on the profile/stats pages
     */
    struct function getCurrentLevel() {
        // No stat recorded yet
        var latestStat = getLatestStat();
        if(isNull(latestStat)) {
            return {
                level      : "--",
                totalxp    : "",
                dateTracked: createDate(2000, 1, 1)
            };
        }

        // Total XP from the latest recorded stat
        var totalxp = latestStat.getXp();

        // Select the current level and the next level
        var levelData = queryExecute(
            "
            SELECT curr.level, curr.requiredxp AS currlevelxp, next.requiredxp AS nextlevelxp
            FROM level curr
            LEFT JOIN level next ON next.level = curr.level + 1
            WHERE :totalxp > curr.requiredxp
            ORDER BY curr.level DESC
            LIMIT 1
            ",
            {totalxp: {value: totalxp, cfsqltype: "bigint"}}
        );

        var result = {
            level      : levelData.level,
            totalxp    : numberFormat(totalxp, ","),
            dateTracked: dateFormat(latestStat.getCreated(), "short")
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
     * Icons unlocked by pokedex progress, in display order
     * Progress counts base species only (no forms, costumes, megas or gigantamax) - the same set "register all" fills
     * need "all" means every base species in the region - for a shiny goal, every one with a released shiny
     */
    array function getUnlockedIcons() {
        var goals = [
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
        ];

        // Per region: base species, how many have a released shiny, and how many of each this trainer has registered
        var progress = {};
        queryExecute(
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
            {trainerid: {value: getId(), cfsqltype: "integer"}},
            {returntype: "array"}
        ).each((row) => {
            progress[row.region] = row;
        });

        var icons = [];
        goals.each((goal) => {
            if(!progress.keyExists(goal.region)) return;
            var region = progress[goal.region];
            var need   = goal.need == "all" ? region["#goal.progress#total"] : goal.need;

            if(need > 0 && region[goal.progress] >= need) {
                icons.append(goal.icons, true);
            }
        });

        if(hasPermission("developer")) {
            icons.append("Wobbuffet");
        }

        return icons;
    }

    string function getIconPath() {
        return "/includes/images/icons/#getIcon()##application.cbController.getSetting("imageExtension")#";
    }

    string function getIconAltText() {
        return "#ucFirst(getIcon())# profile icon";
    }

    /**
     * The trainer's stored settings (defaults are filled in at login - fillDefaultSettings)
     * ORM does not play nice with JSON. The settings property is a jsonb field in postgres
     * Memoized on the entity - setSettings() keeps it in sync
     */
    struct function getSettings() {
        if(!variables.keyExists("settingsMemo")) {
            var stored = queryExecute(
                "
                select settings
                from trainer
                where id = :trainerid
                ",
                {trainerid: {value: getId(), cfsqltype: "integer"}}
            ).settings;

            var settings           = isJSON(stored ?: "") ? deserializeJSON(stored) : {};
            variables.settingsMemo = isStruct(settings) ? settings : {};
        }
        return duplicate(variables.settingsMemo);
    }

    /**
     * Add any settings from settings.defaultSettings this trainer doesn't have yet (new keys, or new keys in a struct)
     * Runs on every login, only writes when something was missing
     */
    void function fillDefaultSettings() {
        var settings = getSettings();
        var defaults = application.cbController.getSetting("defaultSettings");
        var state    = {missing: false};

        defaults.each((key, value) => {
            if(!settings.keyExists(key)) {
                settings[key] = duplicate(value);
                state.missing = true;
            }
            else if(isStruct(value) && isStruct(settings[key])) {
                value.each((propname, propvalue) => {
                    if(!settings[key].keyExists(propname)) {
                        settings[key][propname] = propvalue;
                        state.missing           = true;
                    }
                });
            }
        });

        if(state.missing) {
            setSettings(settings);
        }
    }

    void function setSettings(required struct settings) {
        queryExecute(
            "
            update trainer
            set settings = cast(:settings as jsonb)
            where id = :trainerid
            ",
            {
                settings : {value: serializeJSON(arguments.settings), cfsqltype: "other"},
                trainerid: {value: getId(), cfsqltype: "integer"}
            }
        );
        variables.settingsMemo = duplicate(arguments.settings);
    }

}
