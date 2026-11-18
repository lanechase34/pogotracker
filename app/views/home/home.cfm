<cfoutput>
<div class="row gy-3 homeCards" id="homeCards">
    <!--- Blog List --->
    <section class="col-12 col-md-8 col-xl-6 homeCard">
        <div class="home-hero">
            <h1 class="home-hero-title mb-0">Track Your Pokémon GO Journey</h1>
            <p class="home-hero-subtitle">Stats, events, and community — all in one place.</p>
        </div>
        <div class="home-section-label">
            <i class="bi bi-book-half fs-5"></i>Recent Blogs
        </div>
        <div id="blogList" class="d-flex flex-column gap-3" data-offset="#prc.blogCount#">
            <div>#view(view="/views/blog/list", args={blogs: prc.blogs, showimage: true, offset: 0, exclude: -1, sidebar: false})#</div>
        </div>
    </section>

    <!--- Upcoming Events --->
    <aside class="col-12 col-md-4 col-xl-3 homeCard" id="eventsDiv"></aside>

    <!--- News Section --->
    <aside class="col-12 col-md-4 col-xl-3 homeCard" id="newsDiv"></aside>

    <!--- Leaderboard --->
    <aside class="col-12 col-md-8 col-xl-6 homeCard" id="leaderboardDiv"></aside>
</div>
</cfoutput>