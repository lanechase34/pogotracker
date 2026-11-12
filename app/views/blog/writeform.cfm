<cfoutput>
<form name="writeblogform" data-submit="#encodeForHTML(args.submit)#" id="writeblogform" class="g-3" novalidate action="" method="post" autocomplete="off">
    <input type="hidden" name="csrf" value="#csrfToken()#">
    <div class="col-sm-12 col-lg-10 col-xl-8">
        <div id="blogAlert"></div>
        <div class="row mt-3">
            <label for="blogheader" class="col-sm-3 col-xl-1 col-form-label">Header</label>
            <div class="col-sm-9 col-xl-11">
                <input type="text" class="form-control" id="blogheader" name="blogheader" value="<cfif args.editing>#args.blog.getHeader()#</cfif>" required>
            </div>
        </div>
        <div class="row mt-3">
            <label for="blogmeta" class="col-sm-3 col-xl-1 col-form-label">Meta</label>
            <div class="col-sm-9 col-xl-11">
                <input type="text" class="form-control" id="blogmeta" name="blogmeta" value="<cfif args.editing>#args.blog.getMeta()#</cfif>" min="1" max="150" required>
            </div>
        </div>
        <div class="row mt-3">
            <label for="blogimage" class="col-sm-3 col-xl-1 col-form-label">Image</label>
            <div class="col-sm-9 col-xl-11">
                <input class="form-control" type="file" id="blogimage" name="blogimage" accept="image/png,image/jpeg,image/webp,image/heic">
            </div>
        </div>
        <div class="row mt-3">
            <label for="blogimagealt" class="col-sm-3 col-xl-1 col-form-label">Image Alt</label>
            <div class="col-sm-9 col-xl-11">
                <input type="text" class="form-control" id="blogimagealt" name="blogimagealt" value="<cfif args.editing>#args.blog.getAltText()#</cfif>" min="1" max="100" required>
            </div>
        </div>
        <div class="row mt-3">
            <span class="col-sm-3 col-xl-1 col-form-label">Body</span>
            <div class="col-sm-9 col-xl-11">
                <div id="blogDiv" class="card">
                </div>
            </div>
        </div>
        <cfif args.editing>
            <input type="hidden" name="blogid" value="#encodeForHTML(args.blog.getId())#"/>
        </cfif>
    </div>
</form>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/paragraph@2.11.7/dist/paragraph.umd.js" integrity="sha384-lLK35tPhwDTnFk6ouQhe86GxDo5/HUCzSZQYPRF3rdLQ8I+ay/a2W1ygFwApL6uc" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/header@2.8.9/dist/header.umd.js" integrity="sha384-gsHcARcunRrx+hZA2vZY6ESWTIC8ZJZpyuAjNmKponX5ftG43VHfZ8geURncPDPh" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/raw@2.5.1/dist/raw.umd.js" integrity="sha384-SnKuY1dyCiUIK4MoMUEprsVtxaN/aMGLqyipRou/Wyc3E2PZTEITsxTvoIq2RXTb" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/image@2.10.3/dist/image.umd.js" integrity="sha384-x+8X+am+peBvhMXyUZDpid1xuh/eJzrRGmPT7082F3Q4BL+GFvqjtx+b/MavaMhc" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/checklist@1.6.0/dist/checklist.umd.js" integrity="sha384-0BqF+qLJW3rgkQbEXSAPhd2gF6Xwk49oPrdpj1vTJP8oD38jxRANuMVPYi0ehfVr" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/list@2.0.9/dist/editorjs-list.umd.js" integrity="sha384-rgmnoyP4Ld6tRkTXoq965fzulyZZ6NSUYy+JYI4mO9sxaJDrpyjORlNUz5Un2gbn" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/quote@2.7.6/dist/quote.umd.js" integrity="sha384-z43sl0T5c0VaZ0qANtyMgguU+QmuuzTmE4lWCjGDs2IgVrbQn6ycdbCwemISQxug" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/code@2.9.4/dist/code.umd.js" integrity="sha384-pmKzfNHAxgIHBx/Nzm5HVAQyKQwkM/Mpcm2NSVPojR03VCm4g2kYBgzY9FsE4cXa" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/editorjs-indent-tune@1.4.4/dist/bundle.js" integrity="sha384-1W5w9tcMpNuqSMaFAM75j8Y4FYXjpa2z/kegdENJjpCHmGrlsWT5RuIX2GNLMb92" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/editorjs-html@4.0.0/.build/edjsHTML.js" integrity="sha384-BB4X7yc0bnM2VsOMK98H1Rqxp1yjp/UfUFXm396N0Gsbc9ycSB4vF95LBGsjqrKM" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/editorjs@2.31.6/dist/editorjs.umd.js" integrity="sha384-GD/okP6ykDTeZ/l96nAWwMNN+U76lsX9WmEFpA4OQxpM2Ymz52nGfZBlj0H2vAfI" crossorigin="anonymous"></script>

<script>var bodyJson = <cfif args.keyExists('bodyJson')>#args.bodyJson#<cfelse>{}</cfif>;</script>
</cfoutput>