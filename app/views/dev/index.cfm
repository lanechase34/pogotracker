<cfoutput> 
    <div class="row">
        <div class="col-12 col-md-3 d-flex align-items-start mt-3">
            <div class="list-group w-100">
                <a href="/dev/cpCalculator" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">CP Calculator</div>
                </a>
                <a href="/dev/debugInfo" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Debug</div>
                </a>
                <a href="/dev/forceError" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Force Error</div>
                </a>
                <a href="/dev/ormReload" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">ORM Reload</div>
                </a>
                <a href="/tests/runner.cfm" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Run Testbox</div>
                </a>
                <a href="/dev/sendTestEmail" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Send Test Email</div>
                </a>
                <a href="/dev/testJsoup" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Test Jsoup</div>
                </a>
                <a href="/dev/testEventTask" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Test Leekduck Event Task</div>
                </a>
                <a href="/dev/viewEmail" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">View Sent Email</div>
                </a>
            </div>
        </div>
        <div class="col-12 col-md-3 d-flex align-items-start mt-3">
            <div class="list-group w-100">
                <a href="/dev/createBlog" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Create Blog</div>
                </a>
                <a href="/dev/createCPMultiplierJson" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Create CP Multiplier Json</div>
                </a>
                <a href="/dev/createRandomBlogs" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Create Random Blogs</div>
                </a>
                <a href="/dev/createRandomTeam" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Create Random Team</div>
                </a>
                <a href="/dev/createTestTrainer" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Create Test Trainers</div>
                </a>
                <a href="/dev/createUnownJson" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Create Unown Json</div>
                </a>
                <a href="/dev/registerRandomPokemon" class="list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">Register Random Pokemon</div>
                </a>
            </div>
        </div>
        <div class="col-12 col-md-6 d-flex mt-3">
            <div class="d-flex h-100 w-100 card">
                <div class="card-header">
                    Download Image
                </div>
                <div class="card-body mx-1">
                    <form action="/dev/downloadImage" method="post" class="needs-validation h-100 w-100 p-0 m-0" novalidate autocomplete="off">
                        <div class="row d-flex w-100">
                            <div class="col-12 mb-3">
                                <label for="imageUrl" class="form-label">Image URL</label>
                                <input type="url" class="form-control" id="imageUrl" name="imageUrl" placeholder="https://" required>
                                <div class="invalid-feedback">Please provide a valid URL.</div>
                            </div>
                            <div class="col-12">
                                <button type="submit" class="col-12 col-lg-4 btn btn-dark">
                                    Download
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</cfoutput>