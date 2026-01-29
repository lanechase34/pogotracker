component persistent="true" extends="base" {

    // columns
    property name="shadow" ormtype="boolean" default="0";
    property name="legacy" ormtype="boolean" default="0";

    // relations
    property name="pokemon" fieldtype="many-to-one" cfc="pokemon" fkcolumn="pokemonid" lazy="true";
    property name="move"    fieldtype="many-to-one" cfc="move"    fkcolumn="moveid"    lazy="true";

    // functions
    string function getMoveText() {
        return '#getMove().getName()##getShadow() ? '$' : ''##getLegacy() ? '*' : ''#';
    }

}
