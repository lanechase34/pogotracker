component accessors="true" extends="cbsecurity.models.auth.User" transientCache="false" {

    /**
     * Properties
     */
    property name="id"       type="numeric";
    property name="username" type="string";
    property name="email"    type="string";
    property name="icon"     type="string";

    // Security level and the permissions it grants - names from the permissions setting (user, trusted, admin, developer)
    // Unverified trainers have none until they verify their email
    property name="securityLevel" type="numeric";
    property name="verified"      type="boolean";
    property name="permissions"   type="array";

    property name="friendcode" type="string";
    property name="lastLogin";
    property name="settings" type="struct";

    // Bumped when the trainer's password changes - older sessions sign out
    property name="sessionVersion" type="numeric";

    property name="imageExtension" inject="coldbox:setting:imageExtension";

    /**
     * Constructor
     */
    public any function init() {
        super.init();
        variables.id             = -1;
        variables.username       = "";
        variables.email          = "";
        variables.icon           = "";
        variables.securityLevel  = 0;
        variables.verified       = false;
        variables.permissions    = [];
        variables.friendcode     = "";
        variables.lastLogin      = "";
        variables.settings       = {};
        variables.sessionVersion = 0;
        return this;
    }

    /**
     * Web path to the trainer's profile icon image
     */
    public string function getIconPath() {
        return "/includes/images/icons/#variables.icon##getImageExtension()#";
    }

    /**
     * Alt text for the trainer's profile icon image
     */
    public string function getIconAltText() {
        return "#ucFirst(variables.icon)# profile icon";
    }

    /**
     * Roles and permissions are the same thing here
     *
     * @role One, a list, or an array of roles
     */
    public boolean function hasRole(required any role) {
        return hasPermission(arguments.role);
    }

    /**
     * Verify if this is a valid user or not
     */
    public boolean function isLoaded() {
        return (!isNull(variables.id) && len(variables.id) && variables.id > 0);
    }

}
