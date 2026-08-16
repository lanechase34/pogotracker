<cfoutput>
<cfloop index="i" item="currEvent" array="#args.events#">
    <tr>
        <td>
            <cfif NOT currEvent.commday>
                <a href="/mycustompokedex/#currEvent.id#" target="_blank" class="link-dark fw-medium link-underline-opacity-0 link-underline-opacity-100-hover">
                    #currEvent.name#
                </a>
            <cfelse>
                #currEvent.name#
            </cfif>
            
            <cfloop index="j" item="costumetype" array="#currEvent.costumes#">
                <span class="ms-2 badge bg-secondary text-capitalize">#costumetype#</span>
            </cfloop>
        </td>
        <td class="text-muted small text-nowrap">
            <cfif dateDiff('d', currEvent.begins, currEvent.ends) LT 1>
                #currEvent.begins#
            <cfelse>
                #currEvent.begins# &mdash; #currEvent.ends#
            </cfif>
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
