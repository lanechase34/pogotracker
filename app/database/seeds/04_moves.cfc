component extends="base" {

    function run(qb, mockdata) {
        var data     = [];
        var moveData = deserializeJSON(fileRead('resources/moves.json'));
        moveData.each((move, i) => {
            data.append({
                'energy'    : {value: move.energy, cfsqltype: 'decimal'},
                'nameid'    : toUTF8(move.nameid),
                'buffchance': {value: move.buffchance, cfsqltype: 'decimal'},
                'buffself'  : {value: move.buffself, cfsqltype: 'boolean'},
                'buffeffect': move.buffeffect,
                'name'      : toUTF8(move.name),
                'type'      : move.type,
                'damage'    : {value: move.damage, cfsqltype: 'decimal'},
                'turns'     : {value: move.turns, cfsqltype: 'decimal'}
            });
        });
        qb.table('move').insert(data);
    }

}
