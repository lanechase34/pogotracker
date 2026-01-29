component extends="coldbox.system.testing.BaseTestCase" {

    function init() {
        customService = getInstance('services.custom');
    }

    public numeric function count() {
        return queryExecute(
            '
            select count(id) as count
            from custom
            '
        ).count;
    }

    public numeric function getMostRecentCreated() {
        return queryExecute(
            '
            select max(id) as id
            from custom
            '
        ).id;
    }

    public void function deleteByName(required string name) {
        var customid = queryExecute(
            '
            select id
            from custom
            where name = :name
            ',
            {name: {value: arguments.name, cfsqltype: 'varchar'}}
        ).id;

        if(customid.len()) {
            queryExecute(
                '
                delete from custompokedex
                where customid = :customid
                ',
                {customid: {value: customid, cfsqltype: 'numeric'}}
            );

            queryExecute(
                '
                delete from custom
                where id = :customid
                ',
                {customid: {value: customid, cfsqltype: 'numeric'}}
            );
        }

        return;
    }

}
