component extends="base" {

    function run(qb, mockdata) {
        var data = [
            {
                'accepted' : true,
                'trainerid': 2,
                'friendid' : 3
            },
            {
                'accepted' : true,
                'trainerid': 2,
                'friendid' : 4
            },
            {
                'accepted' : true,
                'trainerid': 2,
                'friendid' : 5
            },
            {
                'accepted' : true,
                'trainerid': 3,
                'friendid' : 2
            },
            {
                'accepted' : true,
                'trainerid': 4,
                'friendid' : 2
            },
            {
                'accepted' : true,
                'trainerid': 5,
                'friendid' : 2
            }
        ];

        qb.table('friend').insert(data);
    }

}
