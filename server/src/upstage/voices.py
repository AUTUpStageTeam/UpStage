"""Voice definitions used by the speech engine, and the avatar editing
pages.

The voices are automatically generated.

XXX TODO: it should check whether the appropriate files exist.

Modified: Shaun Narayan (01/27/10) - Static Voices Bug Fix (Aut Upstage team 09/10)
                                   - Modified to allow finding enhanced festival2 voices
                                   - Added new voices (some are just re-sampled existing voices)
Heath Behrens & Vibhu Patel (15-06-2011) - Added some new voices namely emb_de6, emb_it4,emb_ro1,emb_gr2. More to come.
						   Note the voice packages need to be installed, for the emb voices to work the packages: 
						   mbrola-* need to be installed using either debian package manager or by extracting the 
						   files to /usr/share/mbrola/
Heath Behrens (18/09/2011) - Patch for emb voices, namely the emb voices which did not work on the main 
                               server. Modified _espeak_mbrola function.
                           
Daniel Han (12/10/2011) - Patch for cmu Voices which failed to create proper MP3 but only with noises. modified festival related methods
Gavin Chan and Scott Riddell (23/10/2011) - Changed raw to wav, updated _festival and _festival 2 methods to correctly configure the files into the right voice format
Gavin Chan and Scott Riddell (29/10/2011) - Changed the mbrola path to the correct location, edited Rsynth method to work correctly.
"""
import re, os

from upstage import config

log = '' #' 2>> ' + config.SPEECH_LOG


def find_executable(x):
    """Look for a file of thegiven name in the executable path.  By
    doing this here, instead of letting the system path find it, it is
    possible to identify missing executables and avoid adding them to
    the voices list.
    """
    for p in ('/usr/local/bin/', '/usr/bin/', '/bin/', './'):
        exe = os.path.join(p, x)
        if os.path.exists(exe):
            return exe
    return ''

timeout = find_executable('timeout')
if timeout:
    timeout = " %s %s " % (timeout, config.SPEECH_TIMEOUT)
    

echo_in = ''#cat | ' #"read SPEECH ; echo $SPEECH |"
#Heath Behrens readded the -x switch used for byte switching as it breaks some voices.
#fest_lame =    " | %s lame -S --quiet -m s -s %%s --resample 22.05 - $1 " % timeout
fest_lame =    " | %s lame -S --quiet -m s -s %%s --resample 44.10 - $1 " % timeout
rsynth_lame =  " | %s lame -S --quiet -m m -r -s 11.025 --preset phone - $1 " % timeout
#espeak_mbrola_lame = " | %s lame -S --quiet -m m -s 16  --resample 22.05 --preset phone $1.wav $1" % timeout
espeak_mbrola_lame = "%s lame -S --quiet -m m -s 16  --resample 22.05 --preset phone $1.wav $1" % timeout

# espeak doesn't seem to like piping to stdout, so it saves to tmp file instead
espeak_lame =  " %s lame -S --quiet -m m -s 22.05 --preset phone $1.wav $1 " % timeout
espeak_cleanup = " rm $1.wav "

#Heath Behrens - Need to declare to possible paths for mbrola voices.
path_to_embrola = "/usr/share/mbrola/"
#Heath Behrens - this is the path to some of the voices that install in a different location.
#The other option is to simply copy all voices from the folder to the previous folder.
path_to_embrola_alt = "/usr/share/mbrola/voices"

# freshly downloaded mbrola voices
# cause: "Binary error", see: http://tcts.fpms.ac.be/synthesis/mbrola/mbrfaq.html#Q2
path_to_embrola_voices = "/usr/local/share/mbrola/"

# FIXME: seems unused right now!
#text2wave = '/usr/local/share/festvox/festival/bin/text2wave'
text2wave = '/usr/bin/text2wave'

#these functions are run over the definitions in VOICE_KIT, below, to
#create the appropriate shell script for each voice.

def _festival(voice, hz):
    s = ''.join((echo_in, timeout, "text2wave -eval '%s' " % voice,
                " -otype wav - -o - ", log,
                (fest_lame % hz), log))
    return [s]

def _festival2(voice, hz, options=''):
    s = ''.join((echo_in, timeout, "text2wave -eval '%s' " % voice,
                 options, " -otype wav - -o - ", log,
                (fest_lame % hz), log))
    return [s]

