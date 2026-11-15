component extends="base" {

    function run(qb, mockdata) {
        // Set up blog img - use the preview img
        var uploadPath = "#replace(
            expandPath("#getDirectoryFromPath(getCurrentTemplatePath())#../../includes/uploads"),
            "\",
            "/",
            "all"
        )#";

        if(!directoryExists(uploadPath)) {
            directoryCreate(uploadPath);
        }

        if(!directoryExists("#uploadPath#/cards")) {
            directoryCreate("#uploadPath#/cards");
        }

        if(!directoryExists("#uploadPath#/full")) {
            directoryCreate("#uploadPath#/full");
        }

        if(!directoryExists("#uploadPath#/extra")) {
            directoryCreate("#uploadPath#/extra");
        }

        var imgId = "#left(createUUID().replace("-", "", "all"), 25)#.webp";
        fileCopy("../../includes/images/preview.webp", "../../includes/uploads/cards/#imgId#");
        fileCopy("../../includes/images/preview.webp", "../../includes/uploads/full/#imgId#");

        var data = [];
        for(var i = 1; i <= 50; i++) {
            data.append({
                "trainerid": 1,
                "header"   : "Blog number #i#",
                "meta"     : createUUID().left(10),
                "image"    : imgId,
                "alttext"  : "#i#",
                "bodyjson" : "",
                "body"     : createUUID(),
                "created"  : dateAdd("d", -i, now())
            });
        }

        qb.table("blog").insert(data);

        // Enough comments on the newest blog to page through, and a few on the next one (a single page)
        seedComments(qb = qb, header = "Blog number 1", amount = 125);
        seedComments(qb = qb, header = "Blog number 2", amount = 4);
    }

    /**
     * Comments on a seeded blog from the seeded test_ trainers, oldest first, ten minutes apart after the blog was posted
     * Inserted in time order, so ids rise with created like real comments (comment paging orders by id)
     *
     * @qb     query builder
     * @header blog to comment on
     * @amount how many comments
     */
    private void function seedComments(
        required any qb,
        required string header,
        required numeric amount
    ) {
        var blog = queryExecute(
            "SELECT id, created FROM blog WHERE header = :header",
            {header: {value: arguments.header, cfsqltype: "varchar"}},
            {returnType: "array"}
        )[1];
        var trainers = queryExecute(
            "SELECT id FROM trainer WHERE username LIKE 'test\_%' AND securitylevel = 10 ORDER BY id ASC",
            {},
            {returnType: "array"}
        );

        // A mix of short, multi line, long and markup looking comments - markup must show as typed
        var samples = [
            "Great post, thanks for the update!",
            "Can't wait to try this out.",
            "First raid of the day went great.#chr(10)#Second one, not so much.#chr(10)##chr(10)#Still worth it!",
            "Does this work for shadow pokemon too?",
            "Use <Pikachu> & friends - a < b, and <b>this</b> should not be bold.",
            repeatString("This is a long comment to check wrapping. ", 20),
            "Thanks!",
            "Shiny hunting all weekend. Wish me luck"
        ];

        var data = [];
        for(var i = 1; i <= arguments.amount; i++) {
            data.append({
                "trainerid": trainers[(i - 1) % trainers.len() + 1].id,
                "blogid"   : blog.id,
                "comment"  : "###i# - #samples[(i - 1) % samples.len() + 1]#",
                "created"  : dateAdd("n", i * 10, blog.created)
            });
        }

        arguments.qb
            .newQuery()
            .table("comment")
            .insert(data);
    }

}
