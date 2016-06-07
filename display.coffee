# @param eltId the target HTML element id
# @param file the source image file path
# @param image the parsed {header, data} object to display
# @param z the zero-based z dimension index

define 'display', ['cornerstone'], (cornerstone) ->
  (eltId, file, image, z) ->
    # The display target element.
    elt = document.getElementById(eltId)
  
    # The Cornerstone loader scheme.
    LOADER_SCHEME = 'nifti'
  
    # The integer data type pattern matcher.
    INT_DATATYPE_REGEX = /^u?int(\d\d?)$/

    # Enable the Cornerstone viewports.
    #
    cornerstone.enable(elt)
  
    # @returns a unique id for the given image location
    imageIdFor = ->
      # Append the slice number to the image path.
      "#{ LOADER_SCHEME }:#{ file }[#{ z }]"

    # Selects the [x, y] view of the 3D image [ x, y, z] ndarray.
    format = ->
      # The unique slice image id.
      imageId = imageIdFor(z)
      # The image header.
      header = image.header
      # The slice image data subarray.
      data = image.data.pick(null, null, z)
      # Return the data adapted for Cornerstone.
      adapt(imageId, header, data)
  
    # @param imageId the caching id
    # @param header the parsed {nifti, dicom} object
    # @param data the NIfTI image byte array
    # @returns the Cornerstone image object
    adapt = (imageId, header, data) ->
      # The datum size in bytes.
      match = INT_DATATYPE_REGEX.exec(header.nifti.datatype)
      if match?
        datumSize = parseInt(match[1])
      else if header.nifti.datatype is 'float'
        datumSize = 4
      else if header.nifti.datatype is 'double'
        datumSize = 8
      else
        throw new Error("The NIfTI datatype is not recognized:" +
                        " #{ header.nifti.datatype }")
      # The 1D intensity array.
      flat = flatten(data, datumSize)
      if not header.dicom?
        throw new Error("The NIfTI file is missing the embedded" +
                        " DICOM meta-data extension")
      if not header.dicom.WindowCenter?
        throw new Error("The image is missing an embedded DICOM meta-data" +
                        " WindowCenter tag")
      windowCenter = header.dicom.WindowCenter[z]
      if not header.dicom.WindowWidth?
        throw new Error("The image is missing an embedded DICOM meta-data" +
                        " WindowWidth tag")
      windowWidth = header.dicom.WindowWidth[z]

      slope = header.nifti.scl_slope
      intercept = header.nifti.scl_inter

      # The columns and rows are the NIfTI shape first and
      # second items, resp.
      colCnt = data.shape[0]
      rowCnt = data.shape[1]

      # The column/row pixel spacing is the NRRD spacings
      # second and third items, resp.
      spacing =
        column: header.nrrd.spacings[1]
        row: header.nrrd.spacings[2]
      # The number of bytes in the image data.
      byteCnt = colCnt * rowCnt * datumSize

      # Return the Cornerstone image descriptor.
      imageId: imageId
      minPixelValue : flat.min
      maxPixelValue : flat.max
      slope: slope
      intercept: intercept
      windowCenter : windowCenter
      windowWidth : windowWidth
      render: cornerstone.renderGrayscaleImage
      getPixelData: -> flat.data
      columns: colCnt
      rows: rowCnt
      width: colCnt
      height: rowCnt
      color: false
      columnPixelSpacing: spacing.column
      rowPixelSpacing: spacing.row
      sizeInBytes: byteCnt

    # Converts the given 2D ndarray to a 1D array.
    #
    # @param data the 2D ndarray
    # @param datumSize the intensity value size in bytes
    # @returns the {data, min, max} object containing
    #   the flattened 1D data array and the minimum
    #   and maximum values
    flatten = (data, datumSize) ->
      colCnt = data.shape[0]
      rowCnt = data.shape[1]
      length = colCnt * rowCnt
      # Determine the min and max during the iteration.
      minValue = Math.pow(2, 15) - 1
      maxValue = -minValue
      # The 1D array content.
      buffer = new ArrayBuffer(length * datumSize)
    
      # Flatten the ndarray.
      shape = [data.shape.reduce(_.multiply)]
      stride = data.stride[..0]
      flat = ndarray(data.data, shape=shape, stride=stride, offset=data.offset)
      # Alias the size property as length.
      Object.defineProperties flat,
        length:
          get: -> @size
      # Add a map function.
      flat.map = (fn) ->
        (fn(@get(i), i, this) for i in [0...@length])

      # Calculate the min and max intensity.
      for i in [0...flat.length]
        minValue = Math.min(minValue, flat.get(i))
        maxValue = Math.max(maxValue, flat.get(i))

      # Return the {data, min, max} object
      data: flat
      min: minValue
      max: maxValue

    # Format the image for Cornerstone.
    descriptor = format()
    # Display the image.
    cornerstone.displayImage(elt, descriptor)
