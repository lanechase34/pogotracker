<cfoutput>
<div class="row homeCards" id="homeCards">
    <!--- Blog List --->
    <section class="col-12 col-md-8 col-xl-6 mt-3 homeCard">
        <div id="blogList">
        </div>
    </section>

    <!--- Upcoming Events --->
    <aside class="col-12 col-md-4 col-xl-3 mt-3 homeCard" id="eventsDiv"></aside> 

    <!--- News Section --->
    <aside class="col-12 col-md-4 col-xl-3 mt-3 homeCard" id="newsDiv"></aside> 

    <!--- Leaderboard --->
    <aside class="col-12 col-md-8 col-xl-6 mt-3 homeCard" id="leaderboardDiv" data-epoch="#now().getTime()#"></aside>
</div>
</cfoutput>