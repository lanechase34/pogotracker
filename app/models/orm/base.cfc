component mappedSuperClass="true" accessors="true" {

    // primary key
    property name="id" fieldtype="id" generator="increment" setter="false";

    // base columns
    property name="created" ormtype="timestamp";
    property name="updated" ormtype="timestamp";

    // functions

    /**
     * Get the created date formatted as short (m/d/y)
     * Returns '---'' if does not exist
     */
    string function getFormattedCreated() {
        if(isNull(getCreated())) {
            return '---';
        }

        return dateFormat(getCreated(), 'short');
    }

    /**
     * Get the updated date formatted as short (m/d/y)
     * Returns '---'' if does not exist
     */
    string function getFormattedUpdated() {
        if(isNull(getUpdated())) {
            return '---';
        }

        return dateFormat(getUpdated(), 'short');
    }

    /**
     * Get the created date time formatted as short (m/d/y h:nn tt)
     */
    string function getTimestamp() {
        return dateTimeFormat(getCreated(), 'short');
    }

    /**
     * Get the epoch time of created
     */
    number function getEpochCreated() {
        return getCreated().getTime();
    }

    /**
     * Return timestamp in blog format (mmm d, yyyy)
     */
    string function getBlogFormat() {
        return dateFormat(getCreated(), 'mmm d, yyyy');
    }

}
