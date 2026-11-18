<cfoutput>
<select id="commentBlog" class="form-select form-select-sm w-auto d-inline-block ms-2" aria-label="Blog post">
    <option value="0"<cfif !prc.blogid> selected</cfif>>All posts</option>
    <cfloop array="#prc.blogs#" item="currBlog">
        <option value="#currBlog.id#"<cfif currBlog.id == prc.blogid> selected</cfif>>#encodeForHTML(currBlog.header)#</option>
    </cfloop>
</select>
<div>
<table id="commentsTable" class="table table-striped table-bordered">
    <thead>
        <tr>
            <th class="text-center">Posted</th>
            <th class="text-center">Post</th>
            <th class="text-center">Trainer</th>
            <th class="text-center">Comment</th>
            <th class="text-center"></th>
        </tr>
    </thead>
</table>
</div>
</cfoutput>
