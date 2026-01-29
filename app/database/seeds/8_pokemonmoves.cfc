component {

    function run(qb, mockdata) {
        var data        = [];
        var pokemonData = deserializeJSON(fileRead('resources/pokedex.json'));
        pokemonData.each(
            (name, pokemon) => {
                pokemon.moves.each((move) => {
                    // Select the pokemon id and move id, insert pokemonmove record
                    var pokemonQb = qb.newQuery();
                    var pokemon   = pokemonQb
                        .from('pokemon')
                        .where('number', {value: pokemon.number, cfsqltype: 'numeric'})
                        .andWhere('name', {value: pokemon.name, cfsqltype: 'varchar'})
                        .andWhere('gender', {value: pokemon.gender, cfsqltype: 'varchar'})
                        .first();

                    var moveQb     = qb.newQuery();
                    var moveRecord = moveQb
                        .from('move')
                        .where('nameid', {value: move.nameid, cfsqltype: 'varchar'})
                        .first();

                    if(pokemon.keyExists('id') && moveRecord.keyExists('id')) {
                        var freshQB = qb.newQuery();
                        freshQB
                            .table('pokemonmove')
                            .insert({
                                'pokemonid': pokemon.id,
                                'moveid'   : moveRecord.id,
                                'shadow'   : move.shadow,
                                'legacy'   : move.legacy
                            });
                    }
                });
            },
            true,
            50
        );
    }

}
