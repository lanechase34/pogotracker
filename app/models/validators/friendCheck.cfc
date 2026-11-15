component extends="baseValidator" accessors="true" singleton hint="Validator for checking if two trainers are friends" {

    property name="auth"          inject="authenticationService@cbauth";
    property name="friendService" inject="services.friend";

    /**
     * Init validator
     */
    public void function init() {
        super.init(name = "friendCheck");
    }

    /**
     * Check that you are/aren't friends with another trainer
     * The target value is the other trainer's id - blank or -1 skips the check when the field isn't required
     * A trainer is never their own friend - the target being the trainer fails, unless allowSelf is set
     *
     * Ex:
     * Your own stats, or a friend's
     * "trainerid": {friendCheck: {accepted: true, allowSelf: true}}
     *
     * Sending a friend request - no friend row yet, accepted or pending
     * "friendid": {friendCheck: {accepted: false, isFriend: false, trainerField: "trainerid"}}
     *
     * @validationResult            The result object of the validation
     * @target                      The target object to validate on
     * @field                       The field on the target object to validate on
     * @targetValue                 The target value to validate
     * @validationData              The validation data the validator was created with
     * @validationData.accepted     T/F only count accepted friend requests (false counts pending ones too)
     * @validationData.isFriend     (optional, default true) false to require that they are NOT friends
     * @validationData.allowSelf    (optional, default false) the target being the trainer passes
     * @validationData.trainerField (optional) field on the target holding the trainer's id, defaults to the logged in trainer
     */
    public boolean function validate(
        required any validationResult,
        required any target,
        required string field,
        any targetValue,
        any validationData,
        struct rules = {}
    ) {
        var errorStruct = newErrorStruct(
            field          = arguments.field,
            targetValue    = arguments.targetValue,
            validationData = arguments.validationData
        );

        // If the field is not required
        // And no value was passed in (blank or -1) - skip the check
        if(isOptionalBlank(arguments.targetValue, arguments.rules, ["", -1])) {
            return true;
        }

        var isFriend  = arguments.validationData?.isFriend ?: true;
        var allowSelf = arguments.validationData?.allowSelf ?: false;

        // The trainer - from the target field, or the logged in trainer
        var trainerid = "";
        if(arguments.validationData.keyExists("trainerField")) {
            trainerid = getTargetId(arguments.target, arguments.validationData.trainerField);
        }
        else if(auth.isLoggedIn()) {
            trainerid = auth.getUserId();
        }

        // Both must be trainer ids - a non numeric value fails instead of slipping through
        var check = !isNull(arguments.targetValue)
        && isSimpleValue(arguments.targetValue)
        && isValid("integer", arguments.targetValue)
        && isValid("integer", trainerid);

        if(check) {
            if(val(arguments.targetValue) == val(trainerid)) {
                check = allowSelf;
            }
            else {
                check = isFriend == friendService.checkFriend(
                    trainerid = trainerid,
                    friendid  = arguments.targetValue,
                    accepted  = arguments.validationData.accepted
                );
            }
        }

        if(!check) {
            return reject(
                validationResult,
                errorStruct,
                isFriend ? "You are not valid friends with this trainer." : "You are already friends with this trainer."
            );
        }

        return true;
    }

}
