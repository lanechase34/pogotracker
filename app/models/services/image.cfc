component singleton accessors="true" {

    property name="imageMagick" inject="coldbox:setting:imageMagickPath";
    property name="uploadPath"  inject="coldbox:setting:uploadPath";

    /**
     * Verify image magick is running
     */
    public boolean function verifyImageMagick() {
        try {
            cfexecute(
                name      = "#imageMagick#",
                arguments = "identify --version",
                variable  = "result",
                timeout   = 30
            );
        }
        catch(any e) {
            return false;
        }
        return true;
    }

    /**
     * Uses imagick identify to check if path is a valid image
     *
     * @path full path to image
     */
    public boolean function validIdentify(required string path) {
        try {
            cfexecute(
                name      = "#imageMagick#",
                arguments = "identify ""#arguments.path#""",
                variable  = "result",
                timeout   = 30
            );
        }
        catch(any e) {
            return false;
        }
        return true;
    }

    /**
     * Uses imagick mogrify to convert the upload to webp and decrease quality
     *
     * @path full path to image
     */
    public boolean function convertToWebp(required string path, numeric quality = 50) {
        try {
            cfexecute(
                name      = "#imageMagick#",
                arguments = "mogrify -format webp -strip -quality #arguments.quality# ""#arguments.path#""",
                variable  = "result",
                timeout   = 30
            );
        }
        catch(any e) {
            return false;
        }
        return true;
    }

    /**
     * Validate the incoming image upload
     * If valid, move to the user's upload directory and return the filename generated
     *
     * @formField  image form field
     * @extensions
     */
    public string function validateUpload(
        required string formField,
        string extensions = 'png,jpg,jpeg,webp,heic',
        string uploadDir  = getUploadPath()
    ) {
        var result = '';

        // Attempt file upload to temp directory
        try {
            var upload = fileUpload(
                destination  = getTempDirectory(),
                fileField    = arguments.formField,
                accept       = 'image/png,image/jpeg,image/webp,image/heic',
                nameConflict = 'makeUnique',
                strict       = true
            );
        }
        catch(any e) {
            throw(type = 'UploadValidationException', message = 'Invalid image upload');
        }

        var tempPath = '#upload.serverdirectory#/#upload.serverfile#';
        tempPath     = replace(tempPath, '\', '/', 'all');

        // Check if valid image
        if(!validIdentify(tempPath) || !listFindNoCase(arguments.extensions, upload.serverfileext)) {
            fileDelete(tempPath);
            throw(type = 'UploadValidationException', message = 'Invalid image upload');
        }

        // Attempt to convert the upload to .webp
        var validConvert = convertToWebp(tempPath);

        if(!validConvert) {
            fileDelete(tempPath);
            throw(type = 'UploadValidationException', message = 'Invalid image upload');
        }

        var oldPath = tempPath;
        tempPath    = '#left(tempPath, tempPath.len() - upload.serverfileext.len())#webp';

        // Rename and move to uploads directory
        var newname = left(createUUID().replace('-', '', 'all'), 25);
        fileMove(tempPath, '#arguments.uploadDir#/#newname#.webp');

        // Delete temp file if was not .webp already
        if(fileExists(oldPath)) {
            fileDelete(oldPath);
        }

        // Return the new name
        return '#newname#.webp';
    }

    /**
     * Resizes blog image to specific dimensions used
     */
    public void function resizeBlogImage(required string filename) {
        // Resize the image
        var img = imageRead('#getUploadPath()#/#arguments.filename#');

        // Card
        img.scaleToFit(fitHeight = 250, fitWidth = '');
        img.write(destination = '#getUploadPath()#/cards/#arguments.filename#', quality = 0.1);

        // Full
        img.scaleToFit(fitHeight = 350, fitWidth = '');
        img.write(destination = '#getUploadPath()#/full/#arguments.filename#', quality = 0.1);

        fileDelete('#getUploadPath()#/#arguments.filename#');
        return;
    }

}
