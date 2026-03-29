component persistent="true" extends="base" {

    // columns
    property name="ip"      ormtype="string" length="45";
    property name="event"   ormtype="string" length="250";
    property name="message" ormtype="string" length="250";
    property name="stack" ormtype="string";

    // relations
    property name="trainer" fieldtype="many-to-one" fkcolumn="trainerid" cfc="trainer" lazy="true";

    // functions

    /**
     * Get the username of the trainer, if exists, that the bug belongs to
     */
    string function getUsername() {
        return getTrainer()?.getUsername() ?: '';
    }

}
