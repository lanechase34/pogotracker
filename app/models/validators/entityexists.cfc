component acecssors="true" singleton hint="Validator for checking if an entity (db record) exists" {

    property name="name";

    /**
     * Init validator
     */
    function init() {
        this.name = 'entityExists';
    }

    /**
     * Getter for validator's name
     */
    string function getName() {
        return this.name;
    }

    /**
     * Validates that a referenced database entity actually exists. Optionally checks that the entity belongs to the currently authenticated trainer session.
     *
     * Ex:
     * Load stat entity by PK - using the statid param - and force ownership
     * "statid": {
     *  required: true,
     *  type: 'numeric',
     *  entityExists: {
     *      entityName: 'stat',
     *      pk: true,
     *      belongsToUser: true
     *  }
     * }
     *
     * @validationResult The result object of the validation
     * @target           The target object to validate on
     * @field            The field on the target object to validate on
     * @targetValue      The target value to validate
     * @validationData   The validation data the validator was created with
     * @rules            The other validation rules. Check if the key is numeric/string and required/optional 
     * @callingStruct    Params in the struct defined
     * @entityName       The ORM Entity name to load
     * @pk               If true, loads the entity using entityLoadByPk()
     * @column           A unique column name to load using entityLoad()
     * @belongsToUser    Check if the loaded entity belongs to the current user's session
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
