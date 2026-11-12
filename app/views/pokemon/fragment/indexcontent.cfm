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

<cfloop array="#prc.pokedexIndex#" item="group">
    <section class="pokedex-section mb-4" id="gen-#encodeForHTMLAttribute(group.generation)#" aria-labelledby="gen-#encodeForHTMLAttribute(group.generation)#-title">
        <div class="card shadow-sm">
            <h2 class="card-header card-header-pokemon" id="gen-#encodeForHTMLAttribute(group.generation)#-title">
                #encodeForHTML(group.region)# Pokémon
                <span class="pokedex-gen-label">Generation #encodeForHTML(group.generation)# &middot; <span class="pokedex-gen-count">#group.pokemon.len()#</span></span>
            </h2>
            <div class="card-body">
                <ul class="pokedex-grid list-unstyled mb-0">
                    <cfloop array="#group.pokemon#" item="mon">
                        #view(view = "/views/pokemon/fragment/indextile", args = {mon: mon, href: "/pokemon/#mon.ses#"})#
                    </cfloop>
                </ul>
            </div>
        </div>
    </section>
</cfloop>

<!--- Costumes link to their base pokemon's detail page costume card --->
<cfif prc.costumeIndex.len()>
    <section class="pokedex-section mb-4" id="costumes" aria-labelledby="costumes-title">
        <div class="card shadow-sm">
            <h2 class="card-header card-header-pokemon" id="costumes-title">
                Costume Pokémon
                <span class="pokedex-gen-label">Event costumes &middot; <span class="pokedex-gen-count">#prc.costumeIndex.len()#</span></span>
            </h2>
            <div class="card-body">
                <ul class="pokedex-grid list-unstyled mb-0">
                    <cfloop array="#prc.costumeIndex#" item="mon">
                        #view(view = "/views/pokemon/fragment/indextile", args = {mon: mon, href: "/pokemon/#mon.ses###costumes"})#
                    </cfloop>
                </ul>
            </div>
        </div>
    </section>
</cfif>
</cfoutput>
