component extends="base" {

    function run(qb, mockdata) {
        var pokemonData = getPokemonData();
        pokemonData.each(
            (name, pokemon) => {
                var freshQB = qb.newQuery();
                freshQB
                    .table('pokemon')
                    .insert({
                        'number'     : {value: pokemon.number, cfsqltype: 'numeric'},
                        'name'       : {value: toUTF8(pokemon.name), cfsqltype: 'varchar'},
                        'generation' : {value: pokemon.generation, cfsqltype: 'numeric'},
                        'gender'     : {value: pokemon.gender, cfsqltype: 'varchar'},
                        'live'       : pokemon.live,
                        'shiny'      : pokemon.shiny,
                        'type1'      : pokemon.type[1],
                        'type2'      : {value: pokemon.type.len() == 2 ? pokemon.type[2] : '', cfsqltype: 'varchar'},
                        'attack'     : {value: pokemon.attack, cfsqltype: 'numeric'},
                        'defense'    : {value: pokemon.defense, cfsqltype: 'numeric'},
                        'hp'         : {value: pokemon.hp, cfsqltype: 'numeric'},
                        'catch'      : {value: pokemon.catch, cfsqltype: 'numeric'},
                        'flee'       : {value: pokemon.flee, cfsqltype: 'numeric'},
                        'form'       : pokemon.form,
                        'mega'       : pokemon.mega,
                        'sprite'     : {value: toUTF8(pokemon.sprite), cfsqltype: 'varchar'},
                        'tradable'   : pokemon.tradable,
                        'shadow'     : pokemon.shadow,
                        'shadowshiny': pokemon.shadowshiny,
                        'giga'       : pokemon.giga,
                        'formtype'   : {value: pokemon.keyExists('formtype') ? pokemon.formtype : '', cfsqltype: 'varchar'},
                        'ses'        : {value: pokemon.ses, cfsqltype: 'varchar'},
                        'costume'    : false,
                        'costumetype': {value: '', cfsqltype: 'varchar'}
                    });
            },
            true,
            50
        );
    }

}
