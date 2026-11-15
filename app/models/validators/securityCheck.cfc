component
    extends  ="baseValidator"
    accessors="true"
    singleton
    hint="Validator for checking the target trainer is the logged in trainer, or the logged in trainer is an admin"
{

    property name="cbSecurity"     inject="CBSecurity@cbsecurity";
    property name="trainerService" inject="services.trainer";

    /**
     * Init validator
     */
    public void function init() {
        super.init(name = "securityCheck");

        // Level for a trainer that can't be loaded - above every real level
        variables.UNKNOWN_LEVEL = 2147483647;
    }

    /**
     * Checks if the supplied user passes security check
     * By default the target value is a trainer id - it must be the logged in trainer, or the logged in trainer is an admin
     * Error messages say who attempted what - a NotAuthorized built from them is recorded in the audit log, which holds 250 characters
     *
     * Ex:
     * Your own profile, or any profile if you're an admin - but never a trainer who outranks you
     * "trainerid": {securityCheck: {noHigherLevel: true}}
     *
     * A field only admins may set
     * "securityLevel": {securityCheck: {adminOnly: true}}
     *
     * @validationResult             The result object of the validation
     * @target                       The target object to validate on
     * @field                        The field on the target object to validate on
     * @targetValue                  The target value to validate
     * @validationData               The validation data the validator was created with
     * @validationData.adminOnly     (optional) the target value is any value only admins may set - blank passes
     * @validationData.noHigherLevel (optional) another trainer with a higher security level than the logged in trainer fails, even for admins
     */
    public boolean function validate(
        required any validationResult,
        required any target,
        required string field,
        any targetValue,
        any validationData
    ) {
        var errorStruct = newErrorStruct(
            field          = arguments.field,
            targetValue    = arguments.targetValue,
            validationData = arguments.validationData
        );

        // Admin only field - nothing set passes, anything set needs an admin
        if(arguments.validationData?.adminOnly ?: false) {
            if(
                isNull(arguments.targetValue)
                || (isSimpleValue(arguments.targetValue) && !len(trim(arguments.targetValue)))
                || (cbSecurity.isLoggedIn() && cbSecurity.has("admin"))
            ) {
                return true;
            }

            return reject(
                validationResult,
                errorStruct,
                "#describeActor()# is not an admin: set #arguments.field# to '#isSimpleValue(arguments.targetValue) ? left(arguments.targetValue, 30) : "[complex value]"#'"
            );
        }

        // Field must be present
        if(
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue) ||
            !arguments.targetValue.len()
        ) {
            return reject(
                validationResult,
                errorStruct,
                "Invalid security check call."
            );
        }

        // Your own data, or you are an admin
        if(
            !cbSecurity.isLoggedIn()
            || (
                arguments.targetValue != cbSecurity.getUser().getId()
                && !cbSecurity.has("admin")
            )
        ) {
            return reject(
                validationResult,
                errorStruct,
                "#describeActor()# is not an admin: acted on trainer #left(arguments.targetValue, 30)#"
            );
        }

        // No one acts on a trainer that outranks them
        if(
            (arguments.validationData?.noHigherLevel ?: false)
            && arguments.targetValue != cbSecurity.getUser().getId()
        ) {
            var targetLevel = getTargetLevel(arguments.targetValue);
            if(targetLevel <= val(cbSecurity.getUser().getSecurityLevel())) {
                return true;
            }

            return reject(
                validationResult,
                errorStruct,
                "#describeActor()# acted on trainer #left(arguments.targetValue, 30)#, who outranks them (#targetLevel == variables.UNKNOWN_LEVEL ? "unknown trainer" : "level #targetLevel#"#)"
            );
        }

        return true;
    }

    /**
     * The trainer's security level
     * A trainer that can't be loaded gets UNKNOWN_LEVEL, so it outranks everyone - entityExists reports the missing trainer
     *
     * @trainerid trainer id
     */
    private numeric function getTargetLevel(required any trainerid) {
        if(!isValid("integer", arguments.trainerid)) {
            return variables.UNKNOWN_LEVEL;
        }

        try {
            return val(trainerService.getFromId(arguments.trainerid).securitylevel);
        }
        catch(TrainerNotFound e) {
            return variables.UNKNOWN_LEVEL;
        }
    }

    /**
     * Who is making the request, for the error messages the audit log records
     * Ex: "Trainer 12 (level 10)" or "A guest"
     */
    private string function describeActor() {
        if(!cbSecurity.isLoggedIn()) {
            return "A guest";
        }
        var user = cbSecurity.getUser();
        return "Trainer #user.getId()# (level #user.getSecurityLevel()#)";
    }

}
