<cfoutput>
<!--- Hero --->
<div class="row mt-3">
    <div class="col-12">
        <div class="card shadow-sm pokemon-hero">
            <div class="card-body py-4 px-4">
                <div class="row align-items-center gy-3">
                    <div class="col-12 col-sm-auto text-center">
                        <div class="pokemon-sprite-pair">
                            <div class="pokemon-sprite-group">
                                <img
                                    class="pokemonIcon"
                                    src="/includes/images/sprites/#prc.detail.pokemon.getSprite()##getSetting('imageExtension')#"
                                    alt="#prc.detail.pokemon.getName()# Sprite"
                                >
                                <span class="badge bg-dark text-white sprite-label">Normal</span>
                            </div>
                            <cfif prc.detail.pokemon.getShiny()>
                            <div class="pokemon-sprite-group">
                                <img
                                    class="pokemonIcon"
                                    src="/includes/images/shinysprites/#prc.detail.pokemon.getSprite()##getSetting('imageExtension')#"
                                    alt="#prc.detail.pokemon.getName()# Shiny Sprite"
                                >
                                <span class="badge bg-dark text-white sprite-label">&##x2728; Shiny</span>
                            </div>
                            </cfif>
                        </div>
                    </div>
                    <div class="col-12 col-sm text-center text-sm-start">
                        <p class="pokemon-hero-number mb-0">No.&nbsp;#prc.detail.pokemon.getNumber()#</p>
                        <h1 class="pokemon-hero-name">#prc.detail.pokemon.getName()#</h1>
                        <div class="pokemon-types justify-content-center justify-content-sm-start">
                            <img
                                class="typeIcon"
                                src="#prc.detail.pokemon.getType1Img()#"
                                alt="#prc.detail.pokemon.getType1()# type"
                            >
                            <cfif prc.detail.pokemon.getType2().len()>
                                <img
                                    class="typeIcon"
                                    src="#prc.detail.pokemon.getType2Img()#"
                                    alt="#prc.detail.pokemon.getType2()# type"
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
<div class="row g-3 mt-3">
    <div class="col-12 col-md-6">
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
    <div class="col-12 col-md-6">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-bar-chart-line"></i> Base Stats
            </h2>
            <div class="card-body">
                <div class="pt-1">
                    #view(
                        view="/views/pokemon/fragment/statrow",
                        nolayout=true,
                        args={stat: "Max CP", value: "#prc.detail.cp.lvl50[2]# CP", color: "bg-primary", percent: prc.detail.statPercentages.cp}
                    )#
                    #view(
                        view="/views/pokemon/fragment/statrow",
                        nolayout=true,
                        args={stat: "Attack", value: "#prc.detail.pokemon.getAttack()# ATK", color: "bg-danger", percent: prc.detail.statPercentages.attack}
                    )#
                    #view(
                        view="/views/pokemon/fragment/statrow",
                        nolayout=true,
                        args={stat: "Defense", value: "#prc.detail.pokemon.getDefense()# DEF", color: "bg-warning", percent: prc.detail.statPercentages.defense}
                    )#
                    #view(
                        view="/views/pokemon/fragment/statrow",
                        nolayout=true,
                        args={stat: "Stamina", value: "#prc.detail.pokemon.getHP()# HP", color: "bg-success", percent: prc.detail.statPercentages.hp}
                    )#
                </div>
            </div>
        </div>
    </div>
</div>

<!--- Evolutions + Moves --->
<div class="row g-3 mt-3">
    <div class="col-12 col-md-6">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-arrow-right-circle"></i> Evolutions
            </h2>
            <div class="card-body">
                <cfif prc.detail.baseStage.getEvolution().len()>
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
                        <cfloop index="i" item="firstStage" array="#prc.detail.baseStage.getEvolution()#">
                            #view(view="/views/pokemon/fragment/evolutionrow", nolayout=true, args={evolution: firstStage})#
                            <cfloop index="j" item="secondStage" array="#firstStage.getEvolution().getEvolution()#">
                                #view(view="/views/pokemon/fragment/evolutionrow", nolayout=true, args={evolution: secondStage})#
                                <cfloop index="k" item="thirdStage" array="#secondStage.getEvolution().getEvolution()#">
                                    #view(view="/views/pokemon/fragment/evolutionrow", nolayout=true, args={evolution: thirdStage})#
                                </cfloop>
                            </cfloop>
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
    <div class="col-12 col-md-6">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-lightning-charge"></i> Moves
            </h2>
            <div class="card-body pb-1">
                <p class="moves-section-label text-muted mb-2">Fast Moves</p>
                <div class="tableDiv mb-3">
                <table class="table align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th class="small fw-semibold">Move</th>
                            <th class="small fw-semibold text-end">DMG / Energy</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop index="i" item="currMove" array="#prc.detail.pokemon.getMoves("fast", "normal")#">
                            #view(view="/views/pokemon/fragment/moverow", nolayout=true, args={move: currMove.getMove()})#
                        </cfloop>
                    </tbody>
                </table>
                </div>
                <p class="moves-section-label text-muted mb-2">Charge Moves</p>
                <div class="tableDiv">
                <table class="table align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th class="small fw-semibold">Move</th>
                            <th class="small fw-semibold text-end">DMG / Energy</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop index="i" item="currMove" array="#prc.detail.pokemon.getMoves("charge", "normal")#">
                            #view(view="/views/pokemon/fragment/moverow", nolayout=true, args={move: currMove.getMove()})#
                        </cfloop>
                    </tbody>
                </table>
                </div>
            </div>
        </div>
    </div>
