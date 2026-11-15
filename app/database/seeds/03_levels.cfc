component extends="base" {

    function run(qb, mockdata) {
        var levelMap = deserializeJSON(fileRead("../../includes/assets/levels.json", "UTF-8"));

        qb.table("level")
            .insert(
                levelMap
                    .keyArray()
                    .map((key) => ({"level": parseNumber(key), "requiredxp": parseNumber(levelMap[key])}))
            );
    }

}
