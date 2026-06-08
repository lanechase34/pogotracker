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

}
