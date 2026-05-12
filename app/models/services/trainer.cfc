component singleton accessors="true" {

    property name="async"           inject="asyncManager@coldbox";
    property name="cacheService"    inject="services.cache";
    property name="securityService" inject="services.security";

    property name="datatableCols" type="array";
    property name="iconMap"       type="array";

    public void function init() {
        setIconMap([
            'Bulbasaur',
            'Squirtle',
            'Charmander',
            'Chikorita',
            'Totodile',
            'Cyndaquil',
            'Treecko',
            'Mudkip',
            'Torchic',
            'Substitute'
        ]);

        setDatatableCols([
            '',
            'trainer.icon',
            'trainer.username',
            'trainer.email',
            'trainer.verified',
            'trainer.securitylevel',
            'trainer.lastlogin'
        ]);
    }

    public component function getFromId(required numeric trainerid) {
        var cacheKey = 'trainer.getFromId|trainerid=#arguments.trainerid#';
        var trainer  = cacheService.get(cacheKey);
        if(isNull(trainer)) {
            trainer = entityLoadByPK('trainer', arguments.trainerid);
            // Make sure relationships are loaded before being cached
            trainer.getCurrentLevel();
            trainer.getUnlockedIcons();
            trainer.getIconPath();
            trainer.getIconAltText();
            cacheService.put(cacheKey, trainer);
        }
        return trainer;
    }

    public struct function get(
        required numeric records,
        required numeric offset,
        required string search   = '',
        required string orderCol = '',
        required string orderDir = ''
    ) {
        var orderBy = '';
        if(arguments.orderCol.len() && arguments.orderDir.len()) {
            orderBy = 'order by #getDatatableCols()[arguments.orderCol + 1]# #arguments.orderDir# nulls last';
        }

        var results = async
            .all(
                () => ormExecuteQuery(
                    '
                    select trainer
                    from trainer as trainer
                    where upper(trainer.username) like :search
                        or upper(trainer.email) like :search
                    #orderBy#
                    ',
                    {search: '%#uCase(search)#%'},
                    {
                        offset    : offset,
                        maxResults: records,
                        cacheable : true,
                        cachename : 'defaultCache'
                    }
                ),
                () => ormExecuteQuery(
                    '
                    select count(trainer.id)
                    from trainer as trainer
                    where upper(trainer.username) like :search
                        or upper(trainer.email) like :search
                    ',
                    {search: '%#uCase(search)#%'},
                    true
                ),
                () => getTotalRecords()
            )
            .get();

        var trainers       = results[1];
        var filteredCount  = results[2];
        var totalRecords   = results[3];
        var securityLevels = securityService.getSecurityLevels();

        return {
            data: trainers.map((trainer) => {
                return {
                    trainerid    : trainer.getId(),
                    edit         : '',
                    icon         : trainer.getIconPath(),
                    iconAltText  : trainer.getIconAltText(),
                    username     : trainer.getUsername(),
                    email        : trainer.getEmail(),
                    verified     : trainer.getVerified(),
                    securitylevel: securityLevels[trainer.getSecurityLevel()],
                    lastlogin    : trainer.getFormattedLastLogin()
                };
            }),
            recordsTotal   : totalRecords,
            recordsFiltered: filteredCount
        };
    }

    public numeric function getTotalRecords() {
        var cacheKey = 'trainer.getTotalRecords';
        var count    = cacheService.get(cacheKey);
        if(isNull(count)) {
            count = ormExecuteQuery('select count(id) from trainer', {}, true);
            cacheService.put(cacheKey, count, 5, 5);
        }
        return count;
    }

    public void function updateSettings(required component trainer, required struct settings) {
        trainer.setSettings(arguments.settings);
        entitySave(trainer);
        ormFlush();
        return;
    }

}