# manually installed festival 2.1
# TODO: check that the correct "text2wave" ist used!
def _festival3(voice, hz, options=''):
    s = ''.join((echo_in, timeout, "/usr/bin/text2wave -eval '%s' " % voice,
                 options, " -otype wav - -o - ", log,
                (fest_lame % hz), log))
    return [s]

def _rsynth(options):
    exe = find_executable('rsynth-say')
    if not exe:
        return None
    s = ''.join((echo_in, timeout, exe, " -a -l ", options,
                " -  ", log, rsynth_lame, log
                ))
    return [s]

def _espeak(voice, options=''):
    exe = find_executable('espeak')
    if not exe:
        return None
    s = ''.join((echo_in, timeout, exe, " -k27 ", options,
                 " -v ", voice, " --stdin -w $1.wav ", log))
    return [s, espeak_lame, espeak_cleanup]

"""
  Modified by Heath Behrens, changed espeak mbrola scripts to use the same method as e_ voices, which
  writes to a temporary file.
"""
def _espeak_mbrola(voice, mbvoice, options='', mboptions=''):
    espeak = find_executable('espeak')
    mbrola = find_executable('mbrola')
    if not espeak or not mbrola:
        return None
    #s = ''.join((echo_in, timeout, espeak, " -k27 -v ", voice, options, " --stdin ", log,
    #            " | ", mbrola, " -e ", mboptions, " " + path_to_embrola, mbvoice, 
    #            " - $1.wav ", log))
    s = ''.join((echo_in, timeout, espeak, " -k27 -v ", voice, options, " --stdin ", log,
                " | ", mbrola, " -e ", mboptions, " " + path_to_embrola_voices, mbvoice, 
                " - $1.wav ", log))
    return [s, espeak_mbrola_lame, espeak_cleanup]


