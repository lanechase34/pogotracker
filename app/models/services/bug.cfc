component singleton accessors="true" {

    property name="cacheService"   inject="services.cache";
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

    public struct function get(
        required numeric records,
        required numeric offset,
        required string search   = '',
        required string orderCol = '',
        required string orderDir = ''
    ) {
        var orderBy = '';
        if(arguments.orderCol.len() && arguments.orderDir.len()) {
            orderBy = 'order by #getDatatableCols()[arguments.orderCol + 1]# #arguments.orderDir#';
        }

        var bugs = ormExecuteQuery(
            '
            select bug
            from bug as bug
            left outer join bug.trainer as trainer
            where upper(bug.event) like :search
                or upper(bug.message) like :search
                or upper(trainer.username) like :search
            #orderBy#
            ',
            {search: '%#uCase(arguments.search)#%'},
            {
                offset    : arguments.offset,
                maxResults: arguments.records,
                cacheable : true,
                cachename : 'defaultCache'
            }
        );

        var filteredCount = ormExecuteQuery(
            '
            select count(bug.id)
            from bug as bug
            left outer join bug.trainer as trainer
            where upper(bug.event) like :search
                or upper(bug.message) like :search
                or upper(trainer.username) like :search
            ',
            {search: '%#uCase(arguments.search)#%'}
        );

        var data = [];
        bugs.each((bug) => {
            data.append([
                bug.getTimestamp(),
                bug.getIP(),
                bug.getEvent(),
                bug.getMessage(),
                bug.getUsername(),
                encodeForHTML(bug.getStack())
            ]);
        });

        return {
            data           : data,
            recordsTotal   : getTotalRecords(),
            recordsFiltered: filteredCount
        };
    }

    public numeric function getTotalRecords() {
        var cacheKey = 'bug.getTotalRecords';
        var count    = cacheService.get(cacheKey);
        if(isNull(count)) {
            count = ormExecuteQuery('select count(id) from bug')[1];
            cacheService.put(cacheKey, count, 5, 5);
        }
        return count;
    }

}
