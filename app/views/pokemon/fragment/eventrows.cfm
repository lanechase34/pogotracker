<cfoutput>
<cfloop index="i" item="currEvent" array="#args.events#">
    <tr>
        <td>
            <a href="/mycustompokedex/#currEvent.id#" target="_blank" class="link-dark fw-medium link-underline-opacity-0 link-underline-opacity-100-hover">
                #currEvent.name#
            </a>
        </td>
        <td class="text-muted small text-nowrap">
            #currEvent.begins# &mdash; #currEvent.ends#
        </td>
    </tr>
</cfloop>
<cfif args.events.len() EQ args.limit>
<tr id="loadMoreEventsRow">
    <td colspan="2" class="text-center">
        <button
            class="btn btn-sm btn-outline-secondary"
            id="loadMoreEvents"
            data-ses="#args.ses#"
            data-offset="#args.offset#"
        >
            Load more
        </button>
    </td>
</tr>
</cfif>
</cfoutput>
