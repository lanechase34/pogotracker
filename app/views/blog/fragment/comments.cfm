<!--- args.comments one after another (getCommentPage, getComment), with a delete button on each when args.canDelete --->
<cfoutput>
<cfloop item="currComment" array="#args.comments#">
<div class="blogComment" id="comment#currComment.id#">
    <div class="d-flex align-items-start">
        #view(view="/views/blog/fragment/trainerinfo", args={author: currComment.author, date: dateTimeFormat(currComment.created, "mmm d, yyyy h:nn tt")})#
        <cfif args.canDelete>
            <button
                type="button"
                class="ms-auto btn btn-outline-danger btn-sm deleteComment"
                data-commentid="#currComment.id#"
                title="Delete comment and ban its author from commenting"
            >
                <i class="bi bi-trash"></i><span class="visually-hidden">Delete comment</span>
            </button>
        </cfif>
    </div>
    <div class="bg-light rounded p-3 mt-2">
        <p class="mb-0 small text-break blogCommentText">#encodeForHTML(currComment.comment)#</p>
    </div>
</div>
</cfloop>
</cfoutput>