</div>

<!--- Events + Catch Rate --->
<div class="row g-3 mt-3">
    <div class="col-12 col-md-6">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-calendar-event"></i> Previous Events
            </h2>
            <div class="card-body">
                <cfif prc.detail.events.len()>
                    <div class="tableDiv">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th class="small fw-semibold">Event</th>
                                    <th class="small fw-semibold text-nowrap">Dates</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop index="i" item="currEvent" array="#prc.detail.events#">
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
    <div class="col-12 col-md-6">
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

<!--- Availability + Admin --->
<div class="row g-3 mt-3 mb-3">
    <div class="col-12 col-md-6">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-check2-circle"></i> Availability
            </h2>
            <ul class="list-group list-group-flush">
                <li class="list-group-item avail-item">
                    <span class="avail-name">Normal</span>
                    <cfif prc.detail.pokemon.getLive()>
                        <span class="badge text-bg-success rounded-pill"><i class="bi bi-check-lg me-1"></i>Available</span>
                    <cfelse>
                        <span class="badge text-bg-secondary rounded-pill"><i class="bi bi-dash me-1"></i>Unavailable</span>
                    </cfif>
                </li>
                <li class="list-group-item avail-item">
                    <span class="avail-name">Shiny</span>
                    <cfif prc.detail.pokemon.getShiny()>
                        <span class="badge text-bg-success rounded-pill"><i class="bi bi-check-lg me-1"></i>Available</span>
                    <cfelse>
                        <span class="badge text-bg-secondary rounded-pill"><i class="bi bi-dash me-1"></i>Unavailable</span>
                    </cfif>
                </li>
                <li class="list-group-item avail-item">
                    <span class="avail-name">Shadow</span>
                    <cfif prc.detail.pokemon.getShadow()>
                        <span class="badge text-bg-success rounded-pill"><i class="bi bi-check-lg me-1"></i>Available</span>
                    <cfelse>
                        <span class="badge text-bg-secondary rounded-pill"><i class="bi bi-dash me-1"></i>Unavailable</span>
                    </cfif>
                </li>
                <li class="list-group-item avail-item">
                    <span class="avail-name">Shadow Shiny</span>
                    <cfif prc.detail.pokemon.getShadowShiny()>
                        <span class="badge text-bg-success rounded-pill"><i class="bi bi-check-lg me-1"></i>Available</span>
                    <cfelse>
                        <span class="badge text-bg-secondary rounded-pill"><i class="bi bi-dash me-1"></i>Unavailable</span>
                    </cfif>
                </li>
                <li class="list-group-item avail-item">
                    <span class="avail-name">Tradable</span>
                    <cfif prc.detail.pokemon.getTradable()>
                        <span class="badge text-bg-success rounded-pill"><i class="bi bi-check-lg me-1"></i>Yes</span>
                    <cfelse>
                        <span class="badge text-bg-secondary rounded-pill"><i class="bi bi-dash me-1"></i>No</span>
                    </cfif>
                </li>
            </ul>
        </div>
    </div>
    <cfif (session?.securityLevel ?: -10) GTE 50>
    <div class="col-12 col-md-6">
        <div class="card shadow-sm h-100">
            <h2 class="card-header card-header-pokemon">
                <i class="bi bi-tools"></i> Pokemon Detail
            </h2>
            <div class="card-body mx-1">
                <form action="/pokemon/updateDetail" name="pokemonDetailForm" method="post" id="pokemonDetailForm" class="needs-validation p-0 m-0" novalidate>
                    <input type="hidden" name="pokemonid" value="#prc.detail.pokemon.getId()#"/>
                    <div class="row d-flex">
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="liveSwitch" name="liveSwitch" <cfif prc.detail.pokemon.getLive()>checked</cfif>>
                                <label class="form-check-label" for="liveSwitch">Live</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="shinySwitch" name="shinySwitch" <cfif prc.detail.pokemon.getShiny()>checked</cfif>>
                                <label class="form-check-label" for="shinySwitch">Shiny</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="shadowSwitch" name="shadowSwitch" <cfif prc.detail.pokemon.getShadow()>checked</cfif>>
                                <label class="form-check-label" for="shadowSwitch">Shadow</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="shinyShadowSwitch" name="shinyShadowSwitch" <cfif prc.detail.pokemon.getShadowShiny()>checked</cfif>>
                                <label class="form-check-label" for="shinyShadowSwitch">Shiny Shadow</label>
                            </div>
                        </div>
                        <div class="col-12 mb-1">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" role="switch" id="tradableSwitch" name="tradableSwitch" <cfif prc.detail.pokemon.getTradable()>checked</cfif>>
                                <label class="form-check-label" for="tradableSwitch">Tradable</label>
                            </div>
                        </div>
                        <div class="col-12 mt-3">
                            <button type="submit" class="col-12 col-lg-4 mt-auto btn btn-sm btn-primary">
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
</cfoutput>