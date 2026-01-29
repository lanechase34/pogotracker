component persistent="true" extends="base" {

    // columns
    property name="ip"      ormtype="string" length="45";
    property name="event"   ormtype="string" length="250";
    property name="message" ormtype="string" length="250";
    property name="stack"   ormtype="string" length="1000";

    // relations
    property name="trainer" fieldtype="many-to-one" fkcolumn="trainerid" cfc="trainer" lazy="true";

    // functions
    string function getUsername() {
        return getTrainer()?.getUsername() ?: '';
    }

}
