component extends="base" {

    function run(qb, mockdata) {
        var data      = [];
        var medalData = deserializeJSON(fileRead('resources/medals.json'));
        medalData.each((name, medal) => {
            data.append({
                'name'        : toUTF8(name),
                'description' : toUTF8(medal.description),
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
