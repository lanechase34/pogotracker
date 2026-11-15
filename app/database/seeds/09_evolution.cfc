component extends="base" {

    function run(qb, mockdata) {
        var pokemonData = getPokemonData();
        pokemonData.each(
            (name, pokemon) => {
                pokemon.evolutions.each((evolution) => {
                    // Select the pokemon id
                    var pokemonQB     = qb.newQuery();
                    var pokemonRecord = pokemonQB
                        .from("pokemon")
                        .where("number", {value: pokemon.number, cfsqltype: "integer"})
                        .andWhere("name", {value: pokemon.name, cfsqltype: "varchar"})
                        .andWhere("gender", {value: pokemon.gender, cfsqltype: "varchar"})
                        .first();

                    if(!pokemonRecord.keyExists("id")) continue; // safeguard, but this shouldn't happen

                    // Select the evolution id
                    var evoQB = qb.newQuery();
                    var evo   = evoQB
                        .from("pokemon")
                        .where("number", {value: evolution.number, cfsqltype: "integer"})
                        .andWhere("name", {value: evolution.name, cfsqltype: "varchar"})
                        .andWhere("gender", {value: evolution.gender, cfsqltype: "varchar"})
                        .first();

                    if(evo.keyExists("id")) {
                        var freshQB = qb.newQuery();
                        freshQB
                            .table("evolution")
                            .insert({
                                "pokemonid"  : {value: pokemonRecord.id, cfsqltype: "integer"},
                                "evolutionid": {value: evo.id, cfsqltype: "integer"},
                                "special"    : {value: evolution.special, cfsqltype: "boolean"},
                                "cost"       : {value: evolution.cost, cfsqltype: "integer"},
                                "condition"  : {value: evolution.condition, cfsqltype: "varchar"}
                            });
                    }
                });
            },
            true,
            50
        );
    }

}
