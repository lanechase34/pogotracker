component accessors="true" hint="Shared helpers for the custom validators" {

    property name="name";

    /**
     * Init validator
     *
     * @name The validator's name - the constraint key, and the error's validationType (custom messages are looked up by it)
     */
    public void function init(required string name) {
        this.name = arguments.name;
    }

    /**
     * Getter for validator's name
     */
    public string function getName() {
        return this.name;
    }

    /**
     * A blank error for this validator - reject fills in the message
     *
     * @field          The field on the target object being validated
     * @targetValue    The target value - a complex value is reported as blank
     * @validationData The validation data the validator was created with
     */
    private struct function newErrorStruct(
        required string field,
        any targetValue,
        any validationData
    ) {
        return {
            message       : "",
            field         : arguments.field,
            validationType: getName(),
            rejectedValue : (isSimpleValue(arguments.targetValue) ? arguments.targetValue : ""),
            validationData: arguments.validationData
        };
    }

    /**
     * Adds the error to the validation result and fails the validation
     *
     * @validationResult The result object of the validation
     * @errorStruct      The error from newErrorStruct
     * @message          The error message
     */
    private boolean function reject(
        required any validationResult,
        required struct errorStruct,
        required string message
    ) {
        arguments.errorStruct.message = arguments.message;
        arguments.validationResult.addError(
            arguments.validationResult.newError(argumentCollection = arguments.errorStruct)
        );
        return false;
    }

    /**
     * Whether an optional field was left blank, so its check is skipped
     *
     * @targetValue The target value
     * @rules       The field's constraint rules - a required field is never blank
     * @blankValues Values that count as blank - a string blank also counts whitespace only
     */
    private boolean function isOptionalBlank(
        any targetValue,
        struct rules      = {},
        array blankValues = [""]
    ) {
        if(
            (arguments.rules?.required ?: false) ||
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue)
        ) {
            return false;
        }
        var value = trim(arguments.targetValue);
        return arguments.blankValues.some((blank) => value == blank);
    }

    /**
     * A record id held in a field of the target, "" when the field is missing or not a whole number
     *
     * @target The target object being validated
     * @field  The field holding the id
     */
    private string function getTargetId(required any target, required string field) {
        var id = invoke(arguments.target, "get#arguments.field#");
        if(isNull(id) || !isSimpleValue(id) || !isValid("integer", id)) return "";
        return id;
    }

    /**
     * Whether the value is a plain table or column name, safe to put into SQL directly
     *
     * @name The table or column name
     */
    private boolean function isSQLName(required string name) {
        return reFindNoCase("^[a-z_][a-z0-9_]*$", arguments.name) > 0;
    }

}
