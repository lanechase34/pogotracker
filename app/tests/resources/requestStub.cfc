component {

    property name="utilService" inject="services.util";

    /**
     * Accept: application/json (fetch/ajax callers)
     */
    any function asJsonRequest(required any fn) {
        return stubbed("isJsonRequest", true, arguments.fn);
    }

    private any function stubbed(
        required string method,
        required any value,
        required any fn
    ) {
        var original = variables.utilService[arguments.method];
        var answer   = arguments.value;

        variables.utilService[arguments.method] = () => answer;
        try {
            return arguments.fn();
        }
        finally {
            variables.utilService[arguments.method] = original;
        }
    }

}
