component singleton accessors="true" {

    property name="accountService" inject="services.account";
    property name="environment"    inject="coldbox:setting:environment";
    property name="impersonation"  inject="coldbox:setting:impersonation";
    property name="populator"      inject="wirebox:populator";
    property name="trainerService" inject="services.trainer";

    /**
     * Construct a new user object via WireBox Providers
     */
    private userObj function new() provider="objects.userObj" {
    }

    /**
     * Check a trainer's email and password - cbauth calls this on login
     * Any password is accepted for an existing trainer when impersonation is allowed
     *
     * @username trainer's email
     * @password user entered password
     */
    public boolean function isValidCredentials(required string username, required string password) {
        return accountService.checkLogin(
            arguments.username,
            arguments.password,
            allowImpersonation()
        );
    }

    /**
     * Load the trainer for a successful login
     *
     * @username trainer's email
     */
    public any function retrieveUserByUsername(required string username) {
        var trainer = trainerService.findByEmail(arguments.username);
        if(isNull(trainer)) {
            throw(type = "TrainerNotFound", message = "No trainer with that email");
        }
        return buildUser(trainer);
    }

    /**
     * Load the logged in trainer - cbauth calls this once per request
     * Throws TrainerNotFound when the trainer no longer exists
     *
     * @id trainer pk
     */
    public any function retrieveUserById(required any id) {
        return buildUser(trainerService.getFromId(arguments.id));
    }

    /**
     * The auth user (objects.userObj) for a trainer
     * Null columns are skipped so the user keeps its defaults
     *
     * @trainer trainer struct (trainerService.getFromId)
     */
    public userObj function buildUser(required struct trainer) {
        var columns = arguments.trainer.filter((key, value) => !isNull(arguments.value));
        var user    = populator.populateFromStruct(new (), columns);
        user.setPermissions(trainerService.getPermissionNames(arguments.trainer));
        return user;
    }

    /**
     * Any password is accepted for an existing trainer when impersonation is on
     * Lets the test suite and local dev log in as anyone - never allowed in production
     */
    private boolean function allowImpersonation() {
        return getImpersonation() && getEnvironment() != "production";
    }

}
