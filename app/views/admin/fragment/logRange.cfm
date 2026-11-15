<cfoutput>
<select id="logRange" class="form-select form-select-sm w-auto d-inline-block ms-2" aria-label="Time range">
    <cfloop collection="#prc.ranges#" item="rangeKey">
        <option value="#rangeKey#"<cfif rangeKey == prc.range> selected</cfif>>#prc.ranges[rangeKey].label#</option>
    </cfloop>
</select>
</cfoutput>
