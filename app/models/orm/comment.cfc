component persistent="true" extends="base" {

    // columns
    property name="comment" ormtype="string" length="1000";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";
    property name="blog"    fieldtype="many-to-one" cfc="blog"    fkcolumn="blogid"    lazy="true";

}
