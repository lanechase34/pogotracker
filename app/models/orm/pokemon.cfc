component persistent="true" extends="base" {

    // columns
    property name="number" ormtype="integer";
    property name="name"   ormtype="string" length="50";
    property name="gender" ormtype="string" length="10";
    property name="live"        ormtype="boolean" default="0";
    property name="shiny"       ormtype="boolean" default="0";
    property name="shadow"      ormtype="boolean" default="0";
    property name="shadowshiny" ormtype="boolean" default="0";
    property name="type1" ormtype="string" length="10";
    property name="type2" ormtype="string" default="" length="10";
    property name="attack"  ormtype="integer";
    property name="defense" ormtype="integer";
    property name="hp"      ormtype="integer";
    property name="catch" ormtype="numeric" precision="2" scale="2";
    property name="flee"  ormtype="numeric" precision="2" scale="2";
    property name="form" ormtype="boolean" default="0";
    property name="mega" ormtype="boolean" default="0";
    property name="sprite" ormtype="string" length="50";
    property name="tradable" ormtype="boolean" default="1"; // can't trade certain pokemon ie mythicals
    property name="giga" ormtype="boolean" default="0";
    property name="formtype" ormtype="string" length="50";
    property name="ses"      ormtype="string" length="150";

    // relations
    property
        name     ="generation"
        fieldtype="many-to-one"
        cfc      ="generation"
        fkcolumn ="generation"
        mappedby ="generation"
        lazy     ="true";
    property name="pokedex"       fieldtype="one-to-many" cfc="pokedex"       lazy="true";
    property name="custompokedex" fieldtype="one-to-many" cfc="custompokedex" lazy="true";
    property name="pokemonmove"   fieldtype="one-to-many" cfc="pokemonmove"   lazy="true";
    property name="evolution"     fieldtype="one-to-many" cfc="evolution"     lazy="true";

    /**
     * Get names of evolutions
     */
    string function getEvolutionText() {
        if(isNull(getEvolution())) return '';

        return getEvolution().reduce((result, evolution, index) => {
            if(index > 1) {
                return '#result#, #evolution.getEvolution().getName()#';
            }
            return evolution.getEvolution().getName();
        });
    }

    /**
     * Get the move text belonging to this pokemon
     *
     * @type        fast or charge moves
     * @pokemonType all, normal, shadow, purified
     */
    string function getMovesText(required string type, required string pokemonType) {
        var moves = getMoves(arguments.type, arguments.pokemonType);
        if(!moves.len()) return '';

        var moveText = [];
        moves.each((move) => {
            moveText.append('#move.getMove().getName()##move.getShadow() ? '$' : ''##move.getLegacy() ? '*' : ''#');
        });
        return moveText.sort('text', 'asc').toList('<br>');
    }

    /**
     * Get the moves (as components) belonging to this pokemon
     *
     * @type        fast OR charge
     * @pokemonType all, normal, shadow, purified
     */
    array function getMoves(required string type, required string pokemonType) {
        if(isNull(getPokemonMove())) return [];

        return getPokemonMove().filter((move) => {
            if(
                (
                    (type == 'fast' && move.getMove().getTurns() > 0) ||
                    (type == 'charge' && move.getMove().getTurns() == 0)
                ) &&
                (
                    pokemonType == 'all' ||
                    (pokemonType == 'normal' && !move.getShadow()) ||
                    (pokemonType == 'shadow' && move.getShadow())
                )
            ) {
                return true;
            }
            return false;
        });
    }

    string function getType1Img(string type = 'icon') {
        // icon or symbol
        return '/includes/images/type#arguments.type#/#lCase(getType1())#.webp';
    }

    string function getType2Img(string type = 'icon') {
        // icon or symbol
        return '/includes/images/type#arguments.type#/#lCase(getType2())#.webp';
    }

}
