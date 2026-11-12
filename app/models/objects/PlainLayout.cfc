component extends="coldbox.system.logging.Layout" {

    /**
     * Plain text LogBox layout: timestamp header followed by the raw message
     * Used for multi-line messages (e.g. json diffs) that the default csv layout would mangle
     */
    function format(required logEvent) {
        var timestamp = dateTimeFormat(arguments.logEvent.getTimestamp(), "yyyy-mm-dd HH:nn:ss");
        return "[#timestamp#] #arguments.logEvent.getCategory()##chr(10)##arguments.logEvent.getMessage()##chr(10)#";
    }

}
