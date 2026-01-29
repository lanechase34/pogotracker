component persistent="true" extends="base" {

    // columns
    property name="caught"      ormtype="boolean" default="0";
    property name="shiny"       ormtype="boolean" default="0";
    property name="hundo"       ormtype="boolean" default="0";
    property name="trade"       ormtype="boolean" default="1";
    property name="shadow"      ormtype="boolean" default="0";
    property name="shadowshiny" ormtype="boolean" default="0";
    property name="seen"        ormtype="integer" default="0";
    property name="total"       ormtype="integer" default="0";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";
    property name="pokemon" fieldtype="many-to-one" cfc="pokemon" fkcolumn="pokemonid" lazy="true";

}