#XXX perhaps ought to be moved OUT of python code into a real config file.
VOICE_KIT = {
          #Shaun Narayan (01/23/10) - Changed sampling rate (from 16 to 8) for all festival voices as after voices bug fix they were too fast
          #debian packaged festival/mbrola:
          #'default': (_festival, ('(voice_us1_mbrola)', 8 )),
          #'roger': (_festival, ('(voice_en1_mbrola)', 8)),
          #'bud': (_festival, ('(voice_us2_mbrola)', 8)),
          #'randy': (_festival, ('(voice_us3_mbrola)', 8)),
          # ------
          'default': (_festival, ('(voice_us1_mbrola)', 16)),
          'roger': (_festival, ('(voice_en1_mbrola)', 16)),
          'bud': (_festival, ('(voice_us2_mbrola)', 16)),
          'randy': (_festival, ('(voice_us3_mbrola)', 16)),

          #debian packaged festival/festival
          #'kal': (_festival, ('(voice_kal_diphone)', 8)),
          #'ked': (_festival, ('(voice_ked_diphone)', 8)),
          #'rab': (_festival, ('(voice_rab_diphone)', 8)),
          #'don': (_festival, ('(voice_don_diphone)', 5)),
          # ------
          'kal': (_festival, ('(voice_kal_diphone)', 16)),
          'ked': (_festival, ('(voice_ked_diphone)', 16)),
          'rab': (_festival, ('(voice_rab_diphone)', 16)),
          'don': (_festival, ('(voice_don_diphone)', 16)),

          #compiled festival
          #'slt_cmu': (_festival2, ('(voice_cmu_us_slt_arctic_clunits)', 8)),
          #'slt_nitech': (_festival2, ('(voice_nitech_us_slt_arctic_hts)', 8)),
          #'awb_cmu': (_festival2, ('(voice_cmu_us_awb_arctic_clunits)', 8)),
          #'awb_nitech': (_festival2, ('(voice_nitech_us_awb_arctic_hts)', 8)),
          #'clb_nitech': (_festival2, ('(voice_nitech_us_clb_arctic_hts)', 8)),
          #'bdl_cmu': (_festival2, ('(voice_cmu_us_bdl_arctic_clunits)', 8)),
          #'bdl_nitech': (_festival2, ('(voice_nitech_us_bdl_arctic_hts)', 8)),
          #'jmk_cmu': (_festival2, ('(voice_cmu_us_jmk_arctic_clunits)', 8)),
          #'jmk_nitech': (_festival2, ('(voice_nitech_us_jmk_arctic_hts)', 8)),
          #'rms_nitech': (_festival2, ('(voice_nitech_us_rms_arctic_hts)', 8)),
          #'rms_faster': (_festival2, ('(voice_nitech_us_rms_arctic_hts)', 8, " -F 11025")),
          # -----
          'slt_cmu': (_festival3, ('(voice_cmu_us_slt_arctic_hts)', 16)),
          'slt_nitech': (_festival3, ('(voice_nitech_us_slt_arctic_hts)', 16)),
          'awb_cmu': (_festival3, ('(voice_cmu_us_awb_arctic_hts)', 16)),
          'awb_nitech': (_festival3, ('(voice_nitech_us_awb_arctic_hts)', 16)),
          'clb_nitech': (_festival3, ('(voice_nitech_us_clb_arctic_hts)', 16)),
          'bdl_cmu': (_festival3, ('(voice_cmu_us_bdl_arctic_hts)', 16)),
          'bdl_nitech': (_festival3, ('(voice_nitech_us_bdl_arctic_hts)', 16)),
          'jmk_cmu': (_festival3, ('(voice_cmu_us_jmk_arctic_hts)', 16)),
          'jmk_nitech': (_festival3, ('(voice_nitech_us_jmk_arctic_hts)', 16)),
          'rms_nitech': (_festival3, ('(voice_nitech_us_rms_arctic_hts)', 16)),
          # rms does not work "faster"
          #'rms_faster': (_festival3, ('(voice_nitech_us_rms_arctic_hts)', 8, " -F 11.025")),
          ###Shaun Narayan (02/22/10) - New voices
          #'bdl_cmu': (_festival2, ('(voice_cmu_us_bdl_arctic_clunits)', 8)),
          #'ksp_cmu': (_festival2, ('(voice_cmu_us_ksp_arctic_clunits)', 8)),
          #'rms_cmu': (_festival2, ('(voice_cmu_us_rms_arctic_clunits)', 8)),
          #'kal_cmu': (_festival2, ('(voice_cmu_us_kal_com_clunits)', 8)),
          #'kal_cmu_faster': (_festival2, ('(voice_cmu_us_kal_com_clunits)', 8, " -F 11025")),
          #'bdl_cmu_faster': (_festival2, ('(voice_cmu_us_bdl_arctic_clunits)', 8, " -F 11025")),
          #'ksp_cmu_faster': (_festival2, ('(voice_cmu_us_ksp_arctic_clunits)', 8, " -F 11025")),
          #'rms_cmu_faster': (_festival2, ('(voice_cmu_us_rms_arctic_clunits)', 8, " -F 11025")),
          #'slt_cmu_faster': (_festival2, ('(voice_cmu_us_slt_arctic_clunits)', 8, " -F 11025")),
          #'slt_nitech_faster': (_festival2, ('(voice_nitech_us_slt_arctic_hts)', 8, " -F 11025")),
          #'awb_cmu_faster': (_festival2, ('(voice_cmu_us_awb_arctic_clunits)', 8, " -F 11025")),
          #'awb_nitech_faster': (_festival2, ('(voice_nitech_us_awb_arctic_hts)', 8, " -F 11025")),
          #'clb_nitech_faster': (_festival2, ('(voice_nitech_us_clb_arctic_hts)', 8, " -F 11025")),
          #'bdl_cmu_faster': (_festival2, ('(voice_cmu_us_bdl_arctic_clunits)', 8, " -F 11025")),
          #'bdl_nitech_faster': (_festival2, ('(voice_nitech_us_bdl_arctic_hts)', 8, " -F 11025")),
          #'jmk_cmu_faster': (_festival2, ('(voice_cmu_us_jmk_arctic_clunits)', 8, " -F 11025")),
          #'jmk_nitech_faster': (_festival2, ('(voice_nitech_us_jmk_arctic_hts)', 8, " -F 11025")),
          # ------
          # bdl_cmu already defined: commented out
          #'bdl_cmu': (_festival3, ('(voice_cmu_us_bdl_arctic_hts)', 16)),
          # ksp and rms do not work:
          #'ksp_cmu': (_festival3, ('(voice_cmu_us_ksp_arctic_hts)', 16)),
          #'rms_cmu': (_festival3, ('(voice_cmu_us_rms_arctic_hts)', 16)),
          # kal_cmu does not exist: commented out
          #'kal_cmu': (_festival3, ('(voice_cmu_us_kal_com_hts)', 16)),
          # all "faster" versions commented out, as they will not work (without sox or similar)
          #'kal_cmu_faster': (_festival3, ('(voice_cmu_us_kal_com_hts)', 16, " -F 8000")),
          #'bdl_cmu_faster': (_festival3, ('(voice_cmu_us_bdl_arctic_hts)', 8, " -F 8000")),
          #'ksp_cmu_faster': (_festival3, ('(voice_cmu_us_ksp_arctic_hts)', 8, " -F 8000")),
          #'rms_cmu_faster': (_festival3, ('(voice_cmu_us_rms_arctic_hts)', 8, " -F 8000")),
          #'slt_cmu_faster': (_festival3, ('(voice_cmu_us_slt_arctic_hts)', 8, " -F 8000")),
          #'slt_nitech_faster': (_festival3, ('(voice_nitech_us_slt_arctic_hts)', 8, " -F 8000")),
          #'awb_cmu_faster': (_festival3, ('(voice_cmu_us_awb_arctic_hts)', 8, " -F 8000")),
          #'awb_nitech_faster': (_festival3, ('(voice_nitech_us_awb_arctic_hts)', 8, " -F 8000")),
          #'clb_nitech_faster': (_festival3, ('(voice_nitech_us_clb_arctic_hts)', 8, " -F 8000")),
          #'bdl_cmu_faster': (_festival3, ('(voice_cmu_us_bdl_arctic_hts)', 8, " -F 8000")),
          #'bdl_nitech_faster': (_festival3, ('(voice_nitech_us_bdl_arctic_hts)', 8, " -F 8000")),
          #'jmk_cmu_faster': (_festival3, ('(voice_cmu_us_jmk_arctic_hts)', 8, " -F 8000")),
          #'jmk_nitech_faster': (_festival3, ('(voice_nitech_us_jmk_arctic_hts)', 8, " -F 8000")),
          
          
          #rsynth:
          'slow': (_rsynth, (" -x 1200 -S 3 ",)),
          'high': (_rsynth, (" -x 2800 -S 1.4  ",)),
          'crunchy' :(_rsynth, (" -x 1000 -f 16 -F 700 -t 20 ",)),


          #espeak:
          'e_en': (_espeak, ("en/en  ",)),
          #'e_en-croak': (_espeak,  ("en/en-croak ",)),
          'e_en-n': (_espeak, ("en/en-n ",)),
          #'e_en-r': (_espeak, ("en/en-r ",)),
          'e_en-r': (_espeak, ("en/en-us1 ",)),
          'e_en-rp': (_espeak, ("en/en-rp ",)),
          'e_en-sc': (_espeak, ("en/en-sc ",)),
          'e_en-wm': (_espeak, ("en/en-wm ",)),

          'e_en-wm-slow': (_espeak, ("en/en-wm ", ' -s 90' )),


          #'e_en-croak+11': (_espeak, ("en/en-croak+11 ",)),
          'e_en-n-f2': (_espeak, ("en/en-n+12 ",)),
          #'e_en-r-f3': (_espeak, ("en/en-r+13 ",)),
          'e_en-r-f3': (_espeak, ("en/en-us+13 ",)),
          'e_en-rp-f1': (_espeak, ("en/en-rp+11 ",)),
          'e_en-sc-f1': (_espeak, ("en/en-sc+11 ",)),
          'e_en-wm-f1': (_espeak, ("en/en-wm+11 ",)),         
          #'e_en-croak-f4': (_espeak, ("en/en-croak+14 ",)),
          'e_en-n-f4': (_espeak, ("en/en-n+14 ",)),
          #'e_en-r-f4': (_espeak, ("en/en-r+14 ",)),
          'e_en-r-f4': (_espeak, ("en/en-us+14 ",)),
          'e_en-rp-f4': (_espeak, ("en/en-rp+14 ",)),
          'e_en-sc-f4': (_espeak, ("en/en-sc+14 ",)),
          'e_en-wm-f4': (_espeak, ("en/en-wm+14 ",)),
          'e_en-wm-slow-f3': (_espeak, ("en/en-wm+13 ", ' -s 85 ')),

          'e_en-m1': (_espeak, ("en+1 ",)),
          'e_en-m2': (_espeak, ("en+2 ",)),
          'e_en-m3': (_espeak, ("en+3 ",)),
          'e_en-m4': (_espeak, ("en+4 ",)),
          'e_en-m5': (_espeak, ("en+5 ",)),
          'e_en-f1': (_espeak, ("en+11 ",)),
          'e_en-slow-f1': (_espeak, ("en/en+11 ", ' -s 90')),
          'e_en-fast-f1': (_espeak, ("en/en+11 ", ' -s 220')),
          'e_en-f2': (_espeak, ("en+12 ",)),
          'e_en-f3': (_espeak, ("en+13 ",)),
          'e_en-f4': (_espeak, ("en+14 ",)),
          'e_en-low-f4': (_espeak, ("en/en+14 ", ' -p 25 ')),

          #espeak non-english
          'e_af': (_espeak, ("af ",)),
          'e_cs': (_espeak, ("cs ",)),
          'e_cy': (_espeak, ("cy ",)),
          'e_de': (_espeak, ("de ",)),
          'e_el': (_espeak, ("el ",)),
          'e_eo': (_espeak, ("eo ",)),
          'e_es': (_espeak, ("es ",)),
          'e_fi': (_espeak, ("fi ",)),
          'e_fr': (_espeak, ("fr ",)),
          'e_hi': (_espeak, ("hi ",)),
          'e_hr': (_espeak, ("hr ",)),
          'e_hu': (_espeak, ("hu ",)),
          'e_it': (_espeak, ("it ",)),
          'e_nl': (_espeak, ("nl ",)),
          'e_no': (_espeak, ("no ",)),
          'e_pl': (_espeak, ("pl ",)),
          'e_pt': (_espeak, ("pt ",)),
          'e_pt-pt': (_espeak, ("pt-pt ",)),
          'e_ro': (_espeak, ("ro ",)),
          'e_ru': (_espeak, ("ru ",)),
          'e_sk': (_espeak, ("sk ",)),
          'e_sv': (_espeak, ("sv ",)),
          'e_sw': (_espeak, ("sw ",)),
          'e_vi': (_espeak, ("vi ",)),
          'e_zhy': (_espeak, ("zhy ",)),

          #espeak-mbrola: Heath Behrens - modified some of the paths to go one directory deeper.
          'emb_af1-en': (_espeak_mbrola, ("mb/mb-af1-en", "af1",)),
          'emb_de4-en': (_espeak_mbrola, ("mb/mb-de4-en", "de4",)),
          'emb_de5-en': (_espeak_mbrola, ("mb/mb-de5-en", "de5",)),
          'emb_fr1-en': (_espeak_mbrola, ("mb/mb-fr1-en", "fr1",)),
          'emb_fr4-en': (_espeak_mbrola, ("mb/mb-fr4-en", "fr4",)),
          'emb_hu1-en': (_espeak_mbrola, ("mb/mb-hu1-en", "hu1",)),
          'emb_nl2-en': (_espeak_mbrola, ("mb/mb-nl2-en", "nl2",)),
          'emb_pl1-en': (_espeak_mbrola, ("mb/mb-pl1-en", "pl1",)),
          'emb_ro1-en': (_espeak_mbrola, ("mb/mb-ro1-en", "ro1",)),
          'emb_sw1-en': (_espeak_mbrola, ("mb/mb-sw1-en", "sw1",)),
          'emb_sw2-en': (_espeak_mbrola, ("mb/mb-sw2-en", "sw2",)),
	  'emb_br3': (_espeak_mbrola, ("mb/mb-br3", "br3",)),
          'emb_de7': (_espeak_mbrola, ("mb/mb-de7", "de7",)),
	  'emb_de6': (_espeak_mbrola, ("mb/mb-de6", "de6",)),
          'emb_en1': (_espeak_mbrola, ("mb/mb-en1", "en1",)),
          'emb_fr1': (_espeak_mbrola, ("mb/mb-fr1", "fr1",)),
          'emb_fr4': (_espeak_mbrola, ("mb/mb-fr4", "fr4",)),
          'emb_hu1': (_espeak_mbrola, ("mb/mb-hu1", "hu1",)),
	  'emb_it4': (_espeak_mbrola, ("mb/mb-it4", "it4",)),
	  'emb_la1': (_espeak_mbrola, ("mb/mb-la1", "la1",)),
          'emb_nl2': (_espeak_mbrola, ("mb/mb-nl2", "nl2",)),
          'emb_pl1': (_espeak_mbrola, ("mb/mb-pl1", "pl1",)),
	  'emb_gr2': (_espeak_mbrola, ("mb/mb-gr2", "gr2",)),
          'emb_ro1': (_espeak_mbrola, ("mb/mb-ro1", "ro1",)),
          'emb_sw1': (_espeak_mbrola, ("mb/mb-sw1", "sw1",)),
          'emb_sw2': (_espeak_mbrola, ("mb/mb-sw2", "sw2",)),
          'emb_af1': (_espeak_mbrola, ("mb/mb-af1", "af1",)),
          'emb_cr1': (_espeak_mbrola, ("mb/mb-cr1", "cr1",)),
          'emb_cz2': (_espeak_mbrola, ("mb/mb-cz2", "cz2",)),
	  'emb_ro1': (_espeak_mbrola, ("mb/mb-ro1", "ro1",)),
          'emb_de4': (_espeak_mbrola, ("mb/mb-de4", "de4",)),
          'emb_de5': (_espeak_mbrola, ("mb/mb-de5", "de5",)),
          'emb_us1': (_espeak_mbrola, ("mb/mb-us1", "us1",)),
          'emb_us2': (_espeak_mbrola, ("mb/mb-us2", "us2",)),
          'emb_en1-high': (_espeak_mbrola, ("mb/mb-en1", "en1", '', ' -f1.4 ',)),
          'emb_us2-slow': (_espeak_mbrola, ("mb/mb-us2", "us2", '', ' -t1.5 ',)),
          'emb_us1-slow': (_espeak_mbrola, ("mb/mb-us1", "us1", '', ' -t1.6 ',)),
          'emb_sw1-en-fast': (_espeak_mbrola, ("mb/mb-sw1-en", "sw1", '', ' -t 0.75 ' )),
          'emb_hu1-en-slow': (_espeak_mbrola, ("mb/mb-hu1-en", "hu1", '', ' -t1.4 ')),
          'emb_fr1-en-low': (_espeak_mbrola, ("mb/mb-fr1-en", "fr1", '', ' -t1.1 -f0.6 ')),
          'emb_pl1-en-low-slow': (_espeak_mbrola, ("mb/mb-pl1-en", "pl1", '', ' -t1.4 -f0.7 ')),
          'emb_fr4-en-high-slow': (_espeak_mbrola, ("mb/mb-fr4-en", "fr4", '', ' -t1.4 -f1.7 ' )),
          'emb_de4-en-low-slow': (_espeak_mbrola, ("mb/mb-de4-en", "de4", '', ' -t1.4 -f0.6 ' )),
          'emb_sw1-en-low-slow': (_espeak_mbrola, ("mb/mb-sw1-en", "sw1", '', ' -t1.4 -f0.6 ' )),
          'emb_de5-en-high-slow': (_espeak_mbrola, ("mb/mb-de5-en", "de5", '', ' -t1.4 -f1.3 ' )),
          'emb_sw2-en-high-slow': (_espeak_mbrola, ("mb/mb-sw2-en", "sw2", '', ' -t1.4 -f1.3 ' )),
           #'emb_us3': (_espeak_mbrola, ("mb/mb-us3", "us3",)),
         }


