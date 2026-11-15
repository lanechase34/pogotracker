component extends="base" {

    function run(qb, mockdata) {
        var generationMap = deserializeJSON(fileRead("../../includes/assets/generationmap.json", "UTF-8"));
        qb.table("generation")
            .insert(
                generationMap
                    .keyArray()
                    .map((generation) => (
                        {
                            "generation": {
                                value    : generation,
                                cfsqltype: "decimal",
                                scale    : 1
                            },
                            "region": generationMap[generation]
                        }
                    ))
            );
    }

}
