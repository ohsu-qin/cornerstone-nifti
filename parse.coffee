define 'parse', ['lodash', 'niftiParser', 'ndarray'], (_, niftiParser, ndarray) ->
  # Unquoted whitespace matcher (doesn't handle escapes).
  WHITESPACE_REGEX = /\s+(?=([^"]*"[^"]*")*[^"]*$)/g

  # Parses the image file content. Returns the
  # {header, data}, where:
  # * *header* is an object {nifti, nrrd, dicom}, where *nifti* is
  #   is the NIfTI header, NRRD is the NRRD header and *dicom* is
  #   the embedded DICOM meta-data object
  # * *data* is the image binary ndarray in dimension order
  #   [x, y, z, time], where *z* is the slice index and *time*
  #   is the volume index.
  # 
  # @buffer the binary image file ArrayBuffer 
  # @returns the parsed image {header, data} object
  (buffer) ->
    # Extract the NIfTI header.
    niftiHeader = niftiParser.parseNIfTIHeader(buffer)
    # Extract the NRRD header.
    nrrdHeader = niftiParser.parseNRRDHeader(buffer)
  
    # Extract the embedded DICOM metadata. 
    extensions = niftiParser.parseHeaderExtensions(buffer)
    if extensions.length > 1
      throw new Error("The NIfTI file has more than one extension")
    if extensions.length == 1
      extension = extensions[0]
      # Note: the conventional idiom:
      #   String.fromCharCode.apply(null, data)
      # results in a stack overflow. The work-around is to convert
      # the characters one byte at a time.
      chars = (String.fromCharCode(c) for c in extension.data)
      # Get rid of whitespace.
      json = chars.join('').replace(WHITESPACE_REGEX, '')
      # Note: JSON parse fails with message that it can't find
      # a JSON object. The work-around to this work-around bug is
      # to search for the substrings we want and hammer together
      # a minimal JSON string.
      # TODO - unravel this mess.
      windowCenterRegex = /("WindowCenter":\[[^\]]+\])/
      windowWidthRegex = /("WindowWidth":\[[^\]]+\])/
      matches = windowCenterRegex.exec(json)
      if matches?
        item1 = matches[1]
        matches = windowWidthRegex.exec(json)
        if matches?
          item2 = matches[1]
          json = '{' + [item1, item2].join(',') + '}'
          # Parse the JSON.
          dicom = JSON.parse(json)
        else
          dicom = null
      else
        dicom = null
    else
      dicom = null

    # Extract the image binary data.
    parsed = niftiParser.parse(buffer)
    # The binary image ndarray. Per the nifti-js site, the NIfTI
    # header sizes attribute is the inverse of the raw NIfTI
    # ndarray order, and suggests reversing the sizes in the
    # ndarray constructor argument below. There is (of course)
    # no rationale given for this. We dispense with this advice
    # and retain the input sizes, which results in a data shape
    # consistent with the input shape.
    # 
    # The dcmstack layout is in [time, x, y, z] order. This differs
    # from the expected [x, y, z, time] order described
    # in, e.g., https://brainder.org/2012/09/23/the-nifti-file-format/,
    # We retain the input layout, which has ramifications for the
    # array slicing and dicing in sliceDisplay.coffee.
    #
    # Note: the js ndarray default stride differs from the expected
    # nibabel default stride, after accounting for the difference
    # in the underlying datum size (byte for nibabel, int16 for js).
    # Reversing the sizes as described above still results in an
    # incorrect stride. The work-around is to calculate the stride
    # by hand.
    # TODO - bring this up with the ndarray dev team.
    stride = (parsed.sizes[0...i].reduce(_.multiply, 1) for i in [0...parsed.sizes.length]) 
    data = ndarray(parsed.data, parsed.sizes, stride)
  
    # Return the image {header, data} object.
    header:
      nifti: niftiHeader
      nrrd: nrrdHeader
      dicom: dicom
    data: data
