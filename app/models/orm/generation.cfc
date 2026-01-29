component persistent="true" extends="base" {

    // columns
    property name="generation" ormtype="numeric" precision="2" scale="1";
    property name="region" ormtype="string";

    // relations
    property name="pokemon" fieldtype="one-to-many" cfc="pokemon" lazy="true";

}
