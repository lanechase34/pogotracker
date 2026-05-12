component extends="base" {

    function run(qb, mockdata) {
        var pokemonData = getPokemonData();
        pokemonData.each(
            (name, pokemon) => {
                pokemon.moves.each((move) => {
                    // Select the pokemon id and move id, insert pokemonmove record
                    var pokemonQb = qb.newQuery();
                    var pokemon   = pokemonQb
                        .from('pokemon')
                        .where('number', {value: pokemon.number, cfsqltype: 'numeric'})
                        .andWhere('name', {value: toUTF8(pokemon.name), cfsqltype: 'varchar'})
                        .andWhere('gender', {value: pokemon.gender, cfsqltype: 'varchar'})
                        .first();

                    var moveQb     = qb.newQuery();
                    var moveRecord = moveQb
                        .from('move')
                        .where('nameid', {value: toUTF8(move.nameid), cfsqltype: 'varchar'})
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
