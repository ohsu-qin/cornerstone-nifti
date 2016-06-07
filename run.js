define("run", ["load", "parse", "display"], function (load, parse, display) {
  return function (eltId, file, z) {
    load(file, function (content) {
      var parsed = parse(content);
      // Augment the parsed header with DICOM Window tags for the two slices.
      parsed.header.dicom = {
        WindowCenter: [1513, 1585],
        WindowWidth: [3212, 3191]
      }
      display(eltId, file, parsed, z);
    });
  };
});
