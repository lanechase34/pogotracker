component
    extends  ="baseValidator"
    accessors="true"
    singleton
    hint="Validator for checking if an entity (db record) exists"
{

    property name="auth" inject="authenticationService@cbauth";

    /**
     * Init validator
     */
    public void function init() {
        super.init(name = "entityExists");

        // entity names whose table is named differently
        variables.TABLES = {requestlog: "request_log"};
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
     * Load a custom pokedex that the trainerid param's trainer created, or that is public
     * "customid": {
     *  entityExists: {
     *      entityName: 'custom',
     *      pk: true,
     *      ownerField: 'trainerid',
     *      publicColumn: 'public'
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
     * @entityName       The record type (table) to look in
     * @pk               If true, looks the record up by its id
     * @column           A unique column name to look the record up by
     * @belongsToUser    Check if the loaded entity belongs to the current user's session
     * @ownerField       Check if the loaded entity belongs to the trainer whose id is in this target field (instead of the session)
     * @publicColumn     Boolean column - records where it is true pass the belongsToUser/ownerField check
     */
    public boolean function validate(
        required any validationResult,
        required any target,
        required string field,
        any targetValue,
        any validationData,
        struct rules
    ) {
        var errorStruct = newErrorStruct(
            field          = arguments.field,
            targetValue    = arguments.targetValue,
            validationData = arguments.validationData
        );

        // If the field is not required
        // And no valid value was passed in (-1 for a numeric field, blank for a string field) - skip the check
        var blankValues = {numeric: [-1], string: [""]};
        if(
            isOptionalBlank(
                arguments.targetValue,
                arguments.rules,
                blankValues[arguments.rules?.type ?: ""] ?: []
            )
        ) {
            return true;
        }

        // Field must be present
        if(
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue) ||
            !arguments.targetValue.len() ||
            !arguments.validationData.keyExists("entityName") ||
            (
                !arguments.validationData.keyExists("pk") &&
                !arguments.validationData.keyExists("column")
            ) ||
            (
                arguments.validationData.keyExists("pk") &&
                !isWholeId(arguments.targetValue)
            )
        ) {
            return reject(
                validationResult,
                errorStruct,
                "Invalid entity exists call."
            );
        }

        var byPK         = arguments.validationData.keyExists("pk") && arguments.validationData.pk;
        var byOwnerField = arguments.validationData.keyExists("ownerField");
        var ownerCheck   = byOwnerField || (
            arguments.validationData.keyExists("belongsToUser") && arguments.validationData.belongsToUser
        );
        var publicColumn = arguments.validationData?.publicColumn ?: "";

        // Table and columns go into the sql directly - they come from the validation config, but only allow plain names
        var table  = variables.TABLES[arguments.validationData.entityName] ?: arguments.validationData.entityName;
        var column = byPK ? "id" : arguments.validationData.column;
        if(
            !isSQLName(table)
            || !isSQLName(column)
            || (publicColumn.len() && !isSQLName(publicColumn))
        ) {
            throw(
                type    = "entityExists.InvalidName",
                message = "Invalid entityExists table or column: #table#.#column# #publicColumn#"
            );
        }

        var check = queryExecute(
            "
            SELECT #ownerCheck ? "trainerid" : "id"# AS found
                #publicColumn.len() ? ", #publicColumn# AS ispublic" : ""#
            FROM #table#
            WHERE #column# = :targetValue
            LIMIT 1
            ",
            {targetValue: {value: arguments.targetValue, cfsqltype: byPK ? "integer" : "varchar"}}
        );

        // Entity does not exists
        if(!check.recordCount) {
            return reject(
                validationResult,
                errorStruct,
                "The #arguments.validationData.entityName# entity (#arguments.targetValue#) does not exist."
            );
        }

        // If this entity should belong to the logged in trainer, or the trainer in the owner field
        // Public records (publicColumn) belong to everyone
        var owner = "";
        if(byOwnerField) {
            owner = invoke(arguments.target, "get#arguments.validationData.ownerField#");
        }
        else if(auth.isLoggedIn()) {
            owner = auth.getUserId();
        }
        var isPublic = publicColumn.len() && isBoolean(check.ispublic) && check.ispublic;
        var isOwner  = !isNull(owner)
        && isSimpleValue(owner)
        && isNumeric(owner)
        && isNumeric(check.found)
        && check.found == owner;

        if(ownerCheck && !isPublic && !isOwner) {
            return reject(validationResult, errorStruct, "Invalid access.");
        }

        return true;
    }

    /**
     * Ids are postgres integers - only a whole number in integer range can match one
     *
     * @value the submitted id
     */
    private boolean function isWholeId(required string value) {
        return reFind("^-?[0-9]{1,10}$", arguments.value) && abs(arguments.value) <= 2147483647;
    }

}
