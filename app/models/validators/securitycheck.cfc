component accessors="true" singleton hint="Validator for checking if a user has appropriate security level" {

    property name="name";

    /**
     * Init validator
     */
    function init() {
        this.name = 'securityCheck';
    }

    /**
     * Getter for validator's name
     */
    string function getName() {
        return this.name;
    }

    /**
     * Checks if the supplied user passes security check
     *
     * @validationResult The result object of the validation
     * @target           The target object to validate on
     * @field            The field on the target object to validate on
     * @targetValue      The target value to validate
     * @validationData   The validation data the validator was created with
     */
    boolean function validate(
        required any validationResult,
        required any target,
        required string field,
        any targetValue,
        any validationData
    ) {
        var errorStruct = {
            message       : '',
            field         : arguments.field,
            validationType: getName(),
            rejectedValue : (isSimpleValue(arguments.targetValue) ? arguments.targetValue : ''),
            validationData: arguments.validationData
        };

        // Field must be present
        if(
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue) ||
            !arguments.targetValue.len()
        ) {
            errorStruct.message = 'Invalid security check call.';
            validationResult.addError(
                validationResult
                    .newError(argumentCollection = errorStruct)
                    .setErrorMetadata({securityCheck: arguments.validationData})
            );
            return false;
        }

        // You are viewing your own session data
        if(arguments.targetValue == session.trainerid) {
            return true;
        }

        // You are admin or higher rights
        if(session.securityLevel >= 50) {
            return true;
        }

        // Failed check
        errorStruct.message = 'Failed security check';
        validationResult.addError(
            validationResult
                .newError(argumentCollection = errorStruct)
                .setErrorMetadata({securityCheck: arguments.validationData})
        );
        return false;
    }

}
