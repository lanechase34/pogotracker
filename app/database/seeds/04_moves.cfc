component extends="base" {

    function run(qb, mockdata) {
        var moveData = deserializeJSON(fileRead("resources/moves.json", "UTF-8"));
        qb.table("move")
            .insert(
                moveData.map((move) => (
                    {
                        "energy": {
                            value    : move.energy,
                            cfsqltype: "decimal",
                            scale    : 2
                        },
                        "nameid"    : move.nameid,
                        "buffchance": {
                            value    : move.buffchance,
                            cfsqltype: "decimal",
                            scale    : 4
                        },
                        "buffself"  : {value: move.buffself, cfsqltype: "boolean"},
                        "buffeffect": move.buffeffect,
                        "name"      : move.name,
                        "type"      : move.type,
                        "damage"    : {
                            value    : move.damage,
                            cfsqltype: "decimal",
                            scale    : 2
                        },
                        "turns": {
                            value    : move.turns,
                            cfsqltype: "decimal",
                            scale    : 2
                        }
                    }
                ))
            );
    }

}
