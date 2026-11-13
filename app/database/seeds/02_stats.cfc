component extends="base" {

    function run(qb, mockdata) {
        var data  = [];
        var total = 500;

        for(var i = 1; i <= total; i++) {
            data.append({
                "created"  : dateAdd("d", -1 * i, now()),
                "caught"   : randRange(100, 100000),
                "spun"     : randRange(100, 100000),
                "walked"   : randRange(100, 100000),
                "xp"       : randRange(100, 100000),
                "trainerid": randRange(1, 3)
            });
        };

        qb.table("stat").insert(data);
    }

}
