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
    property name="resetSentDate" ormtype="timestamp" default="";

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

    // methods
    string function getFormattedFriendCode() {
        return reReplace(getFriendCode(), '([0-9]{4})', '\1-', 'all').left(-1);
    }

    any function getFormattedLastLogin() {
        if(isNull(getLastLogin())) {
            return '---';
        }

        return dateTimeFormat(getLastLogin(), 'mmm-dd-yyyy HH:nn:ss')
    }

    number function getEpochLastLogin() {
        if(isNull(getLastLogin())) return -1;
        return getLastLogin().getTime();
    }

    struct function getCurrentLevel() {
        var statStruct = {
            level      : '--',
            totalxp    : '',
            dateTracked: createDate(2000, 1, 1)
        };

        if(isNull(getStat()) || !getStat().len()) {
            return statStruct;
        }

        var latestStat = getStat()[1];

        statStruct.totalxp = latestStat.getXp();
        statStruct.level   = ormExecuteQuery(
            '
            select level.level
            from level as level
            where :latestxp > requiredxp
            order by level.level desc
            ',
            {'latestxp': statStruct.totalxp},
            false,
            {maxResults: 1}
        )[1];

        // Calculate the progress to the next level
        if(statStruct.level < 50) {
            statStruct.nextlevelxp = entityLoad('level', {'level': statStruct.level + 1}, true).getRequiredXp();
            statStruct.currlevelxp = entityLoad('level', {'level': statStruct.level}, true).getRequiredXp();

            statStruct.currxp      = statStruct.totalxp - statStruct.currlevelxp;
            statStruct.nextlevelxp = statStruct.nextlevelxp - statStruct.currlevelxp;
            statStruct.progress    = round(statStruct.currxp / statStruct.nextlevelxp, 2) * 100;
        }

        statStruct.totalxp     = numberFormat(statStruct.totalxp, ',');
        statStruct.dateTracked = dateFormat(latestStat.getCreated(), 'short');
        return statStruct;
    }

    array function getUnlockedIcons() {
        var icons = [];

        // caught badges
        var caught = ormExecuteQuery(
            '
            select count(pokedex.id) as caught, pokedex.pokemon.generation.region as region
            from pokedex as pokedex
            where pokedex.caught = true
            and pokedex.pokemon.mega = false
            and pokedex.trainer = :trainer
            group by pokedex.pokemon.generation.region, pokedex.pokemon.generation
            order by pokedex.pokemon.generation asc
            ',
            {trainer: this}
        );

        caught.each((curr) => {
            var region = curr[2];
            var caught = curr[1];

            if(region == 'Kanto') {
                if(caught >= 76) {
                    icons.append('Venusaur');
                    icons.append('Blastoise');
                    icons.append('Charizard');
                }
                if(caught == 151) {
                    icons.append('Mewtwo');
                }
            }

            if(region == 'Johto') {
                if(caught >= 75) {
                    icons.append('Lugia');
                    icons.append('Ho-Oh');
                }
                if(caught == 100) {
                    icons.append('Celebi');
                }
            }
        });

        if(getSecurityLevel() >= 60) {
            icons.append('Wobbuffet');
        }

        return icons;
    }

    string function getIconPath() {
        return '/includes/images/icons/#getIcon()##application.cbController.getSetting('imageExtension')#';
    }

    string function getIconAltText() {
        return '#ucFirst(getIcon())# profile icon';
    }

    // ORM does not play nice with JSON. The settings property is a jsonb field in postgres
    struct function getSettings() {
        var settings = queryExecute(
            '
            select settings
            from trainer
            where id = :trainerid
        ',
            {trainerid: {value: getId(), cfsqltype: 'integer'}}
        ).settings;
        return deserializeJSON(settings);
    }

    void function setSettings(required struct settings) {
        queryExecute(
            '
            update trainer
            set settings = cast(:settings as jsonb)
            where id = :trainerid
            ',
            {settings: {value: serializeJSON(arguments.settings)}, trainerid: {value: getId(), cfsqltype: 'integer'}}
        );
    }

}
