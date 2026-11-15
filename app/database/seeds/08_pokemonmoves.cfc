component extends="base" {

    function run(qb, mockdata) {
        var pokemonData = getPokemonData();
        pokemonData.each(
            (name, pokemon) => {
                pokemon.moves.each((move) => {
                    // Select the pokemon id and move id, insert pokemonmove record
                    var pokemonQB = qb.newQuery();
                    var pokemon   = pokemonQB
                        .from("pokemon")
                        .where("number", {value: pokemon.number, cfsqltype: "integer"})
                        .andWhere("name", {value: pokemon.name, cfsqltype: "varchar"})
                        .andWhere("gender", {value: pokemon.gender, cfsqltype: "varchar"})
                        .first();

                    var moveQB     = qb.newQuery();
                    var moveRecord = moveQB
                        .from("move")
                        .where("nameid", {value: move.nameid, cfsqltype: "varchar"})
                        .first();

                    if(pokemon.keyExists("id") && moveRecord.keyExists("id")) {
                        var freshQB = qb.newQuery();
                        freshQB
                            .table("pokemonmove")
                            .insert({
                                "pokemonid": pokemon.id,
                                "moveid"   : moveRecord.id,
                                "shadow"   : move.shadow,
                                "legacy"   : move.legacy
                            });
                    }
                });
            },
            true,
            50
        );
    }

}
