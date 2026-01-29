<cfoutput>
<div class="row mt-3">
    <table class="table table-striped table-bordered">
        <thead>
            <tr>
                <th></th>
                <th>Pokemon</th>
                <th>Fast</th>
                <th>Charge 1</th>
                <th>Charge 2</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <th scope="row">##1</th>
                <td class="text-center">
                    <img class="pokemonIcon" src="/includes/images/sprites/#prc.team.getP1().getSprite()##getSetting('imageExtension')#" loading="lazy">
                </td>
                <td>#prc.team.getP1fast().getMoveText()#</td>
                <td>#prc.team.getP1charge1().getMoveText()#</td>
                <td>#prc.team.getP1charge2().getMoveText()#</td>
            </tr>
            <tr>
                <th scope="row">##2</th>
                <td class="text-center">
                    <img class="pokemonIcon" src="/includes/images/sprites/#prc.team.getP2().getSprite()##getSetting('imageExtension')#" loading="lazy">
                </td>
                <td>#prc.team.getP2fast().getMoveText()#</td>
                <td>#prc.team.getP2charge1().getMoveText()#</td>
                <td>#prc.team.getP2charge2().getMoveText()#</td>
            </tr>
            <tr>
                <th scope="row">##3</th>
                <td class="text-center">
                    <img class="pokemonIcon" src="/includes/images/sprites/#prc.team.getP3().getSprite()##getSetting('imageExtension')#" loading="lazy">
                </td>
                <td>#prc.team.getP3fast().getMoveText()#</td>
                <td>#prc.team.getP3charge1().getMoveText()#</td>
                <td>#prc.team.getP3charge2().getMoveText()#</td>
            </tr>
        </tbody>
    </table>
</div>
</cfoutput>