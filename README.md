## AUT UpStage Team 2013

### List of dependencies

________

- espeak
- festival
- gif2png
- libgif4
- netpbm
- python-twisted <= 8.1.0-4 (8.2.0 recommended)
- lame >= 3.97-0.0
- libgdbmg >= 1.7.3-28
- rsynth >= 2.0-6
- mbrola >= 3.01h-6
- swftools >= 0.9.0-0ubuntu1
- python <= 2.5.2

swftools: wget http://archive.canonical.com/ubuntu/pool/partner/s/swftools/swftools_0.9.0-0ubuntu2_i386.deb
rsynth: wget http://archive.debian.org/debian-archive/debian/pool/non-free/r/rsynth/rsynth_2.0-6_i386.deb

________

**We will use Ant to build and run UpStage in the near future.**

________

### Install Instructions:

As root run: `apt-get install espeak festival gif2png libgif4 netpbm python-twisted timeout`
> NOTE: You will need to install: swftools, lame, libgdbmg, mbrola and rsynth using your distributions package manager.

If you have downloaded the other dependencies as deb files, install them

- Extract the dependency.tar.gz file
- `cd` to the dependency folder
- run as root: `dpkg -i *.deb`


If downloaded from GitHub

- Extract the download .zip or .tar.gz

Open a terminal and cd to UpStage directory.

Run: `python install.py`
This will install upstage. Refer to below instructions for other options

If you prefer to use the deb file there is a built in deb creater but you need to have the following installed:

```
apt-get install build-essential autoconf automake autotools-dev dh-make debhelper devscripts fakeroot xutils lintian pbuilder
```

Once the above build tools are installed run: `python install.py deb`

To compile the client if you made changes or just want to make sure the latest client in included, use:
`python install.py cc /path/to/flex`

If you do not have the flex compiler 2. Then this will not work.