component {

    function run(qb, mockdata) {
        var data      = [];
        var medalData = deserializeJSON(fileRead('resources/medals.json'));
        medalData.each((name, medal) => {
            data.append({
                'name'        : name,
                'description' : medal.description,
                'bronze'      : medal.bronze,
                'silver'      : medal.silver,
                'gold'        : medal.gold,
                'platinum'    : medal.platinum,
                'displayorder': medal.order
            });
        });
        qb.table('medal').insert(data);
    }

}
