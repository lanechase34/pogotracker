component extends="base" {

    function run(qb, mockdata) {
        var medalData = deserializeJSON(fileRead('resources/medals.json'));
        qb.table('medal')
            .insert(
                medalData
                    .keyArray()
                    .map((name) => (
                        {
                            'name'        : toUTF8(name),
                            'description' : toUTF8(medalData[name].description),
                            'bronze'      : medalData[name].bronze,
                            'silver'      : medalData[name].silver,
                            'gold'        : medalData[name].gold,
                            'platinum'    : medalData[name].platinum,
                            'displayorder': medalData[name].order
                        }
                    ))
            );
    }

}
