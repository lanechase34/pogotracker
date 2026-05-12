component extends="base" {

    function run(qb, mockdata) {
        var levelMap = deserializeJSON(fileRead('../../includes/assets/levels.json'));

        qb.table('level')
            .insert(
                levelMap
                    .keyArray()
                    .map((key) => ({'level': parseNumber(key), 'requiredxp': parseNumber(levelMap[key])}))
            );
    }

}
