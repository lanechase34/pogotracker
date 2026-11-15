component singleton {

    // Words from the list this site allows and where the list is (profanity setting)
    property name="settings" inject="coldbox:setting:profanity";

    variables.javaPattern = createObject("java", "java.util.regex.Pattern");
    variables.normalizer  = createObject("java", "java.text.Normalizer");
    variables.nfkd        = createObject("java", "java.text.Normalizer$Form").NFKD;

    // Combining accents and invisible format characters (zero width spaces/joiners)
    variables.MARKS = variables.javaPattern.compile("[\p{M}\p{Cf}]");
    // One run of non whitespace - a word for getProfanityContext
    variables.WORD  = variables.javaPattern.compile("\S+");

    // Look-alike characters people swap in for letters
    variables.LEET = {
        "@": "a",
        "$": "s",
        "0": "o",
        "1": "i",
        "3": "e",
        "4": "a",
        "5": "s",
        "7": "t"
    };

    // Punctuation or symbols between the letters of a word (f.u.c.k, f-u-c-k)
    variables.SEPARATOR  = "[\p{P}\p{S}]*";
    // What a space in a multi word entry matches
    variables.WORD_GAP   = "[\s\p{P}\p{S}]+";
    // Whole word entries can't touch another letter or digit on either side
    variables.NOT_BEFORE = "(?<![\p{L}\p{N}])";
    variables.NOT_AFTER  = "(?![\p{L}\p{N}])";
    variables.ENDINGS    = "(?:s|es|ed|er|ers|ing)?";

    /**
     * Load the word list and compile it into one pattern
     * The list comes from the @2toad/profanity npm package - npm install writes it (includes/scripts/buildProfanityList.js)
     *
     * Entries match as whole words plus common endings (shit matches shits, not shiitake), so "class" never matches ass.
     * Entries already ending in s get no endings - the list has its own plurals, and asses + s would match "assess".
     * Every entry also matches stretched letters (fuuuck - see buildWordPattern), punctuation between letters (f.u.c.k)
     * and the text after normalizeText (accents, zero width characters and leetspeak removed)
     */
    public void function onDIComplete() {
        var listPath = variables.settings.listPath;
        if(!fileExists(listPath)) {
            throw(
                type    = "ProfanityListMissing",
                message = "#listPath# is missing - run npm install (or npm run buildProfanity) in app/includes"
            );
        }

        // Normalized the same way as the text, so the list's own leetspeak entries (5h1t) fold into the word they spell
        var allowed = variables.settings.allowedWords.reduce((set, word) => {
            set[normalizeText(trim(word))] = true;
            return set;
        }, {});

        // Keyed by word, so entries that normalize to the same word are compiled once
        var words = deserializeJSON(fileRead(listPath, "UTF-8")).words
            .map((word) => normalizeText(trim(word)))
            .filter((word) => word.len() && !allowed.keyExists(word))
            .reduce((set, word) => {
                set[word] = true;
                return set;
            }, {});

        // An empty alternation matches everything, which would block every comment
        if(words.isEmpty()) {
            throw(
                type    = "ProfanityListEmpty",
                message = "#listPath# has no words left after profanity.allowedWords - run npm install (or npm run buildProfanity) in app/includes"
            );
        }

        var entries = words
            .keyArray()
            .map((word) => {
                return variables.NOT_BEFORE & buildWordPattern(word) & (right(word, 1) == "s" ? "" : variables.ENDINGS) & variables.NOT_AFTER;
            });

        // CASE_INSENSITIVE (2) | UNICODE_CASE (64)
        variables.pattern = variables.javaPattern.compile("(?:" & entries.toList("|") & ")", 66);
    }

    /**
     * Whether the text has a banned word in it
     *
     * @text user entered text
     */
    public boolean function containsProfanity(required string text) {
        if(!len(arguments.text)) return false;
        return variables.pattern.matcher(normalizeText(arguments.text)).find();
    }

    /**
     * Just the words around each banned word, for the audit log - runs of the text joined by ... where words were left out
     * Built from the normalized text (normalizeText), since that is what the pattern matched
     * Empty when the text has no banned word
     *
     * @text        user entered text
     * @wordsAround words kept on each side of a banned word
     */
    public string function getProfanityContext(required string text, numeric wordsAround = 5) {
        var normalized = normalizeText(arguments.text);

        // Every word with where it starts and ends
        var words       = [];
        var wordMatcher = variables.WORD.matcher(normalized);
        while(wordMatcher.find()) {
            words.append({
                start: wordMatcher.start(),
                end  : wordMatcher.end(),
                text : wordMatcher.group()
            });
        }

        // The words each banned word touches, widened by wordsAround
        var keep    = {};
        var matcher = variables.pattern.matcher(normalized);
        while(matcher.find()) {
            for(var i = 1; i <= words.len(); i++) {
                if(words[i].end > matcher.start() && words[i].start < matcher.end()) {
                    for(var j = max(1, i - arguments.wordsAround); j <= min(words.len(), i + arguments.wordsAround); j++) {
                        keep[j] = true;
                    }
                }
            }
        }
        if(keep.isEmpty()) return "";

        var parts    = [];
        var lastKept = 0;
        for(var i = 1; i <= words.len(); i++) {
            if(!keep.keyExists(i)) continue;
            if(i > lastKept + 1) parts.append("...");
            parts.append(words[i].text);
            lastKept = i;
        }
        if(lastKept < words.len()) parts.append("...");
        return parts.toList(" ");
    }

    /**
     * The text as it is matched - accents and invisible characters removed, lowercased, look-alikes swapped for letters
     *
     * @text user entered text
     */
    private string function normalizeText(required string text) {
        var normalized = variables.normalizer.normalize(javacast("string", arguments.text), variables.nfkd);
        normalized     = lCase(variables.MARKS.matcher(normalized).replaceAll(""));
        for(var lookAlike in variables.LEET) {
            normalized = replace(
                normalized,
                lookAlike,
                variables.LEET[lookAlike],
                "all"
            );
        }
        return normalized;
    }

    /**
     * Regex for one list entry, with separators between its runs of letters
     * A single letter matches once, or stretched to three or more (fuuuck) - never exactly twice, since doubled
     * letters are how ordinary words are spelled (asses must not match "assess"). A doubled letter matches two or more
     *
     * @word list entry, already normalized (normalizeText) and trimmed
     */
    private string function buildWordPattern(required string word) {
        var parts = [];
        var i     = 1;
        while(i <= len(arguments.word)) {
            var letter = mid(arguments.word, i, 1);
            var run    = 1;
            while(i + run <= len(arguments.word) && mid(arguments.word, i + run, 1) == letter) {
                run++;
            }

            if(letter == " ") {
                parts.append(variables.WORD_GAP);
            }
            else {
                if(parts.len() && parts.last() != variables.WORD_GAP) {
                    parts.append(variables.SEPARATOR);
                }
                var quoted = variables.javaPattern.quote(letter);
                parts.append(run == 1 ? "#quoted#(?:#quoted#{2,})?" : "#quoted#{#run#,}");
            }
            i += run;
        }
        return parts.toList("");
    }

}
