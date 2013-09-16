## AUT UpStage Team 2013

### List of dependencies
________

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

twisted: wget http://tmrc.mit.edu/mirror/twisted/Twisted/8.2/Twisted-8.2.0.tar.bz2
swftools: wget http://archive.canonical.com/ubuntu/pool/partner/s/swftools/swftools_0.9.0-0ubuntu2_i386.deb
rsynth: wget http://archive.debian.org/debian-archive/debian/pool/non-free/r/rsynth/rsynth_2.0-6_i386.deb

________

Use `ant` to compile/build/run (other targets are not tested yet)
> Note: you need to install `mtasc` and `swfmill` to compile UpStage client

## Instructions:

- `ant clean-start` to build a new instance of UpStage and run it as a background process
- `ant start` to start the built instance of UpStage as a background process
- `ant kill` to stop UpStage server that is currently running

#### Other useful targets

- `ant build` to build UpStage, and `build/upstage-server.sh` to run the server manually on default ports
- `ant run` to  build and run automatically
- `ant clean` to clean `build` and `temp` directories
- `ant compile-swf` to compile client swf files
