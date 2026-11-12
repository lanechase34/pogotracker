component mappedSuperClass="true" accessors="true" {

    // primary key - the database assigns it from the table's SERIAL sequence, so any number of apps/servers can insert
    // entitySave() runs the INSERT immediately to read the new id back, instead of waiting for ormFlush()
    property name="id" fieldtype="id" generator="identity" setter="false";

    // base columns
    property name="created" ormtype="timestamp";
    property name="updated" ormtype="timestamp";

    // functions

    /**
     * Return timestamp in blog format (mmm d, yyyy)
     */
    string function getBlogFormat() {
        return dateFormat(getCreated(), "mmm d, yyyy");
    }

}
