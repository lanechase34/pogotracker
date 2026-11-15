component extends="baseValidator" accessors="true" singleton hint="Validator for checking a file exists" {

    /**
     * Init validator
     */
    public void function init() {
        super.init(name = "fileExistsCheck");
    }

    /**
     * Checks if the file exists
     * Expects filename (targetValue), filePath, and optional extension
     *
     * @validationResult The result object of the validation
     * @target           The target object to validate on
     * @field            The field on the target object to validate on
     * @targetValue      The target value to validate
     * @validationData   The validation data the validator was created with
     */
    public boolean function validate(
        required any validationResult,
        required any target,
        required string field,
        any targetValue,
        any validationData
    ) {
        var errorStruct = newErrorStruct(
            field          = arguments.field,
            targetValue    = arguments.targetValue,
            validationData = arguments.validationData
        );

        // Field must be present
        if(
            isNull(arguments.targetValue) ||
            !isSimpleValue(arguments.targetValue) ||
            !arguments.targetValue.len() ||
            !arguments.validationData.keyExists("path")
        ) {
            return reject(
                validationResult,
                errorStruct,
                "Invalid file exists check call."
            );
        }

        // Make sure file exists, if extension provided, use that
        var check = fileExists("#validationData.path#/#arguments.targetValue##validationData.keyExists("extension") ? validationData.extension : ""#");

        if(!check) {
            return reject(
                validationResult,
                errorStruct,
                "The file #arguments.targetValue# does not exist."
            );
        }

        return true;
    }

}
