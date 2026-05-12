component extends="base" {

    function run(qb, mockdata) {
        var moveData = deserializeJSON(fileRead('resources/moves.json'));
        qb.table('move')
            .insert(
                moveData.map((move) => (
                    {
                        'energy'    : {value: move.energy, cfsqltype: 'decimal'},
                        'nameid'    : toUTF8(move.nameid),
                        'buffchance': {value: move.buffchance, cfsqltype: 'decimal'},
                        'buffself'  : {value: move.buffself, cfsqltype: 'boolean'},
                        'buffeffect': move.buffeffect,
                        'name'      : toUTF8(move.name),
                        'type'      : move.type,
                        'damage'    : {value: move.damage, cfsqltype: 'decimal'},
                        'turns'     : {value: move.turns, cfsqltype: 'decimal'}
                    }
                ))
            );
    }

}
