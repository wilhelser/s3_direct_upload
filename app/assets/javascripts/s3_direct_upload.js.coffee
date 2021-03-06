#= require jquery-fileupload/basic
#= require jquery-fileupload/vendor/tmpl

(($) ->
  $.fn.S3Uploader = (options) ->

    # support multiple elements
    if @length > 1
      @each ->
        $(this).S3Uploader options

      return this

    $uploadForm = this

    settings =
      path: ''
      additional_data: null
      before_add: null

    settings = $.extend settings, options

    current_files = []

    setUploadForm = ->
      $uploadForm.fileupload

        add: (e, data) ->
          current_files.push data
          file = data.files[0]
          unless settings.before_add and not settings.before_add(file)
            data.context = $(tmpl("template-upload", file))
            $uploadForm.append(data.context)
            data.submit()

        progress: (e, data) ->
          if data.context
            progress = parseInt(data.loaded / data.total * 100, 10)
            data.context.find('.bar').css('width', progress + '%')

        done: (e, data) ->
          file = data.files[0]
          domain = $uploadForm.attr('action')
          path = settings.path + $uploadForm.find('input[name=key]').val().replace('/${filename}', '')
          to = $uploadForm.data('post')
          content = {}
          content[$uploadForm.data('as')] = domain + path + '/' + file.name
          content.filename = file.name
          content.filepath = path
          if settings.additional_data
            content = $.extend content, settings.additional_data
          if 'size' of file
            content.file_size = file.size
          if 'type' of file
            content.file_type = file.type

          $.post(to, content)
          data.context.remove() if data.context # remove progress bar

          current_files.splice($.inArray(data, current_files), 1) # remove that element from the array 
          if current_files.length == 0
            $(document).trigger("s3_uploads_complete")

        fail: (e, data) ->
          alert("#{data.files[0].name} failed to upload.")
          console.log("Upload failed:")
          console.log(data)

        formData: (form) ->
          data = form.serializeArray()
          fileType = ""
          if "type" of @files[0]
            fileType = @files[0].type
          data.push
            name: "Content-Type"
            value: fileType

          data[1].value = settings.path + data[1].value

          data

    #public methods
    @initialize = ->
      setUploadForm()
      this

    @path = (new_path) -> 
      settings.path = new_path

    @additional_data = (new_data) ->
      settings.additional_data = additional_data

    @initialize()
) jQuery
