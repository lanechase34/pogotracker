component accessors="true" singleton {

    property name="name";

    function init() {
        this.name = 'uniqueDatabaseField';
    }

    string function getName() {
        return this.name;
    }

    /**
     * Checks if the supplied value is unique to a database table and column
     *
     * Expects the table and column
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
            !arguments.targetValue.len() ||
            !arguments.validationData.keyExists('table') ||
            !arguments.validationData.keyExists('column')
        ) {
            errorStruct.message = 'Invalid unique database field call.';
            validationResult.addError(
                validationResult
                    .newError(argumentCollection = errorStruct)
                    .setErrorMetadata({uniqueDatabaseField: arguments.validationData})
            );
            return false;
        }

        // Run query to make sure value is unique in column in table
        var check = ormExecuteQuery(
            '
            select #validationData.column#
            from #validationData.table#
            where upper(#validationData.column#) = :targetValue
            ',
            {targetValue: uCase(arguments.targetValue)}
        );

        // Already taken
        if(check.len()) {
            errorStruct.message = 'The #validationData.column# field is not unique.';
            validationResult.addError(
                validationResult
                    .newError(argumentCollection = errorStruct)
                    .setErrorMetadata({uniqueDatabaseField: arguments.validationData})
            );
            return false;
        }

        return true;
    }

}
