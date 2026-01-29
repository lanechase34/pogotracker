component persistent="true" table="custom" extends="base" {

    // columns
    property name="name" ormtype="string" length="100";
    property name="link" ormtype="string" length="250";
    property name="public" ormtype="boolean" default="0";
    property name="begins" ormtype="timestamp";
    property name="ends"   ormtype="timestamp";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";
    property name="custompokedex" fieldtype="one-to-many" cfc="custompokedex" lazy="true";

    string function getFormattedBegins() {
        if(isNull(getBegins())) return dateFormat(getCreated(), 'mmm d, yyyy');
        return dateFormat(getBegins(), 'mmm d, yyyy');
    }

    string function getFormattedEnds() {
        if(isNull(getEnds())) return dateFormat(getCreated(), 'mmm d, yyyy');
        return dateFormat(getEnds(), 'mmm d, yyyy');
    }

}
