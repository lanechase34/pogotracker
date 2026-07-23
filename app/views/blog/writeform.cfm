<cfoutput>
<form name="writeblogform" data-submit="#encodeForHTML(args.submit)#" id="writeblogform" class="g-3" novalidate action="" method="post" autocomplete="off">
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
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/paragraph@2.11.7"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/header@2.8.9"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/raw@2.5.1"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/image@2.10.3"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/checklist@1.6.0"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/list@2.0.9"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/quote@2.7.6"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/code@2.9.4"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/editorjs-indent-tune@1.4.4/dist/bundle.js"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/editorjs-html@4.0.0/.build/edjsHTML.js"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/@editorjs/editorjs@2.31.6"></script>

<script>var bodyJson = <cfif args.keyExists('bodyJson')>#args.bodyJson#<cfelse>{}</cfif>;</script>
</cfoutput>