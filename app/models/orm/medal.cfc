component persistent="true" extends="base" {

    // columns
    property name="name"        ormtype="string" length="50";
    property name="description" ormtype="string" length="100";
    property name="bronze"       ormtype="integer";
    property name="silver"       ormtype="integer";
    property name="gold"         ormtype="integer";
    property name="platinum"     ormtype="integer";
    property name="displayorder" ormtype="integer";

    // relations
    property name="trainermedal" fieldtype="one-to-many" cfc="trainermedal" lazy="true";

    string function getAltText() {
        return '#ucFirst(getName())# medal icon';
    }

}
