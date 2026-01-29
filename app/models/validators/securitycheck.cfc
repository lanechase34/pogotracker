component accessors="true" singleton {

    property name="name";

    function init() {
        this.name = 'securityCheck';
    }

    string function getName() {
        return this.name;
    }

    /**
     * Checks if the supplied user passes security check
     *
     * @validationResultThe result object of the validation
     * @targetThe           target object to validate on
     * @fieldThe            field on the target object to validate on
     * @targetValueThe      target value to validate
     * @validationDataThe   validation data the validator was created with
     */
    boolean function validate(
        required any validationResult,
        required any target,
        required string field,
        any targetValue,
        any validationData,
        struct rules
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
