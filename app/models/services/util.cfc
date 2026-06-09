component singleton accessors="true" {

    /**
     * Capitalize the first letter of each word in a sentence string
     *
     * @sentence  the string
     * @delimiter optional delimiter for the sentence, defaults to space
     */
    function capitalizeWords(required string sentence, string delimiter = ' ') {
        return sentence
            .listToArray(delimiter)
            .map((word) => {
                return word.left(1).uCase() & word.mid(2, word.len() - 1).lCase();
            })
            .toList(delimiter);
    }

    /**
     * Remove duplicate entries in a delimited list
     *
     * @list      The list with potential duplicates
     * @delimiter The list delimiter
     */
    public string function removeDuplicates(required string list, string delimiter = ',') {
        return arrayToList(
            listToArray(arguments.list, arguments.delimiter)
                .map((item) => trim(item))
                .reduce((seen, item) => {
                    if(!seen.keyExists(item)) {
                        seen.result.append(item);
                        seen[item] = true;
                    }
                    return seen;
                }, {result: []})
                .result,
            arguments.delimiter
        );
    }

    /**
     * Attempt to format the incoming string to date object
     * Falls back to now() if fails
     *
     * @toFormat string that may contain a valid date
     */
    public date function formatStringToDate(required string toFormat) {
        try {
            // Remove trailing comma
            if(toFormat[toFormat.len()] == ',') {
                toFormat = toFormat.left(toFormat.len() - 1);
            }

            return dateTimeFormat(toFormat);
        }
        catch(any e) {
            return now();
        }
    }

    /**
     * Determine if the request is accepting json by looking at the headers
     */
    public boolean function isJsonRequest() {
        if(!getHTTPRequestData().headers.keyExists('Accept')) return false;
        var accept = getHTTPRequestData().headers.accept.listToArray(',');
        return accept.some((type) => type.trim() == 'application/json');
    }

    /**
     * Returns timestamp of date at 00:00:00
     *
     * @low date
     */
    public date function makeLowDate(required date low) {
        return createDateTime(year(low), month(low), day(low), 0, 0, 0);
    }

    /**
     * Returns timestamp of date at 23:59:59
     *
     * @high date
     */
    public date function makeHighDate(required date high) {
        return dateAdd(
            's',
            -1,
            dateAdd(
                'd',
                1,
                createDateTime(year(high), month(high), day(high), 0, 0, 0)
            )
        );
    }

}
