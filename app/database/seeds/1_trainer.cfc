component {

    function run(qb, mockdata) {
        var data = [
            {
                'username'     : 'chaz14x',
                'email'        : 'lanechase34@outlook.com',
                'password'     : createUUID(),
                'salt'         : createUUID(),
                'securitylevel': 60,
                'friendcode'   : '123412341235',
                'icon'         : 'treecko',
                'verified'     : true
            },
            {
                'username'     : 'test_0',
                'email'        : 'test_0@gmail.com',
                'password'     : createUUID(),
                'salt'         : createUUID(),
                'securitylevel': 60,
                'friendcode'   : '123412341234',
                'icon'         : 'mudkip',
                'verified'     : true
            }
        ];

        var amount = 50;
        for(var i = 1; i <= amount; i++) {
            data.append({
                'username'     : 'test_#i#',
                'email'        : 'test_#i#@gmail.com',
                'password'     : createUUID(),
                'salt'         : createUUID(),
                'securitylevel': 10,
                'friendcode'   : makeFriendCode(),
                'icon'         : 'torchic',
                'verified'     : true
            });
        }

        qb.table('trainer').insert(data);
    }


    string function makeFriendCode() {
        var out    = '';
        var groups = 3;

        for(var i = 1; i <= groups; i++) {
            out &= '#randRange(1111, 9999)#';
        }

        return out;
    }

}
