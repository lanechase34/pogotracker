component extends="base" {

    function run(qb, mockdata) {
        var pokemonData = getPokemonData();
        pokemonData.each(
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
                        "costume"    : false,
                        "costumetype": {value: "", cfsqltype: "varchar"}
                    });
            },
            true,
            50
        );
    }

}
