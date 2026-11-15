<cfoutput>
<!--- Previous / next pokemon in Pokedex order, shown above and below the page --->
<cfsavecontent variable="adjacentNav">
<cfloop list="previous,next" item="direction">
    <cfset adj = prc.detail.adjacent[direction]>
    <cfif adj.isEmpty()>
        <span class="pokemon-adjacent-placeholder" aria-hidden="true"></span>
    <cfelse>
        <a
            class="pokemon-adjacent pokemon-adjacent-#direction#"
            href="/pokemon/#encodeForHTMLAttribute(adj.ses)#"
            rel="#direction == "previous" ? "prev" : "next"#"
        >
            <cfif direction == "previous"><i class="bi bi-chevron-left" aria-hidden="true"></i></cfif>
            <img src="#encodeForHTMLAttribute(adj.sprite)#" alt="" width="40" height="40" loading="lazy" decoding="async">
            <span class="pokemon-adjacent-text">
                <span class="pokemon-adjacent-label">#direction == "previous" ? "Previous" : "Next"# &middot; ###adj.number#</span>
                <span class="pokemon-adjacent-name">#encodeForHTML(adj.name)#</span>
            </span>
            <cfif direction == "next"><i class="bi bi-chevron-right" aria-hidden="true"></i></cfif>
        </a>
    </cfif>
</cfloop>
</cfsavecontent>

<!--- Breadcrumb - mirrors the BreadcrumbList structured data --->
<div class="pokemon-topbar mt-3">
    <nav aria-label="Breadcrumb">
        <ol class="breadcrumb pokemon-breadcrumb mb-0">
            <li class="breadcrumb-item">
                <a href="/"><i class="bi bi-house-door-fill" aria-hidden="true"></i>Home</a>
            </li>
            <li class="breadcrumb-item">
                <a href="/pokemon"><i class="bi bi-grid-3x3-gap-fill" aria-hidden="true"></i>Pokédex</a>
            </li>
            <li class="breadcrumb-item active" aria-current="page">
                <span class="pokemon-breadcrumb-number">###prc.detail.number#</span><span>#prc.detail.fullname#</span>
            </li>
        </ol>
    </nav>
    <nav class="pokemon-adjacent-nav" aria-label="Previous and next Pokémon">#adjacentNav#</nav>
</div>

<!--- Hero --->
<div class="row mt-2">
    <div class="col-12 mb-4">
        <div class="card shadow-sm pokemon-hero">
            <div class="card-body py-4 px-4">
                <div class="row align-items-center gy-3">
                    <div class="col-12 col-sm-auto text-center">
                        #view(view = "/views/pokemon/fragment/spritePair", args = {
                            sprite   : prc.detail.pokemon.sprite,
                            shiny    : prc.detail.pokemon.shiny,
                            normalAlt: "#prc.detail.fullname# Sprite",
                            shinyAlt : "#prc.detail.fullname# Shiny Sprite"
                        })#
                    </div>
                    <div class="col-12 col-sm text-center text-sm-start">
                        <p class="pokemon-hero-number mb-0">No.&nbsp;#prc.detail.pokemon.number#</p>
                        <h1 class="pokemon-hero-name">#prc.detail.fullname#</h1>
                        <div class="pokemon-types justify-content-center justify-content-sm-start">
                            <img
                                class="typeIcon"
                                src="#prc.detail.pokemon.type1img#"
                                alt="#prc.detail.pokemon.type1# type"
                            >
                            <cfif prc.detail.pokemon.type2.len()>
                                <img
                                    class="typeIcon"
                                    src="#prc.detail.pokemon.type2img#"
                                    alt="#prc.detail.pokemon.type2# type"
                                >
                            </cfif>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!--- CP Values + Base Stats --->
