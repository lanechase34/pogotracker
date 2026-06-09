component extends="base" {

    function run(qb, mockdata) {
        // Set up blog img - use the preview img
        var uploadPath = '#replace(
            expandPath('#getDirectoryFromPath(getCurrentTemplatePath())#../../includes/uploads'),
            '\',
            '/',
            'all'
        )#';

        if(!directoryExists(uploadPath)) {
            directoryCreate(uploadPath);
        }

        if(!directoryExists('#uploadPath#/cards')) {
            directoryCreate('#uploadPath#/cards');
        }

        if(!directoryExists('#uploadPath#/full')) {
            directoryCreate('#uploadPath#/full');
        }

        if(!directoryExists('#uploadPath#/extra')) {
            directoryCreate('#uploadPath#/extra');
        }

        var imgId = '#left(createUUID().replace('-', '', 'all'), 25)#.webp';
        fileCopy('../../includes/images/preview.webp', '../../includes/uploads/cards/#imgId#');
        fileCopy('../../includes/images/preview.webp', '../../includes/uploads/full/#imgId#');

        var data = [];
        for(var i = 1; i <= 50; i++) {
            data.append({
                'trainerid': 1,
                'header'   : 'Blog number #i#',
                'meta'     : createUUID().left(10),
                'image'    : imgId,
                'alttext'  : '#i#',
                'bodyjson' : '',
                'body'     : createUUID(),
                'created'  : dateAdd('d', -i, now())
            });
        }

        qb.table('blog').insert(data);
    }

}
