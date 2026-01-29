component acecssors="true" singleton {

    property name="name";
    property name="friendService" inject="services.friend";

    function init() {
        this.name = 'friendCheck';
    }

    string function getName() {
        return this.name;
    }

    /**
     * Check that you are/aren't friends with another trainer
     *
     * Expects the entity name and either the PK or unique field to load entity by
     *
     * @validationResult        The result object of the validation
     * @target                  The target object to validate on
     * @field                   The field on the target object to validate on
     * @targetValue             The target value to validate
     * @validationData          The validation data the validator was created with
     * @validationData.accepted T/F if friend request accepted
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

        // If the field is not required
        // And no valid value was passed in - skip the check
        if(
            !isNull(arguments.targetValue) &&
            isSimpleValue(arguments.targetValue) &&
            !isNumeric(arguments.targetValue)
        ) {
            return true;
        }

        var check = friendService.checkFriend(
            trainerid = session.trainerid,
            friendid  = arguments.targetValue,
            accepted  = arguments.validationData.accepted
        );

        if(!check) {
            errorStruct.message = 'You are not valid friends with this trainer.';
            validationResult.addError(
                validationResult
                    .newError(argumentCollection = errorStruct)
                    .setErrorMetadata({friendCheck: arguments.validationData})
            );
            return false;
        }

        return true;
    }

}
