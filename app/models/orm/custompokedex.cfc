component persistent="true" table="custompokedex" extends="base" {

    // columns

    // relations
    property name="custom"  fieldtype="many-to-one" cfc="custom"  fkcolumn="customid"  lazy="true";
    property name="pokemon" fieldtype="many-to-one" cfc="pokemon" fkcolumn="pokemonid" lazy="true";

}
