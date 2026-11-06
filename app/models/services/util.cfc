component singleton accessors="true" {

    property name="jsonDiffLog" inject="logbox:logger:jsonDiff";
    property name="rootPath"    inject="coldbox:setting:rootPath";

    /**
     * Capitalize the first letter of each word in a sentence string
     *
     * @sentence  the string
     * @delimiter optional delimiter for the sentence, defaults to space
     */
    function capitalizeWords(required string sentence, string delimiter = " ") {
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
    public string function removeDuplicates(required string list, string delimiter = ",") {
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
            if(toFormat[toFormat.len()] == ",") {
                toFormat = toFormat.left(toFormat.len() - 1);
            }

            return dateTimeFormat(toFormat);
        }
        catch(any e) {
            return now();
        }
    }

    /**
     * Attempt to parse a 'yyyy-mm-dd' string
     * Falls back to now() if fails
     *
     * @toParse string that may be 'yyyy-mm-dd' formatted
     */
    public date function parseDateString(required string toParse) {
        try {
            var parts = toParse.listToArray("-");
            return createDate(parts[1], parts[2], parts[3]);
        }
        catch(any e) {
            return now();
        }
    }

    /**
     * Determine if the request is accepting json by looking at the headers
     */
    public boolean function isJsonRequest() {
        if(!getHTTPRequestData().headers.keyExists("Accept")) return false;
        var accept = getHTTPRequestData().headers.accept.listToArray(",");
        return accept.some((type) => type.trim() == "application/json");
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
            "s",
            -1,
            dateAdd(
                "d",
                1,
                createDateTime(year(high), month(high), day(high), 0, 0, 0)
            )
        );
    }

    /**
     * Write a json asset file ordered and formatted with the project's prettier
     * Diffs against the current file first and logs what changed
     *
     * @path relative path from the app root, e.g. /includes/assets/costumes.json
     * @data struct of records keyed by record id
     * @name label for the diff log entry
     */
    public void function writeJsonFile(
        required string path,
        required struct data,
        required string name
    ) {
        var fullPath = "#getRootPath()##arguments.path#";
        var previous = fileExists(fullPath) ? deserializeJSON(fileRead(fullPath)) : {};

        writeJsonDiff(
            name    : arguments.name,
            previous: previous,
            current : arguments.data
        );

        fileWrite(
            fullPath,
            serializeJSON(orderJson(arguments.data)),
            "UTF-8"
        );

        runPrettier(fullPath);
    }

    /**
     * Format a file in place with the prettier install in /includes/node_modules
     * Returns false if node or prettier is unavailable or prettier fails
     *
     * @fullPath absolute path of the file to format
     */
    private boolean function runPrettier(required string fullPath) {
        var includesPath = "#getRootPath()#/includes";
        var prettierBin  = "#includesPath#/node_modules/prettier/bin/prettier.cjs";
        if(!fileExists(prettierBin)) return false;

        try {
            // Arguments are passed as an array so no shell parses them
            cfexecute(
                name      : "node",
                arguments : [
                    prettierBin,
                    "--config",
                    "#includesPath#/.prettierrc",
                    "--write",
                    arguments.fullPath
                ],
                timeout          : 60,
                variable         : "local.output",
                errorVariable    : "local.errorOutput",
                exitCodeVariable : "local.exitCode"
            );
            return (local.exitCode ?: 1) == 0;
        }
        catch(any e) {
            return false;
        }
    }

    /**
     * Recursively rebuild structs as ordered structs with sorted keys so written json has a stable order
     *
     * @data struct, array, or simple value
     */
    public any function orderJson(required any data) {
        if(isStruct(arguments.data)) {
            var source  = arguments.data;
            var ordered = structNew("ordered");
            sortJsonKeys(source.keyArray()).each((key) => {
                ordered[key] = orderJson(source[key]);
            });
            return ordered;
        }
        if(isArray(arguments.data)) {
            return arguments.data.map((item) => orderJson(item));
        }
        return arguments.data;
    }

    /**
     * Diff two json record structs (keyed by record id) and log the changes to the jsonDiff logger
     * Ignores ordering, nothing is logged when there are no changes
     *
     * @name     label for the log entry, e.g. costumes
     * @previous records currently on disk
     * @current  newly built records
     */
    public void function writeJsonDiff(
        required string name,
        required struct previous,
        required struct current
    ) {
        var lines       = [];
        var previousRec = arguments.previous;
        var currentRec  = arguments.current;

        sortedKeyUnion(previousRec, currentRec).each((key) => {
            if(!previousRec.keyExists(key)) {
                lines.append("+ #key#");
                return;
            }
            if(!currentRec.keyExists(key)) {
                lines.append("- #key#");
                return;
            }

            var before = previousRec[key];
            var after  = currentRec[key];
            if(!isStruct(before) || !isStruct(after)) {
                if(!jsonValueEquals(before, after)) {
                    lines.append("~ #key#: #jsonValueText(before)# -> #jsonValueText(after)#");
                }
                return;
            }

            // Field level changes for this record
            sortedKeyUnion(before, after).each((field) => {
                var hasBefore = before.keyExists(field);
                var hasAfter  = after.keyExists(field);
                if(hasBefore && hasAfter && jsonValueEquals(before[field], after[field])) return;

                var beforeText = hasBefore ? jsonValueText(before[field]) : "(none)";
                var afterText  = hasAfter ? jsonValueText(after[field]) : "(none)";
                lines.append("~ #key#.#field#: #beforeText# -> #afterText#");
            });
        });

        if(!lines.len()) return;

        lines.prepend("#arguments.name# changes (+ added, - removed, ~ changed)");
        jsonDiffLog.info(lines.toList(chr(10)));
    }

    /**
     * Sort json keys, keys with a numeric prefix (e.g. 25-Baseball-jersey) sort by that number first
     *
     * @keys array of keys
     */
    private array function sortJsonKeys(required array keys) {
        arguments.keys.sort((a, b) => {
            var numCompare = sgn(val(a) - val(b));
            return numCompare != 0 ? numCompare : compareNoCase(a, b);
        });
        return arguments.keys;
    }

    /**
     * Sorted union of the keys of two structs
     */
    private array function sortedKeyUnion(required struct a, required struct b) {
        var union = {};
        arguments.a.each((key) => {
            union[key] = true;
        });
        arguments.b.each((key) => {
            union[key] = true;
        });
        return sortJsonKeys(union.keyArray());
    }

    /**
     * Order-insensitive equality for json values, compares simple values as strings (25 == "25")
     */
    private boolean function jsonValueEquals(any a, any b) {
        if(isSimpleValue(arguments.a) && isSimpleValue(arguments.b)) {
            return compare(toString(arguments.a), toString(arguments.b)) == 0;
        }
        return compare(jsonValueText(arguments.a), jsonValueText(arguments.b)) == 0;
    }

    /**
     * Stable text representation of a json value for diffing
     */
    private string function jsonValueText(any value) {
        return isSimpleValue(arguments.value) ? """#arguments.value#""" : serializeJSON(orderJson(arguments.value));
    }

}
