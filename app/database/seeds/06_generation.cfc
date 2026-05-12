component extends="base" {

    function run(qb, mockdata) {
        var generationMap = deserializeJSON(fileRead('../../includes/assets/generationmap.json'));
        qb.table('generation')
            .insert(
                generationMap
                    .keyArray()
                    .map((generation) => (
                        {'generation': {value: generation, cfsqltype: 'numeric'}, 'region': generationMap[generation]}
                    ))
            );
    }

}
