component persistent="true" extends="base" {

    // columns
    property name="header"  ormtype="string" length="100";
    property name="image"   ormtype="string" length="30";
    property name="alttext" ormtype="string" length="100";
    property name="bodyjson" ormtype="text";
    property name="body"     ormtype="text";
    property name="upvote"   ormtype="integer";
    property name="meta" ormtype="string" length="160";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";
    property name="comment" fieldtype="one-to-many" cfc="comment" lazy="true";

}
