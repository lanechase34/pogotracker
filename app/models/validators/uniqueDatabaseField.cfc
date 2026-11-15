component extends="baseValidator" accessors="true" singleton hint="Validator for checking a field is unique in database" {

    /**
     * Init validator
     */
    public void function init() {
        super.init(name = "uniqueDatabaseField");
    }

    /**
     * Checks if the supplied value is unique to a database table and column
     *
     * Expects the table and column
     *
     * Ex:
     * Username must be unique, ignoring the trainer being edited
     * "username": {
     *  required: true,
     *  uniqueDatabaseField: {table: "trainer", column: "username", excludeField: "trainerid"}
     * }
     *
     *                                  - it's compared without LOWER() so its plain unique index is used
     *
     * @validationResult               The result object of the validation
     * @target                         The target object to validate on
     * @field                          The field on the target object to validate on
     * @targetValue                    The target value to validate
     * @validationData                 The validation data the validator was created with
     * @rules                          The other validation rules. Check if the key is required/optional
     * @validationData.table           The table to look in
     * @validationData.column          The column that must be unique
     * @validationData.excludeField    (optional) Field on the target holding the id of the record being edited - that record is ignored
     * @validationData.storedLowercase (optional) true when the column only ever holds lowercase values (e.g. trainer.email, trainer.friendcode)
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
        // And no value was passed in - skip the check
        if(isOptionalBlank(arguments.targetValue, arguments.rules)) {
            return true;
        }

        // The record being edited, when there is one - it must be a record id
        var excludeId = "";
        if(arguments.validationData.keyExists("excludeField")) {
            excludeId = getTargetId(arguments.target, arguments.validationData.excludeField);
        }

        // Field must be present
        if(
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue) ||
            !arguments.targetValue.len() ||
            !arguments.validationData.keyExists("table") ||
            !arguments.validationData.keyExists("column") ||
            (arguments.validationData.keyExists("excludeField") && !len(excludeId))
        ) {
            return reject(
                validationResult,
                errorStruct,
                "Invalid unique database field call."
            );
        }

        // Run query to make sure value is unique in column in table, ignoring case and surrounding whitespace
        // The database constraint is the real guarantee - this only gives a friendlier error before the insert
        if(
            !isSQLName(arguments.validationData.table) ||
            !isSQLName(arguments.validationData.column)
        ) {
            throw(
                type    = "uniqueDatabaseField.InvalidName",
                message = "Invalid uniqueDatabaseField table or column: #arguments.validationData.table#.#arguments.validationData.column#"
            );
        }

        var params = {targetValue: {value: lCase(trim(arguments.targetValue)), cfsqltype: "varchar"}};
        if(len(excludeId)) {
            params.excludeId = {value: excludeId, cfsqltype: "integer"};
        }

        var columnSQL = (arguments.validationData.storedLowercase ?: false)
         ? arguments.validationData.column
         : "LOWER(#arguments.validationData.column#)";

        var check = queryExecute(
            "
            SELECT 1
            FROM #arguments.validationData.table#
            WHERE #columnSQL# = :targetValue
                #len(excludeId) ? "AND id <> :excludeId" : ""#
            LIMIT 1
            ",
            params
        );

        // Already taken
        if(check.recordCount) {
            return reject(
                validationResult,
                errorStruct,
                "The #validationData.column# field is not unique."
            );
        }

        return true;
    }

}