<div class="row">
    <div class="col-12 col-md-6 mb-4">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-graph-up"></i> CP Values
            </h2>
            <ul class="list-group list-group-flush cp-list">
                <li class="list-group-item">
                    <span class="cp-label">
                        <i class="bi bi-search text-secondary"></i>
                        <span>Research <span class="cp-tier">Lvl 15</span></span>
                    </span>
                    <span class="cp-value">#prc.detail.cp.lvl15[2]#</span>
                </li>
                <li class="list-group-item">
                    <span class="cp-label">
                        <i class="bi bi-egg text-secondary"></i>
                        <span>Raid / Egg <span class="cp-tier">Lvl 20</span></span>
                    </span>
                    <span class="cp-value">#prc.detail.cp.lvl20[1]# &ndash; #prc.detail.cp.lvl20[2]#</span>
                </li>
                <li class="list-group-item">
                    <span class="cp-label">
                        <i class="bi bi-cloud-sun text-secondary"></i>
                        <span>Weather Boosted <span class="cp-tier">Lvl 25</span></span>
                    </span>
                    <span class="cp-value">#prc.detail.cp.lvl25[1]# &ndash; #prc.detail.cp.lvl25[2]#</span>
                </li>
                <li class="list-group-item">
                    <span class="cp-label">
                        <i class="bi bi-trophy text-secondary"></i>
                        <span>Max CP <span class="cp-tier">Lvl 50</span></span>
                    </span>
                    <span class="cp-value">#prc.detail.cp.lvl50[2]#</span>
                </li>
            </ul>
        </div>
    </div>
    <div class="col-12 col-md-6 mb-4">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-bar-chart-line"></i> Base Stats
            </h2>
            <div class="card-body">
                <div class="pt-1">
                    #view(
                        view="/views/pokemon/fragment/statRow",
                        nolayout=true,
                        args={stat: "Max CP", value: "#prc.detail.cp.lvl50[2]# CP", color: "bg-primary", percent: prc.detail.statPercentages.cp}
                    )#
                    #view(
                        view="/views/pokemon/fragment/statRow",
                        nolayout=true,
                        args={stat: "Attack", value: "#prc.detail.pokemon.attack# ATK", color: "bg-danger", percent: prc.detail.statPercentages.attack}
                    )#
                    #view(
                        view="/views/pokemon/fragment/statRow",
                        nolayout=true,
                        args={stat: "Defense", value: "#prc.detail.pokemon.defense# DEF", color: "bg-warning", percent: prc.detail.statPercentages.defense}
                    )#
                    #view(
                        view="/views/pokemon/fragment/statRow",
                        nolayout=true,
                        args={stat: "Stamina", value: "#prc.detail.pokemon.hp# HP", color: "bg-success", percent: prc.detail.statPercentages.hp}
                    )#
                </div>
            </div>
        </div>
    </div>
</div>

<!--- Evolutions + Moves --->
<div class="row">
    <div class="col-12 col-md-6 mb-4">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-arrow-right-circle"></i> Evolutions
            </h2>
            <div class="card-body card-body-table">
                <cfif prc.detail.evolutionChain.len()>
                <div class="tableDiv">
                <table class="table align-middle text-center mb-0">
                    <thead class="table-light">
                        <tr>
                            <th class="col-4 small fw-semibold text-muted text-uppercase">From</th>
                            <th class="col-4 small fw-semibold text-muted text-uppercase">Cost</th>
                            <th class="col-4 small fw-semibold text-muted text-uppercase">To</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop index="i" item="currEvolution" array="#prc.detail.evolutionChain#">
                            #view(view="/views/pokemon/fragment/evolutionRow", nolayout=true, args={evolution: currEvolution})#
                        </cfloop>
                    </tbody>
                </table>
                </div>
                <cfelse>
                    <div class="text-center text-muted py-3">
                        <i class="bi bi-x-circle fs-3 d-block mb-2 opacity-50"></i>
                        <span class="small">No Evolutions</span>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
    <div class="col-12 col-md-6 mb-4">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-lightning-charge"></i> Moves
            </h2>
            <div class="card-body card-body-table">
                <cfloop list="fast,charge" item="moveType">
                <cfset moves = prc.detail.moves[moveType]>
                <p class="moves-section-label text-muted">#moveType == "fast" ? "Fast" : "Charge"# Moves</p>
                <cfif moves.len()>
                <div class="tableDiv">
                <table class="table align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th class="small fw-semibold">Move</th>
                            <th class="small fw-semibold text-end">DMG / Energy</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop index="i" item="currMove" array="#moves#">
                            #view(view="/views/pokemon/fragment/moveRow", nolayout=true, args={move: currMove})#
                        </cfloop>
                    </tbody>
                </table>
                </div>
                <cfelse>
                    <p class="text-muted small text-center px-3 py-2 mb-0">No #moveType# moves</p>
                </cfif>
                </cfloop>
            </div>
        </div>
    </div>
</div>

<!--- Events + Catch Rate --->
<div class="row">
    <div class="col-12 col-md-6 mb-4">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-calendar-event"></i> Previous Events
            </h2>
            <div class="card-body card-body-table">
                <cfif prc.detail.events.len()>
                    <div class="tableDiv">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th class="small fw-semibold">Event</th>
                                    <th class="small fw-semibold text-nowrap">Dates</th>
                                </tr>
                            </thead>
                            <tbody id="eventRows">
                                #view(view='/views/pokemon/fragment/eventRows', args={
                                    events: prc.detail.events,
                                    ses   : prc.detail.pokemon.ses,
                                    offset: 5,
                                    limit : 5
                                })#
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="text-center text-muted py-3">
                        <i class="bi bi-calendar-x fs-3 d-block mb-2 opacity-50"></i>
                        <span class="small">Not featured in any events</span>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
    <div class="col-12 col-md-6 mb-4">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-bullseye"></i> Catch Rate
            </h2>
            <div class="card-body d-flex align-items-center justify-content-center">
                <div class="catch-hero">
                    <div class="catch-pct">
                        #reReplace(numberFormat(prc.detail.catchRate.lvl20, ",.00"), "\.00$", "")#<sup>%</sup>
                    </div>
                    <p class="catch-sub mb-0">Lvl 20 Raid &bull; No modifiers</p>
                </div>
            </div>
        </div>
    </div>
</div>

