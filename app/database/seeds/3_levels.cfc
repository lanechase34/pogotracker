component {

    function run(qb, mockdata) {
        var data     = [];
        var levelMap = deserializeJSON(fileRead('../../../includes/assets/levels.json'));
        levelMap.each((key, value) => {
            data.append({'level': parseNumber(key), 'requiredxp': parseNumber(value)});
        });

        qb.table('level').insert(data);
    }

}
