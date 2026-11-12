component persistent="true" extends="base" {

    // columns
    property name="cookie" ormtype="string" length="128";
    property name="agent"  ormtype="string" length="512";
    property name="lastused"    ormtype="timestamp";
    property name="lastrotated" ormtype="timestamp";
    property name="previouscookie" ormtype="string" length="128";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";

}
