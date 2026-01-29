component {

    function run(qb, mockdata) {
        var data        = [];
        var pokemonData = deserializeJSON(fileRead('resources/pokedex.json'));
        pokemonData.each(
            (name, pokemon) => {
                pokemon.evolutions.each((evolution) => {
                    // Select the pokemon id
                    var pokemonQb     = qb.newQuery();
                    var pokemonRecord = pokemonQb
                        .from('pokemon')
                        .where('number', {value: pokemon.number, cfsqltype: 'numeric'})
                        .andWhere('name', {value: pokemon.name, cfsqltype: 'varchar'})
                        .andWhere('gender', {value: pokemon.gender, cfsqltype: 'varchar'})
                        .first();

                    if(!pokemonRecord.keyExists('id')) continue; // safeguard, but this shouldn't happen

                    // Select the evolution id
                    var evoQb = qb.newQuery();
                    var evo   = evoQb
                        .from('pokemon')
                        .where('number', {value: evolution.number, cfsqltype: 'numeric'})
                        .andWhere('name', {value: evolution.name, cfsqltype: 'varchar'})
                        .andWhere('gender', {value: evolution.gender, cfsqltype: 'varchar'})
                        .first();

                    if(evo.keyExists('id')) {
                        var freshQB = qb.newQuery();
                        freshQB
                            .table('evolution')
                            .insert({
                                'pokemonid'  : {value: pokemonRecord.id, cfsqltype: 'numeric'},
                                'evolutionid': {value: evo.id, cfsqltype: 'numeric'},
                                'special'    : {value: evolution.special, cfsqltype: 'boolean'},
                                'cost'       : {value: evolution.cost, cfsqltype: 'numeric'},
                                'condition'  : {value: evolution.condition, cfsqltype: 'varchar'}
                            });
                    }
                });
            },
            true,
            50
        );
    }

}
