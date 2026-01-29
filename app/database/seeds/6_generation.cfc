component {

    function run(qb, mockdata) {
        var data          = [];
        var generationMap = deserializeJSON(fileRead('../../../includes/assets/generationmap.json'));
        generationMap.each((key, value) => {
            data.append({'generation': {value: key, cfsqltype: 'numeric'}, 'region': value});
        });

        qb.table('generation').insert(data);
    }

}
