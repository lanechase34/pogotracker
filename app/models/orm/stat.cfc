component persistent="true" extends="base" {

    // columns
    property name="caught" ormtype="integer" default="0";
    property name="spun"   ormtype="integer" default="0";
    property name="walked" ormtype="numeric" default="0" precision="10" scale="2";
    property name="xp" ormtype="bigint" default="0";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";

}
