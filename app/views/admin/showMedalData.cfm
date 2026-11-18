<cfoutput>
<div>
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
                <td class="align-middle text-center"><img src="/includes/images/medals/#currMedal.name##getSetting('imageExtension')#" alt="#currMedal.alttext#" loading="lazy" class="medalIcon"/></td>
                <td>#currMedal.name#</td>
                <td>#currMedal.description#</td>
                <td>#currMedal.bronze#</td>
                <td>#currMedal.silver#</td>
                <td>#currMedal.gold#</td>
                <td>#currMedal.platinum#</td>
            </tr>
        </cfloop>
    </tbody>
</table>
</div>
</cfoutput>