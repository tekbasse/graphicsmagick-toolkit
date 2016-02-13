#gmtk-procs.tcl
ad_library {

    GraphicsMagick Toolkit routines require TclMagick
    @creation-date 13 Feb 2016
    @cvs-id $Id:
    @Copyright (c) 2016 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/graphicsmagick-toolkit
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    Temporary comment about git commit comments: http://xkcd.com/1296/
}

namespace eval gmtk {}

ad_proc -private gmtk::ex {
    factor_curve_lol
} {
    Returns laughter and fun
} {
    return $laughter_and_fun
}