def regenerate_voices():
    """generate the shell scripts that make the voices.  These are put
    in the config.VOICE_SCRIPT_DIR directory, which at the time of
    writing is ./config/voices.  The upstage.speak modules calls these
    directly."""
    voices = {}
    for voice, x in VOICE_KIT.iteritems():
        fn, args = x
        commands = fn(*args)
        if commands is None:
            print "WARNING: can't find stuff for voice %s" % voice
            continue
        filename = os.path.join(config.VOICE_SCRIPT_DIR, voice + '.sh')
        #just to check against ../.. etc
        if os.path.dirname(filename) != config.VOICE_SCRIPT_DIR:
            print "something DEVIOUS may be happening:"\
                  " a voice is called %s which ends up at %s" % (voice, filename)
            continue
        cmd = ';\n'.join(commands)
        f = open(filename, 'w')
        f.write("#!/bin/sh\n#automatically generated. think before editing.\n")
        f.write(cmd)
        f.close()
        os.chmod(filename, 0755)
        voices[voice] = filename
    return voices

def recall_voices():
    """Rather than regenerating the voice scripts, read the contents
    of the directory.  This should be slightly faster, and will
    preserve any hand tuning that has been done to those scripts, and
    pick up voices that have been manually added.  Added voices should
    respond to a command like this:

    echo 'hello' | your_voice_script target.mp3

    by saving the sound of 'hello' as an mp3 in target.mp3.
    """
    d = config.VOICE_SCRIPT_DIR
    return dict([(x, os.path.join(d, x)) for x in os.listdir(d)])


if config.REGENERATE_VOICE_SCRIPTS:
    VOICES = regenerate_voices()
else:
    VOICES = recall_voices()


    
