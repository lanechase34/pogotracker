<cfoutput>
<div class="row pokemonCards">
    <!--- Main Card --->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm">
            <div class="card-header h5">
                <h2 class="h5 m-0 p-0">#prc.detail.pokemon.getNumber()# - #prc.detail.pokemon.getName()#</h2>
            </div>
            <div class="card-body d-flex flex-column justify-content-center align-items-center">
                <div>
                    <img class="pokemonIcon" src="/includes/images/sprites/#prc.detail.pokemon.getSprite()##getSetting('imageExtension')#">
                    <cfif prc.detail.pokemon.getShiny()>
                        <img class="pokemonIcon ms-sm-1 ms-md-2 ms-lg-5" src="/includes/images/shinysprites/#prc.detail.pokemon.getSprite()##getSetting('imageExtension')#">
                    </cfif>
                </div>
                <div>
                    <img class="typeIcon" src="#prc.detail.pokemon.getType1Img()#">
                    <cfif prc.detail.pokemon.getType2().len()>
                        <img class="typeIcon" src="#prc.detail.pokemon.getType2Img()#">
                    </cfif>
                </div>
            </div>
        </div>
    </div>
    <!--- CP Card --->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm">
            <div class="card-header h5">
                CP Values
            </div>
            <div class="card-body">
                <div class="tableDiv">
                <table class="table table-striped align-middle mb-0">
                    <tbody>
                        <tr class="py-1">
                            <th scope="row">Research (Lvl15)</th>
                            <td class="text-center text-primary fw-semibold fs-6">
                                <div class="my-1">
                                    #prc.detail.cp.lvl15[2]#
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <th scope="row">Raid / Egg (Lvl20)</th>
                            <td class="text-center text-primary fw-semibold fs-6">
                                <div class="my-1">
                                    #prc.detail.cp.lvl20[1]# - #prc.detail.cp.lvl20[2]#
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <th scope="row">Weather Boosted Raid (Lvl25)</th>
                            <td class="text-center text-primary fw-semibold fs-6">
                                <div class="my-1">
                                    #prc.detail.cp.lvl25[1]# - #prc.detail.cp.lvl25[2]#
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <th scope="row">Max CP (Lvl50)</th>
                            <td class="text-center text-primary fw-semibold fs-6">
                                <div class="my-1">
                                    #prc.detail.cp.lvl50[2]#
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
                </div>
            </div>
        </div>
    </div>
    <!--- Evolutions Card --->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm">
            <div class="card-header h5">
                Evolutions
            </div>
            <div class="card-body">
                <cfif prc.detail.baseStage.getEvolution().len()>
                <div class="tableDiv">
                <table class="table align-middle text-center mb-0">
                    <thead>
                        <tr>
                            <th scope="col" class="col-4">Pokemon</th>
                            <th scope="col" class="col-4">Requirement</th>
                            <th scope="col" class="col-4">Evolution</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!--- starting from base stage, get all evolutions --->
                        <cfloop index="i" item="firstStage" array="#prc.detail.baseStage.getEvolution()#">
                            #view(
                                view="/views/pokedex/fragment/evolutionrow",
                                nolayout=true,
                                args={evolution: firstStage}
                            )#
                            
                            <cfloop index="j" item="secondStage" array="#firstStage.getEvolution().getEvolution()#">
                                #view(
                                    view="/views/pokedex/fragment/evolutionrow",
                                    nolayout=true,
                                    args={evolution: secondStage}
                                )#

                                <cfloop index="k" item="thirdStage" array="#secondStage.getEvolution().getEvolution()#">
                                    #view(
                                        view="/views/pokedex/fragment/evolutionrow",
                                        nolayout=true,
                                        args={evolution: thirdStage}
                                    )#
                                </cfloop>
                            </cfloop>
                        </cfloop>
                    </tbody>
                </table>
                </div>
                <cfelse>
                    <div class="text-center">
                        No Evolutions
                    </div>
                </cfif>
            </div>
        </div>
    </div>
    <!--- Move Card --->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm">
            <div class="card-header h5">
                Moves
            </div>
            <div class="card-body">
                <div class="tableDiv">
                <table class="table align-middle mb-3">
                    <thead>
                        <tr>
                            <th scope="col" class="col-6">Fast Moves</th>
                            <th scope="col" class="col-6">Damage, Energy</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop index="i" item="currMove" array="#prc.detail.pokemon.getMoves("fast", "normal")#">
                            #view(
                                view="/views/pokedex/fragment/moverow",
                                nolayout=true,
                                args={move: currMove.getMove()}
                            )#
                        </cfloop>
                    </tbody>
                </table>
                </div>

                <div class="tableDiv">
                <table class="table align-middle mb-0">
                    <thead>
                        <tr>
                            <th scope="col" class="col-6">Charge Moves</th>
                            <th scope="col" class="col-6">Damage, Energy</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop index="i" item="currMove" array="#prc.detail.pokemon.getMoves("charge", "normal")#">
                            #view(
                                view="/views/pokedex/fragment/moverow",
                                nolayout=true,
                                args={move: currMove.getMove()}
                            )#
                        </cfloop>
                    </tbody>
                </table>
                </div>
            </div>
        </div>
    </div>
    <!--- Stats Card --->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm">
            <div class="card-header h5">
                Stats
            </div>
            <div class="card-body">
                <div class="tableDiv">
                <table class="table table-striped align-middle mb-0">
                    <tbody>
                        #view(
                            view="/views/pokedex/fragment/pokemonstatrow", 
                            nolayout=true, 
                            args={stat: "Max CP", value: "#prc.detail.cp.lvl50[2]# CP", color: "bg-success", percent: prc.detail.statPercentages.cp}
                        )#
                        #view(
                            view="/views/pokedex/fragment/pokemonstatrow", 
                            nolayout=true, 
                            args={stat: "Attack", value: "#prc.detail.pokemon.getAttack()# ATK", color: "", percent: prc.detail.statPercentages.attack}
                        )#
                        #view(
                            view="/views/pokedex/fragment/pokemonstatrow", 
                            nolayout=true, 
                            args={stat: "Defense", value: "#prc.detail.pokemon.getDefense()# DEF", color: "bg-warning", percent: prc.detail.statPercentages.defense}
                        )#
                        #view(
                            view="/views/pokedex/fragment/pokemonstatrow", 
                            nolayout=true, 
                            args={stat: "Stamina", value: "#prc.detail.pokemon.getHP()# HP", color: "bg-danger", percent: prc.detail.statPercentages.hp}
                        )#
                    </tbody>
                    
                </table>
                </div>
            </div>
        </div>
    </div>
    <!--- Events Card --->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm">
            <div class="card-header h5">
                Previous Events
            </div>
            <div class="card-body">
                <cfif prc.detail.events.len()>
                    <div class="tableDiv">
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th scope="col" class="col-6">Event</th>
                                    <th scope="col" class="col-6">Dates</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop index="i" item="currEvent" array="#prc.detail.events#">
                                    <tr>
                                        <td>
                                            <a href="/mycustompokedex/#currEvent.id#" target="_blank" class="link-dark link-offset-2">
                                                #currEvent.name#
                                            </a>
                                        </td>
                                        <td>
                                            #currEvent.begins# - #currEvent.ends#
                                        </td>
                                    </tr>
                                </cfloop>
                            </tbody> 
                        </table>
                    </div>
                <cfelse>
                    <p class="card-text fs-6">
                        Not featured in any events
                    </p>
                </cfif>
            </div>
        </div>
    </div>
    <!--- Catch card --->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm">
            <div class="card-header h5">
                Catch Rate
            </div>
            <div class="card-body">
                <p class="card-text fs-6">
                    Lvl20 raid no modifiers catch rate = #reReplace(numberFormat(prc.detail.catchRate.lvl20, ",.00"), "\.00$", "")#%
                </p>
            </div>
        </div>
    </div>
    <!-- Availability -->
    <div class="col-12 col-lg-6 mt-3 pokemonCard">
        <div class="card shadow-sm h-100">
            <div class="card-header h5">
                Availability
            </div>  
            
            <ul class="list-group list-group-flush availability-list">
                <li class="list-group-item d-flex align-items-center gap-3">
                    <span class="col-4 flex-grow-0">Normal</span>
                    <cfif prc.detail.pokemon.getLive()>
                        <i class="bi bi-check-circle-fill text-success fs-5"></i>
                    <cfelse>
                        <i class="bi bi-x-circle-fill text-muted fs-5"></i>
                    </cfif>
                </li>

                <li class="list-group-item d-flex align-items-center gap-3">
                    <span class="col-4 flex-grow-0">Shiny</span>
                    <cfif prc.detail.pokemon.getShiny()>
                        <i class="bi bi-check-circle-fill text-success fs-5"></i>
                    <cfelse>
                        <i class="bi bi-x-circle-fill text-muted fs-5"></i>
                    </cfif>
                </li>

                <li class="list-group-item d-flex align-items-center gap-3">
                    <span class="col-4 flex-grow-0">Shadow</span>
                    <cfif prc.detail.pokemon.getShadow()>
                        <i class="bi bi-check-circle-fill text-success fs-5"></i>
                    <cfelse>
                        <i class="bi bi-x-circle-fill text-muted fs-5"></i>
                    </cfif>
                </li>

                <li class="list-group-item d-flex align-items-center gap-3">
                    <span class="col-4 flex-grow-0">Shadow Shiny</span>
                    <cfif prc.detail.pokemon.getShadowShiny()>
                        <i class="bi bi-check-circle-fill text-success fs-5"></i>
                    <cfelse>
                        <i class="bi bi-x-circle-fill text-muted fs-5"></i>
                    </cfif>
                </li>

                <li class="list-group-item d-flex align-items-center gap-3">
                    <span class="col-4 flex-grow-0">Tradable</span>
                    <cfif prc.detail.pokemon.getTradable()>
                        <i class="bi bi-check-circle-fill text-success fs-5"></i>
                    <cfelse>
                        <i class="bi bi-x-circle-fill text-muted fs-5"></i>
                    </cfif>
                </li>
            </ul>
        </div>
    </div>
    <cfif (session?.securityLevel ?: -10) GTE 50>
        <!--- Admin panel --->
        <div class="col-12 col-lg-6 mt-3 pokemonCard">
            <div class="card shadow-sm">
                <div class="card-header h5">
                    Pokemon Detail
                </div>
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