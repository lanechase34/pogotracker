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

}
