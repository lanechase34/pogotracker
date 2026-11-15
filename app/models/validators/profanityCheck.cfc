component extends="baseValidator" accessors="true" singleton hint="Validator for rejecting text with banned words" {

    property name="profanityService" inject="services.profanity";

    /**
     * Init validator
     */
    public void function init() {
        super.init(name = "profanityCheck");
    }

    /**
     * Fails when the target value has a word from the banned word list
     * A blank or non text value passes - pair with required when the field must be filled in
     *
     * Ex:
     * "comment": {profanityCheck: {}, profanityCheckMessage: "Please keep it friendly."}
     *
     * @validationResult The result object of the validation
     * @target           The target object to validate on
     * @field            The field on the target object to validate on
     * @targetValue      The target value to validate
     * @validationData   The validation data the validator was created with
     * @rules            The other validation rules
     */
    public boolean function validate(
        required any validationResult,
        required any target,
        required string field,
        any targetValue,
        any validationData,
        struct rules = {}
    ) {
        if(
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue) ||
            !profanityService.containsProfanity(arguments.targetValue)
        ) {
            return true;
        }

        return reject(
            validationResult = arguments.validationResult,
            errorStruct      = newErrorStruct(
                field          = arguments.field,
                targetValue    = arguments.targetValue,
                validationData = arguments.validationData
            ),
            message = "Please remove the inappropriate language and try again."
        );
    }

}
