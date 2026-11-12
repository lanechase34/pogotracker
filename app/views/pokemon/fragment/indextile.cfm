<!---
    One Pokedex index grid tile
    @args.mon   plain index entry from pokemonService.getIndex / getCostumeIndex
    @args.href  link target
--->
<cfoutput>
<cfset mon = args.mon>
<cfset costumeType = mon?.costumeType ?: "">
<cfset searchText = lCase("#costumeType# #mon.name# #mon.number# #mon.type1# #mon.type2##costumeType.len() ? " costume" : ""##mon.shiny ? " shiny" : ""#")>
<li data-search="#encodeForHTMLAttribute(searchText)#"<cfif mon.shiny> data-shiny</cfif>>
    <a class="pokedex-entry" href="#encodeForHTMLAttribute(args.href)#">
        <img
            class="pokedex-entry-sprite"
            src="#encodeForHTMLAttribute(mon.sprite)#"
            data-normal-src="#encodeForHTMLAttribute(mon.sprite)#"
            <cfif mon.shiny>data-shiny-src="#encodeForHTMLAttribute(mon.shinySprite)#"</cfif>
            alt="#encodeForHTMLAttribute(trim("#costumeType# #mon.name#"))#"
            width="96"
            height="96"
            loading="lazy"
            decoding="async"
        >
        <span class="pokedex-entry-number">###mon.number#</span>
        <cfif costumeType.len()>
            <!--- Same as the costume pokedex: base name secondary, costume type is the primary label --->
            <span class="pokedex-entry-base-name">#encodeForHTML(mon.name)#</span>
            <span class="pokedex-entry-name text-capitalize">#encodeForHTML(costumeType)#</span>
        <cfelse>
            <span class="pokedex-entry-name">#encodeForHTML(mon.name)#</span>
        </cfif>
        <span class="visually-hidden">
            #encodeForHTML(mon.type1)#<cfif mon.type2.len()> / #encodeForHTML(mon.type2)#</cfif> type<cfif mon.shiny>, shiny available</cfif>
        </span>
    </a>
</li>
</cfoutput>
