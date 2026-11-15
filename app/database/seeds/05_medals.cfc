component extends="base" {

    function run(qb, mockdata) {
        var medalData = deserializeJSON(fileRead("resources/medals.json", "UTF-8"));
        qb.table("medal")
            .insert(
                medalData
                    .keyArray()
                    .map((name) => (
                        {
                            "name"        : name,
                            "description" : medalData[name].description,
                            "bronze"      : medalData[name].bronze,
                            "silver"      : medalData[name].silver,
                            "gold"        : medalData[name].gold,
                            "platinum"    : medalData[name].platinum,
                            "displayorder": medalData[name].order
                        }
                    ))
            );
    }

}
