# cornerstone-nifti: Cornerstone NIfTI demo

Displays a NIfTI image using the [Cornerstone](https://github.com/chafey/cornerstone)
library.

Installation
============
* Clone this git repository.
* Run ``npm install``.

Usage
=====
* Run ``npm start``.

Notes
=====
* The input NIfTI file is a small volume consisting of two slices. The first slice
  is displayed. The image is a cylinder viewed on its side, thus showing up
  as a bar.

* This demo uses a [Cornerstone fork](https://github.com/ohsu-qin/cornerstone)
  which extends Cornerstone for NIfTI support.

* Cornerstone requires two DICOM tag values ``WindowWidth`` and ``WindowCenter``
  which do not have a NIfTI equivalent. These values are set in ``run.js``.

* This example uses RequireJS to load the modules. jQuery is loaded as a
  Cornerstone peer dependency, but is not otherwise used.

* The npm ``build`` script compiles ``display.coffee`` and ``parse.coffee``
  into JavaScript.
