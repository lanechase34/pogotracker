component persistent="true" extends="base" {

    // columns
    property name="cookie" ormtype="string" length="128";
    property name="agent"  ormtype="string" length="512";
    property name="lastused"    ormtype="timestamp";
    property name="lastrotated" ormtype="timestamp";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";

}
