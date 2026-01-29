<cfoutput>
<div class="modal fade" 
    id="customPokedexModal" 
    data-bs-backdrop="static" 
    data-bs-keyboard="false" 
    tabindex="-1" 
    aria-labelledby="customPokedexLabel" 
    aria-hidden="true"
>
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5" id="customPokedexLabel">#args.header#</h5>
                <button type="button" class="btn-close closeCustomForm" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form name="customPokedexForm" id="customPokedexForm" class="row needs-validation g-3" novalidate action="" method="post" autocomplete="off">
                    <cfif args.edit>
                        <input type="hidden" id="inputCustomid" name="customid" value="#EncodeForHTML(args.custom.getId())#">
                    </cfif>
                    <div class="col-12">
                        <label for="inputName" class="form-label">Name</label>
                        <input type="text" class="form-control" id="inputName" name="name" value="<cfif args.edit>#encodeForHTML(args.custom.getName())#</cfif>" minlength="5" maxlength="100" required>
                        <div class="invalid-feedback">
                            Please provide a valid name.
                        </div> 
                    </div>
                    <div class="col-12">
                        <label for="pokemon" class="form-label">Pokemon</label>
                        <select id="pokemonList" class="form-control" name="pokemon" autocomplete="off" multiple>
                            <cfloop index="i" item="currPokemon" array="#args.pokemon#">
                                <option value="#currPokemon.getId()#" <cfif args.edit AND args.customPokedex.keyExists(currPokemon.getId())>selected</cfif>>
                                    <cfif currPokemon.getGender().len()>#currPokemon.getGender()# </cfif>#currPokemon.getName()#
                                </option>
                            </cfloop>
                        </select>
                        <div class="invalid-feedback">
                            Please select Pokemon.
                        </div> 
                    </div>
                    <cfif session.securityLevel GTE 20>
                        <div class="col-12">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="inputPublic" name="public" <cfif args.edit AND args.custom.getPublic()>checked</cfif>>
                                <label class="form-check-label" for="inputPublic">Public</label>
                            </div>
                        </div>
                    </cfif> 
                </form>
            </div>
            <div class="modal-footer">
                <div class="btn-group" role="group">
                    <button type="button" class="closeCustomForm btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <cfif args.edit>
                        <button type="button" id="deleteCustomForm" class="btn btn-danger">
                            <i class="bi bi-trash me-1"></i>
                            Delete
                        </button>
                    </cfif>
                    <button type="submit" id="submitCustomForm" class="btn btn-primary">
                        <cfif args.edit>
                            <i class="bi bi-pencil-square me-1"></i>
                            Edit
                        <cfelse>
                            <i class="bi bi-plus-square me-1"></i>
                            Add
                        </cfif>
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
</cfoutput>