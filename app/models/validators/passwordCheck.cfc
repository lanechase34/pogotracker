component extends="baseValidator" accessors="true" singleton hint="Validator for checking a trainer's current password" {

    property name="accountService" inject="services.account";
    property name="auth"           inject="authenticationService@cbauth";
    property name="trainerService" inject="services.trainer";

    /**
     * Init validator
     */
    public void function init() {
        super.init(name = "passwordCheck");
    }

    /**
     * Checks the target value is the trainer's current password when the logged in trainer changes their own password or email
     * Editing another trainer, or changing neither, needs no password
     *
     * Ex:
     * "currentPassword": {passwordCheck: {trainerField: "trainerid"}}
     *
     * @validationResult             The result object of the validation
     * @target                       The target object to validate on
     * @field                        The field on the target object to validate on
     * @targetValue                  The target value to validate
     * @validationData               The validation data the validator was created with
     * @validationData.trainerField  Field on the target holding the id of the trainer being changed
     * @validationData.passwordField (optional, default password) field on the target holding the new password - blank keeps the current one
     * @validationData.emailField    (optional, default email) field on the target holding the email
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
            targetValue    = "",
            validationData = arguments.validationData
        );

        // Only the logged in trainer changing their own account
        var trainerid = getTargetId(arguments.target, arguments.validationData.trainerField);
        if(!auth.isLoggedIn() || !len(trainerid) || trainerid != auth.getUserId()) {
            return true;
        }

        try {
            var trainer = trainerService.getFromId(trainerid);
        }
        catch(TrainerNotFound e) {
            return true;
        }

        // A new password, or a different email
        var password = invoke(arguments.target, "get#arguments.validationData?.passwordField ?: "password"#");
        var email    = invoke(arguments.target, "get#arguments.validationData?.emailField ?: "email"#");
        var changing = (!isNull(password) && isSimpleValue(password) && len(password))
        || (
            !isNull(email) && isSimpleValue(email) && trainerService.normalizeEmail(email) != trainerService.normalizeEmail(
                trainer.email ?: ""
            )
        );
        if(!changing) {
            return true;
        }

        if(
            !isNull(arguments.targetValue)
            && isSimpleValue(arguments.targetValue)
            && accountService.checkPassword(trainer.id, arguments.targetValue)
        ) {
            return true;
        }

        return reject(
            validationResult,
            errorStruct,
            "Current password is incorrect."
        );
    }

}
