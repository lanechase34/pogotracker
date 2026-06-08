component extends="base" {

    function run(qb, mockdata) {
        var costumeData = getCostumeData();
        costumeData.each(
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
                        'costume'    : pokemon.costume,
                        'costumetype': {value: toUTF8(pokemon.costumetype), cfsqltype: 'varchar'}
                    });
            },
            true,
            50
        );

        // Add evolutions
        costumeData.each((name, pokemon) => {
            pokemon.evolutions.each((evolution) => {
                // Select the pokemon id
                var pokemonQb     = qb.newQuery();
                var pokemonRecord = pokemonQb
                    .from('pokemon')
                    .where('number', {value: pokemon.number, cfsqltype: 'numeric'})
                    .andWhere('name', {value: toUTF8(pokemon.name), cfsqltype: 'varchar'})
                    .andWhere('gender', {value: pokemon.gender, cfsqltype: 'varchar'})
                    .andWhere('costume', {value: true, cfsqltype: 'boolean'})
                    .andWhere('costumetype', {value: toUTF8(pokemon.costumetype), cfsqltype: 'varchar'})
                    .first();

                if(!pokemonRecord.keyExists('id')) continue; // safeguard, but this shouldn't happen

                // Select the evolution id
                var evoQb = qb.newQuery();
                var evo   = evoQb
                    .from('pokemon')
                    .where('number', {value: evolution.number, cfsqltype: 'numeric'})
                    .andWhere('name', {value: toUTF8(evolution.name), cfsqltype: 'varchar'})
                    .andWhere('gender', {value: evolution.gender, cfsqltype: 'varchar'})
                    .andWhere('costume', {value: true, cfsqltype: 'boolean'})
                    .andWhere('costumetype', {value: toUTF8(evolution.costumetype), cfsqltype: 'varchar'})
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
        });
    }

}
