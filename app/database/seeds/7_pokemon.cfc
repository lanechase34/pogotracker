component {

    function run(qb, mockdata) {
        var data        = [];
        var pokedexFile = fileOpen(
            file    = 'resources/pokedex.json',
            mode    = 'read',
            charset = 'UTF-8'
        );
        var pokemonData = deserializeJSON(fileRead(pokedexFile));
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
                        'sprite'     : pokemon.sprite,
                        'tradable'   : pokemon.tradable,
                        'shadow'     : pokemon.shadow,
                        'shadowshiny': pokemon.shadowshiny,
                        'giga'       : pokemon.giga,
                        'formtype'   : pokemon.keyExists('formtype') ? pokemon.formtype : '',
                        'ses'        : pokemon.ses
                    });
            },
            true,
            50
        );
    }

    // Detect if we are in windows environment (not UTF-8) and convert
    // Whatever encoding it is to UTF-8
    function toUTF8(string str) {
        if(createObject('java', 'java.lang.System').getProperty('file.encoding') != 'UTF-8') {
            var bytes = createObject('java', 'java.lang.String')
                .init(str)
                .getBytes(createObject('java', 'java.lang.System').getProperty('file.encoding'));
            return createObject('java', 'java.lang.String').init(bytes, 'UTF-8');
        }
        return str;
    }

}
