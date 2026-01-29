component acecssors="true" singleton {

    property name="name";

    function init() {
        this.name = 'entityExists';
    }

    string function getName() {
        return this.name;
    }

    /**
     * Check if the entity exists
     *
     * Expects the entity name and either the PK or unique field to load entity by
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

        // If the field is not required
        // And no valid value was passed in - skip the check
        if(
            !isNull(arguments.targetValue) &&
            isSimpleValue(arguments.targetValue) &&
            !arguments.rules.required && (
                (
                    arguments.rules.type == 'numeric' &&
                    arguments.targetValue == -1
                ) ||
                (
                    arguments.rules.type == 'string' &&
                    arguments.targetValue == ''
                )
            )
        ) {
            return true;
        }

        // Field must be present
        if(
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue) ||
            !arguments.targetValue.len() ||
            !arguments.validationData.keyExists('entityName') ||
            (
                !arguments.validationData.keyExists('pk') &&
                !arguments.validationData.keyExists('column')
            ) ||
            (
                arguments.validationData.keyExists('pk') &&
                !isNumeric(arguments.targetValue)
            )
        ) {
            errorStruct.message = 'Invalid entity exists call.';
            validationResult.addError(
                validationResult
                    .newError(argumentCollection = errorStruct)
                    .setErrorMetadata({uniqueDatabaseField: arguments.validationData})
            );
            return false;
        }

        var check;

        // Attempt to load entity based on PK
        if(arguments.validationData.keyExists('pk') && arguments.validationData.pk) {
            check = entityLoadByPK(arguments.validationData.entityName, arguments.targetValue);
        }

        // Attempt to load entity based on column provided
        else {
            check = entityLoad(
                arguments.validationData.entityName,
                {'#arguments.validationData.column#': arguments.targetValue},
                true
            );
        }

        // Entity does not exists
        if(isNull(check)) {
            errorStruct.message = 'The #arguments.validationData.entityName# entity (#arguments.targetValue#) does not exist.';
            validationResult.addError(
                validationResult
                    .newError(argumentCollection = errorStruct)
                    .setErrorMetadata({uniqueDatabaseField: arguments.validationData})
            );
            return false;
        }

        check = isArray(check) ? check[1] : check;

        // If this entity should belong to the current session's trainer
        if(
            arguments.validationData.keyExists('belongsToUser')
            && arguments.validationData.belongsToUser
            && (check?.getTrainer()?.getId() ?: -1) != session.trainerid
        ) {
            errorStruct.message = 'Invalid access.';
            validationResult.addError(
                validationResult
                    .newError(argumentCollection = errorStruct)
                    .setErrorMetadata({recordExists: arguments.validationData})
            );
            return false;
        }

        return true;
    }

}
