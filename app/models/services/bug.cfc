component singleton accessors="true" {

    property name="async"          inject="asyncManager@coldbox";
    property name="cache"          inject="cachebox:appCache";
    property name="trainerService" inject="services.trainer";

    property name="datatableCols" type="array";

    public void function init() {
        setDatatableCols([
            'bug.created',
            'bug.ip',
            'bug.event',
            'bug.message',
            'trainer.username',
            'bug.stack'
        ]);
    }

    /**
     * Log a new bug including exception stack trace
     */
    public void function logBug(
        required string ip,
        required string event,
        required string message,
        required string stack,
        numeric trainerid = -1
    ) {
        var bug = entityNew(
            'bug',
            {
                'ip'     : arguments.ip,
                'event'  : arguments.event,
                'message': arguments.message,
                'stack'  : arguments.stack
            }
        );

        if(arguments.trainerid > 0) {
            var trainer = trainerService.getFromId(arguments.trainerid);
            bug.setTrainer(trainer);
        }

        entitySave(bug);
        ormFlush();
        return;
    }

    /**
     * Datatable GET for bug log table
     */
    public struct function get(
        required numeric records,
        required numeric offset,
        required string search   = '',
        required string orderCol = '',
        required string orderDir = ''
    ) {
        var orderBy = '';
        if(orderCol.len() && orderDir.len()) {
            orderBy = 'order by #getDatatableCols()[orderCol + 1]# #orderDir#';
        }

        var results = async
            .all(
                () => ormExecuteQuery(
                    '
                    select bug
                    from bug as bug
                    left outer join bug.trainer as trainer
                    where upper(bug.event) like :search
                        or upper(bug.message) like :search
                        or upper(trainer.username) like :search
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
                    select count(bug.id)
                    from bug as bug
                    left outer join bug.trainer as trainer
                    where upper(bug.event) like :search
                        or upper(bug.message) like :search
                        or upper(trainer.username) like :search
                    ',
                    {search: '%#uCase(search)#%'}
                ),
                () => getTotalRecords()
            )
            .get();

        var bugs          = results[1];
        var filteredCount = results[2];
        var totalRecords  = results[3];

        return {
            data: bugs.map((bug) => {
                return [
                    bug.getTimestamp(),
                    bug.getIP(),
                    bug.getEvent(),
                    bug.getMessage(),
                    bug.getUsername(),
                    encodeForHTML(bug.getStack())
                ];
            }),
            recordsTotal   : totalRecords,
            recordsFiltered: filteredCount
        };
    }

    /**
     * Get total count of records in bug table
     */
    public numeric function getTotalRecords() {
        var cacheKey = 'bug.getTotalRecords';
        var count    = cache.get(cacheKey);
        if(isNull(count)) {
            count = ormExecuteQuery('select count(id) from bug')[1];
            cache.set(cacheKey, count, 5, 5);
        }
        return count;
    }

}