<!--- Costumes --->
<cfif prc.detail.costumes.len()>
<div class="row mb-4">
    <div class="col-12">
        <div class="card shadow-sm pokemon-costumes" id="costumes">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-star"></i> Costumes <span class="badge text-bg-dark">#prc.detail.costumes.len()#</span>
                <button
                    class="btn btn-sm p-0 border-0 ms-auto text-muted"
                    type="button"
                    data-bs-toggle="collapse"
                    data-bs-target="##costumesCollapse"
                    aria-expanded="true"
                    aria-controls="costumesCollapse"
                    aria-label="Toggle costumes"
                >
                    <i class="bi bi-chevron-up collapse-chevron"></i>
                </button>
            </h2>
            <div class="collapse show" id="costumesCollapse">
            <div class="card-body">
                <div class="d-flex flex-wrap gap-3 justify-content-center justify-content-sm-start">
                    <cfloop index="i" item="costume" array="#prc.detail.costumes#">
                    <div class="pokemon-entry costume-entry">
                        #view(view = "/views/pokemon/fragment/spritePair", args = {
                            sprite   : costume.sprite,
                            shiny    : costume.shiny,
                            normalAlt: "#costume.costumetype# Normal Sprite",
                            shinyAlt : "#costume.costumetype# Shiny Sprite",
                            iconClass: "costumeIcon",
                            size     : 110,
                            lazy     : true
                        })#
                        <p class="mt-2 mb-0 small fw-semibold text-center text-capitalize">#costume.costumetype#</p>
                    </div>
                    </cfloop>
                </div>
            </div>
            </div>
        </div>
    </div>
</div>
</cfif>

<!--- Availability + Admin --->
<div class="row mb-4">
    <div class="col-12 col-md-6 mb-4 mb-md-0">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-check2-circle"></i> Availability
            </h2>
            <cfset availability = [
                {label: "Normal",       value: prc.detail.pokemon.live,        yes: "Available", no: "Unavailable"},
                {label: "Shiny",        value: prc.detail.pokemon.shiny,       yes: "Available", no: "Unavailable"},
                {label: "Shadow",       value: prc.detail.pokemon.shadow,      yes: "Available", no: "Unavailable"},
                {label: "Shiny Shadow", value: prc.detail.pokemon.shadowshiny, yes: "Available", no: "Unavailable"},
                {label: "Tradable",     value: prc.detail.pokemon.tradable,    yes: "Yes",       no: "No"}
            ]>
            <ul class="list-group list-group-flush">
                <cfloop array="#availability#" item="avail">
                <li class="list-group-item avail-item">
                    <span class="avail-name">#avail.label#</span>
                    <cfif avail.value>
                        <span class="badge text-bg-success rounded-pill"><i class="bi bi-check-lg me-1" aria-hidden="true"></i>#avail.yes#</span>
                    <cfelse>
                        <span class="badge text-bg-secondary rounded-pill"><i class="bi bi-dash me-1" aria-hidden="true"></i>#avail.no#</span>
                    </cfif>
                </li>
                </cfloop>
            </ul>
        </div>
    </div>
    <cfif (prc?.oCurrentUser?.hasPermission("admin") ?: false)>
    <div class="col-12 col-md-6 mb-4 mb-md-0">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-tools"></i> Pokemon Detail
            </h2>
            <div class="card-body mx-1">
                <form action="/pokemon/updateDetail" name="pokemonDetailForm" method="post" id="pokemonDetailForm" class="needs-validation p-0 m-0" novalidate>
                    <input type="hidden" name="pokemonid" value="#prc.detail.pokemon.id#"/>
                    <div class="row d-flex">
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="liveSwitch" name="liveSwitch" <cfif prc.detail.pokemon.live>checked</cfif>>
                                <label class="form-check-label" for="liveSwitch">Live</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="shinySwitch" name="shinySwitch" <cfif prc.detail.pokemon.shiny>checked</cfif>>
                                <label class="form-check-label" for="shinySwitch">Shiny</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="shadowSwitch" name="shadowSwitch" <cfif prc.detail.pokemon.shadow>checked</cfif>>
                                <label class="form-check-label" for="shadowSwitch">Shadow</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="shinyShadowSwitch" name="shinyShadowSwitch" <cfif prc.detail.pokemon.shadowshiny>checked</cfif>>
                                <label class="form-check-label" for="shinyShadowSwitch">Shiny Shadow</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="tradableSwitch" name="tradableSwitch" <cfif prc.detail.pokemon.tradable>checked</cfif>>
                                <label class="form-check-label" for="tradableSwitch">Tradable</label>
                            </div>
                        </div>
                        <div class="col-12 mt-3">
                            <button type="submit" class="col-12 col-lg-4 mt-auto btn btn-sm btn-dark">
                                Update Detail
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
    </cfif>
</div>
<!--- Bottom previous / next --->
<nav class="pokemon-adjacent-nav pokemon-adjacent-nav-bottom mb-4" aria-label="Previous and next Pokémon (bottom)">#adjacentNav#</nav>
</cfoutput>