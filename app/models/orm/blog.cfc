component persistent="true" extends="base" {

    // columns
    property name="header"  ormtype="string" length="100";
    property name="image"   ormtype="string" length="128";
    property name="alttext" ormtype="string" length="100";
    property name="bodyjson" ormtype="text";
    property name="body"     ormtype="text";
    property name="upvote"   ormtype="integer";
    property name="meta" ormtype="string" length="160";

    // relations
    property name="trainer" fieldtype="many-to-one" cfc="trainer" fkcolumn="trainerid" lazy="true";
    property name="comment" fieldtype="one-to-many" cfc="comment" lazy="true";

    string function getOgImage() {
        return '#application.cbController.getSetting('domain')#/includes/uploads/full/#getImage()#';
    }

    /**
     * Returns a plain-text excerpt of the blog body, stripped of all HTML.
     * Jsoup handles tag removal, entity decoding, and whitespace collapsing.
     *
     * @length Maximum number of characters to return)
     */
    string function getExcerpt(numeric length = 200) {
        var rawBody = getBody();
        if(isNull(rawBody) || !len(rawBody)) {
            return '';
        }

        var jsoup = application.cbController.getWireBox().getInstance('javaloader:org.jsoup.Jsoup');
        var text  = jsoup.parse(rawBody).text();
        return left(text, arguments.length);
    }

}
