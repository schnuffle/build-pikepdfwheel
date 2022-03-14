# build-pikepdfwheel
Build wheels for pike PDF on arm

As paperless-ngx has a lot of problems installing the dependencies on the ARMV7/64 platforms, this Repo tries to provide all those missing peaces.
The reason is quite simple, the build takes serveral hours which really breaks the "commit and test often" mantra.

I did a first test with creating the pikepdf wheel:
- Wheels build and install properly
- Using the  image leads to errors as the final image has been missing the qpdf libs

The easy solution would have been to have the compiled qpdf also available. I decided otherwise.

My new approach for the moment based on the idea that with creating a backport from testing, I can take advantage of the test suites of those apps and be sure that in the end the package doesn't have unmet dependencies:
- I've managed to build/install the qpdf backports
- The pikepdf backport is not missing much but as it builds qpdf before every run takes 2-3 hours so progress is slow
- To keep my nerves chilled and speedup dev I made another split and am building/pushing the qpdf image
- The PIKEPDF image is then based on the qpdf image, so that I don't need to wait as long




