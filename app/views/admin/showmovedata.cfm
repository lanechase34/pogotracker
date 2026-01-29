<cfoutput>
<div class="row mt-3">
    <div class="col">
        <ul class="nav nav-tabs">
            <li class="nav-item">
                <button class="nav-link moveLink active"  data-type="fast">
                    Fast Moves
                </button>
            </li>
            <li class="nav-item">
                <button class="nav-link moveLink" data-type="charge">
                    Charge Moves
                </button>
            </li>
        </ul>
    </div>
</div>

<div id="fastMoveWrapper">
<table id="fastMoveTable" class="table table-bordered table-hover">
    <thead>
        <tr>
            <th class="text-center">Name</th>
            <th class="text-center">Type</th>
            <th class="text-center">Damage</th>
            <th class="text-center">Energy</th>
            <th class="text-center">Turns</th>
            <th class="text-center">DPT</th>
            <th class="text-center">EPT</th>
        </tr>
    </thead>
    <tbody>
        <cfloop index="i" item="currMove" array="#prc.fastMoves#">
            <tr>
                <td>#currMove.getName()#</td>
                <td>#currMove.getType()#</td>
                <td>#currMove.getDamage()#</td>
                <td>#currMove.getEnergy()#</td>
                <td>#currMove.getTurns()#</td>
                <td>#currMove.getDamagePerTurn()#</td>
                <td>#currMove.getEnergyPerTurn()#</td>
            </tr>
        </cfloop>
    </tbody>
</table>
</div>

<div id="chargeMoveWrapper" class="d-none">
<table id="chargeMoveTable" class="table table-bordered table-hover">
    <thead>
        <tr>
            <th class="text-center">Name</th>
            <th class="text-center">Type</th>
            <th class="text-center">Damage</th>
            <th class="text-center">Energy</th>
            <th class="text-center">DPE</th>
            <th class="text-center">Effects</th>
        </tr>
    </thead>
    <tbody>
        <cfloop index="i" item="currMove" array="#prc.chargeMoves#">
            <tr>
                <td>#currMove.getName()#</td>
                <td>#currMove.getType()#</td>
                <td>#currMove.getDamage()#</td>
                <td>#currMove.getEnergy()#</td>
                <td>#currMove.getDamagePerEnergy()#</td>
                <td>#currMove.getBuff()#</td>
            </tr>
        </cfloop>
    </tbody>
</table>
</div>
</cfoutput>