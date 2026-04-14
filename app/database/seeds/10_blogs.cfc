component extends="base" {

    function run(qb, mockdata) {
        var data = [];

        for(var i = 1; i <= 50; i++) {
            data.append({
                'trainerid': 1,
                'header'   : 'Blog number #i#',
                'meta'     : createUUID().left(10),
                'image'    : createUUID().left(10),
                'alttext'  : '#i#',
                'bodyjson' : '',
                'body'     : createUUID(),
                'created'  : dateAdd('d', -i, now())
            });
        }

        qb.table('blog').insert(data);
    }

}
