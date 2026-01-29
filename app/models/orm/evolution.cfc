component persistent="true" extends="base" {

    // columns
    property name="cost" ormtype="integer" default="0";
    property name="condition" ormtype="string" length="75";
    property name="special" ormtype="boolean" default="0"; // battle evolution, ie giga, mega, etc..

    // relations
    property name="pokemon"   fieldtype="many-to-one" cfc="pokemon" fkcolumn="pokemonid"   lazy="true";
    property name="evolution" fieldtype="many-to-one" cfc="pokemon" fkcolumn="evolutionid" lazy="true";

}
