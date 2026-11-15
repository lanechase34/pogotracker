component extends="base" {

    function run(qb, mockdata) {
        var costumeData = getCostumeData();
        costumeData.each(
            (name, pokemon) => {
                var freshQB = qb.newQuery();
                freshQB
                    .table("pokemon")
                    .insert({
                        "number"    : {value: pokemon.number, cfsqltype: "integer"},
                        "name"      : {value: pokemon.name, cfsqltype: "varchar"},
                        "generation": {
                            value    : pokemon.generation,
                            cfsqltype: "decimal",
                            scale    : 1
                        },
                        "gender" : {value: pokemon.gender, cfsqltype: "varchar"},
                        "live"   : pokemon.live,
                        "shiny"  : pokemon.shiny,
                        "type1"  : pokemon.type[1],
                        "type2"  : {value: pokemon.type.len() == 2 ? pokemon.type[2] : "", cfsqltype: "varchar"},
                        "attack" : {value: pokemon.attack, cfsqltype: "integer"},
                        "defense": {value: pokemon.defense, cfsqltype: "integer"},
                        "hp"     : {value: pokemon.hp, cfsqltype: "integer"},
                        "catch"  : {
                            value    : pokemon.catch,
                            cfsqltype: "decimal",
                            scale    : 2
                        },
                        "flee": {
                            value    : pokemon.flee,
                            cfsqltype: "decimal",
                            scale    : 2
                        },
                        "form"       : pokemon.form,
                        "mega"       : pokemon.mega,
                        "sprite"     : {value: pokemon.sprite, cfsqltype: "varchar"},
                        "tradable"   : pokemon.tradable,
                        "shadow"     : pokemon.shadow,
                        "shadowshiny": pokemon.shadowshiny,
                        "giga"       : pokemon.giga,
                        "formtype"   : {value: pokemon.keyExists("formtype") ? pokemon.formtype : "", cfsqltype: "varchar"},
                        "ses"        : {value: pokemon.ses, cfsqltype: "varchar"},
                        "costume"    : pokemon.costume,
                        "costumetype": {value: pokemon.costumetype, cfsqltype: "varchar"}
                    });
            },
            true,
            50
        );

        // Add evolutions
        costumeData.each((name, pokemon) => {
            pokemon.evolutions.each((evolution) => {
                // Select the pokemon id
                var pokemonQB     = qb.newQuery();
                var pokemonRecord = pokemonQB
                    .from("pokemon")
                    .where("number", {value: pokemon.number, cfsqltype: "integer"})
                    .andWhere("name", {value: pokemon.name, cfsqltype: "varchar"})
                    .andWhere("gender", {value: pokemon.gender, cfsqltype: "varchar"})
                    .andWhere("costume", {value: true, cfsqltype: "boolean"})
                    .andWhere("costumetype", {value: pokemon.costumetype, cfsqltype: "varchar"})
                    .first();

                if(!pokemonRecord.keyExists("id")) continue; // safeguard, but this shouldn't happen

                // Select the evolution id
                var evoQB = qb.newQuery();
                var evo   = evoQB
                    .from("pokemon")
                    .where("number", {value: evolution.number, cfsqltype: "integer"})
                    .andWhere("name", {value: evolution.name, cfsqltype: "varchar"})
                    .andWhere("gender", {value: evolution.gender, cfsqltype: "varchar"})
                    .andWhere("costume", {value: true, cfsqltype: "boolean"})
                    .andWhere("costumetype", {value: evolution.costumetype, cfsqltype: "varchar"})
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
        });
    }

}
