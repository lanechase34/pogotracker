<cfoutput>
<div class="col-6 mt-3">
    <div class="d-flex card">
        <div class="card-header">
            CP Calculator
        </div>
        <div class="card-body mx-1">
            <form 
                action="/dev/cpCalculator" 
                name="cpCalculatorForm" 
                method="get" 
                id="cpCalculatorForm"
                class="needs-validation"
                novalidate
            >
                <select id="pokemonList" class="form-select" size="1" name="pokemonid">
                    <cfloop index="i" item="currPokemon" array="#prc.allPokemon#">
                        <option 
                            value="#currPokemon.getId()#"
                            <cfif prc.keyExists('pokemonDetail') AND currPokemon.getId() EQ prc.pokemonDetail.pokemon.getId()>selected</cfif>
                        >
                            <cfif currPokemon.getGender().len()>#currPokemon.getGender()# </cfif>#currPokemon.getName()#
                        </option>
                    </cfloop>
                </select>

                <button type="submit" class="mt-3 col-2 btn btn-primary">
                    Calculate
                </button>
            </form>
        </div>
    </div>
</div>
<cfif prc.keyExists('pokemonDetail')>
    <div class="col-6 mt-3">
        <table class="table table-bordered table-striped">
            <thead>
                <tr>
                    <th>Lvl15 (Research)</th>
                    <th>Lvl20 (Raid / Egg)</th>
                    <th>Lvl25 (Weather Boosted)</th>
                    <th>Lvl50 (Max CP)</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>#prc.pokemonDetail.cp.lvl15[2]#</td>
                    <td>#prc.pokemonDetail.cp.lvl20[1]# - #prc.pokemonDetail.cp.lvl20[2]#</td>
                    <td>#prc.pokemonDetail.cp.lvl25[1]# - #prc.pokemonDetail.cp.lvl25[2]#</td>
                    <td>#prc.pokemonDetail.cp.lvl50[2]#</td>
                </tr>
            </tbody>
        </table>
    </div>
</cfif>
</cfoutput>