component persistent="true" extends="base" {

    // columns
    property name="accepted" ormtype="boolean" default="0"; // 0 - pending , 1 - accepted request

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";
    property name="friend"  fieldtype="many-to-one" cfc="trainer" fkcolumn="friendid"  lazy="true";

}
