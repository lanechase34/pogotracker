<cfoutput>
<cfset totalPokemon = prc.pokedexIndex.reduce((sum, group) => sum + group.pokemon.len(), 0)>
<cfset totalShiny = prc.pokedexIndex.reduce((sum, group) => sum + group.pokemon.filter((mon) => mon.shiny).len(), 0)>

<!--- Banner - matches the home page hero --->
<div class="pokedex-hero mt-3">
    <h1 class="pokedex-hero-title mb-0">Pokémon GO Pokédex</h1>
    <p class="pokedex-hero-subtitle">
        Every Pokémon in Pokémon GO, grouped by generation. Pick a Pokémon to see its max CP,
        base stats, fast and charged moves, evolutions, shiny availability, and past events.
    </p>
    <ul class="pokedex-hero-stats list-unstyled mb-0">
        <li><strong>#numberFormat(totalPokemon, ",")#</strong> Pokémon</li>
        <li><strong>#prc.pokedexIndex.len()#</strong> Generations</li>
        <li><strong>#numberFormat(totalShiny, ",")#</strong> Shiny</li>
        <cfif prc.costumeIndex.len()>
            <li><strong>#numberFormat(prc.costumeIndex.len(), ",")#</strong> Costumes</li>
        </cfif>
    </ul>
</div>

<!--- Sticky toolbar: generation jump links (scrollspy highlighted), shiny toggle, client side filter --->
<div class="pokedex-toolbar mb-3" id="pokedexToolbar">
    <nav class="pokedex-jump-wrapper" aria-label="Jump to generation">
        <ul class="pokedex-jump list-unstyled mb-0" id="pokedexJump">
            <cfloop array="#prc.pokedexIndex#" item="group">
                <li>
                    <a
                        class="btn btn-sm btn-outline-dark"
                        href="##gen-#encodeForHTMLAttribute(group.generation)#"
                        title="Generation #encodeForHTMLAttribute(group.generation)#"
                    >
                        #encodeForHTML(group.region)#
                    </a>
                </li>
            </cfloop>
            <cfif prc.costumeIndex.len()>
                <li>
                    <a class="btn btn-sm btn-outline-dark" href="##costumes" title="Costume Pokémon">
                        Costumes
                    </a>
                </li>
            </cfif>
        </ul>
    </nav>
    <div class="pokedex-tools">
        <button
            type="button"
            class="btn btn-sm btn-outline-dark pokedex-shiny-toggle"
            id="pokedexShiny"
            aria-pressed="false"
            title="Show shiny sprites"
        >
            &##x2728; Shiny
        </button>
        <div class="pokedex-filter">
            <label for="pokedexFilter" class="visually-hidden">Filter Pokémon by name, number, type, or costume</label>
            <div class="input-group input-group-sm">
                <span class="input-group-text"><i class="bi bi-funnel" aria-hidden="true"></i></span>
                <input
                    type="search"
                    id="pokedexFilter"
                    class="form-control"
                    placeholder="Filter name, ##, type"
                    autocomplete="off"
                    spellcheck="false"
                >
            </div>
        </div>
    </div>
</div>

<p class="text-center text-muted my-5 d-none" id="pokedexNoResults" role="status">
    No Pokémon match that filter.
</p>

<!--- Generations then costumes share one section/tile loop - costumes link to their base pokemon's detail page costume card --->
<cfset sections = prc.pokedexIndex.map((group) => {
    return {
        id       : "gen-#group.generation#",
        title    : "#group.region# Pokémon",
        label    : "Generation #group.generation#",
        hrefHash : "",
        pokemon  : group.pokemon
    };
})>
<cfif prc.costumeIndex.len()>
    <cfset sections.append({
        id       : "costumes",
        title    : "Costume Pokémon",
        label    : "Event costumes",
        hrefHash : "##costumes",
        pokemon  : prc.costumeIndex
    })>
</cfif>

<cfloop array="#sections#" item="section">
    <section class="pokedex-section mb-4" id="#encodeForHTMLAttribute(section.id)#" aria-labelledby="#encodeForHTMLAttribute(section.id)#-title">
        <div class="card shadow-sm">
            <h2 class="card-header card-header-pokemon" id="#encodeForHTMLAttribute(section.id)#-title">
                #encodeForHTML(section.title)#
                <span class="pokedex-gen-label">#encodeForHTML(section.label)# &middot; <span class="pokedex-gen-count">#section.pokemon.len()#</span></span>
            </h2>
            <div class="card-body">
                <ul class="pokedex-grid list-unstyled mb-0">
                    <cfloop array="#section.pokemon#" item="mon">
                        <cfset costumeType = mon?.costumeType ?: "">
                        <cfset searchText = lCase("#costumeType# #mon.name# #mon.number# #mon.type1# #mon.type2##costumeType.len() ? " costume" : ""##mon.shiny ? " shiny" : ""#")>
                        <li data-search="#encodeForHTMLAttribute(searchText)#"<cfif mon.shiny> data-shiny</cfif>>
                            <a class="pokedex-entry" href="#encodeForHTMLAttribute("/pokemon/#mon.ses##section.hrefHash#")#">
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
                    </cfloop>
                </ul>
            </div>
        </div>
    </section>
</cfloop>
</cfoutput>
