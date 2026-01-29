<cfoutput>
<div class="mt-3">
<table id="medalData" class="table table-bordered table-hover">
    <thead>
        <tr>
            <th class="text-center">Icon</th>
            <th class="text-center">Name</th>
            <th class="text-center">Description</th>
            <th class="text-center">Bronze</th>
            <th class="text-center">Silver</th>
            <th class="text-center">Gold</th>
            <th class="text-center">Platinum</th>
        </tr>
    </thead>
    <tbody>
        <cfloop index="i" item="currMedal" array="#prc.data#">
            <tr>
                <td class="align-middle text-center"><img src="/includes/images/medals/#currMedal.getName()##getSetting('imageExtension')#" alt="#currMedal.getAltText()#" loading="lazy" class="medalIcon"/></td>
                <td>#currMedal.getName()#</td>
                <td>#currMedal.getDescription()#</td>
                <td>#currMedal.getBronze()#</td>
                <td>#currMedal.getSilver()#</td>
                <td>#currMedal.getGold()#</td>
                <td>#currMedal.getPlatinum()#</td>
            </tr>
        </cfloop>
    </tbody>
</table>
</div>
</cfoutput>