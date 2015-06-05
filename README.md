##License Declaration

<a rel="license" href="http://creativecommons.org/licenses/by/3.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/3.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">UpStage</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="http://upstage.org.nz/" property="cc:attributionName" rel="cc:attributionURL">AUT UpStage Team</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/3.0/">Creative Commons Attribution 3.0 Unported License</a>.<br />Based on a work at <a xmlns:dct="http://purl.org/dc/terms/" href="https://github.com/autupstageteam/upstage" rel="dct:source">https://github.com/autupstageteam/upstage</a>.<br />Permissions beyond the scope of this license may be available at <a xmlns:cc="http://creativecommons.org/ns#" href="http://www.upstage.org.nz/" rel="cc:morePermissions">http://www.upstage.org.nz/</a>.

## Installation & Usage
________

Run `python install.py` to install UpStage, and use `upstage-admin` command to create and manage UpStage server(s) after successful installation
> root permission is probably required

### Other options

- `python install.py cc` to compile client.swf (uses `mtasc` and `swfmill`)
- `python install.py deb` to generate .deb package

### Uninstallaion

To uninstall UpStage from the system, execute `uninstall.sh` script with appropriate permission

### Dependencies

- espeak
- festival
- gif2png
- libgif4
- netpbm
- python-twisted 8.2.0 recommended
- lame >= 3.97-0.0
- libgdbmg >= 1.7.3-28
- rsynth >= 2.0-6
- mbrola >= 3.01h-6
- swftools >= 0.9.0-0ubuntu1
- python <= 2.5.2
- pymad (NEW)

twisted: wget http://tmrc.mit.edu/mirror/twisted/Twisted/8.2/Twisted-8.2.0.tar.bz2

swftools: wget http://archive.canonical.com/ubuntu/pool/partner/s/swftools/swftools_0.9.0-0ubuntu2_i386.deb

rsynth: wget http://archive.debian.org/debian-archive/debian/pool/non-free/r/rsynth/rsynth_2.0-6_i386.deb


## For Development
________
__Important:__ Modify the following lines in `server/src/upstage/config.py` like so, and don't forget to modify it back for version releases
```
# Uncomment if installed using install.py or deb pkg
# IMG2SWF_SCRIPT = '/usr/local/bin/img2swf.py'

# Uncomment below if use Ant for development
IMG2SWF_SCRIPT = './img2swf.py'
```

Use `ant` to compile/build/run (other targets are not tested yet)
> Note: you need to install `mtasc` and `swfmill` to compile UpStage client

### Ant Targets:

- `ant clean-start` to build a new instance of UpStage and run it as a background process
- `ant start` to start the built instance of UpStage as a background process
- `ant stop` to stop the UpStage server instance running in the background
- `ant build` to build UpStage, and `build/upstage-server.sh` to run the server manually on default ports
- `ant run` to  build and run automatically
- `ant clean` to clean `build` and `temp` directories
- `ant compile-swf` to compile client swf files

> For problems about the cross domain policy when running multiple server instances (the typical symptom is users cannot load stages), see comments about `this.policyport` variable in `parseUrlVars()` inside `Transport.as`.

________
#### AUT UpStage Team 2013
