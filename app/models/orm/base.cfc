component mappedSuperClass="true" accessors="true" {

    // primary key
    property name="id" fieldtype="id" generator="increment" setter="false";

    // base columns
    property name="created" ormtype="timestamp";
    property name="updated" ormtype="timestamp";

    // functions
    string function getFormattedCreated() {
        if(isNull(getCreated())) {
            return '---';
        }

        return dateFormat(getCreated(), 'short');
    }

    string function getFormattedUpdated() {
        if(isNull(getUpdated())) {
            return '---';
        }

        return dateFormat(getUpdated(), 'short');
    }

    string function getTimestamp() {
        return dateTimeFormat(getCreated(), 'short');
    }

    number function getEpochCreated() {
        return getCreated().getTime();
    }

    string function getBlogFormat() {
        return dateFormat(getCreated(), 'mmm d, yyyy');
    }

}
