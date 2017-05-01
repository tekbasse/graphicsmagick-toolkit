#gmtk-procs.tcl
ad_library {

    GraphicsMagick Toolkit routines require TclMagick
    @creation-date 13 Feb 2016
    @cvs-id $Id:
    @Copyright (c) 2016 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/graphicsmagick-toolkit
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com

    Temporary comment about git commit comments: http://xkcd.com/1296/
}

namespace eval gmtk {}

# first cases are ported from mad-lab-lib https://github.com/tekbasse/mad-lab-lib.git

ad_proc -public gmtk::draw_path {
    drawName
    x_y_lists 
} {
    Draw a path of line segments. Renders list of x_y coordinates as a sequence of connected points.
    List of points may be a simple sequence list x1 y1 x2 y2 x3 y3... or can be a list of lists: list list x1 y1 list x2 y2 list x3 y3..
    If a list of lists, the first list can be a label with 'x' or 'y' to indicate which index is x and y.
    If no labels, x is assumed index 0, y is assumed index 1. Returns 0 if there are no points drawn.
} {
    upvar 1 $drawName drawName
    set x_y_l_len [llength $x_y_lists]
    set point_count $x_y_l_len
    set row0_list [lindex $x_y_lists 0]
    set lol_p 0
    set success_p 1
    if { [llength $row0_list] > 1 } {
	# x_y_lists is a list of lists
	set lol_p 1
	# defaults
	set x_idx 0
	set y_idx 1
	set sx_idx [lsearch -exact $row0_list "x"]
	if { $sx_idx > -1 } {
	    # first row contains labels
	    incr point_count -1
	    set x_y_lists [lrange $x_y_lists 1 end]
	    set sy_idx [lsearch -exact $row0_list "y"]
	    if { $sy_idx > -1 } {
		# first row has qualifying labels
		set x_idx $sx_idx
		set y_idx $sy_idx
	    }
	}
	set x0y0_list [lindex $x_y_lists 0]
	set x [lindex $x0y0_list $x_idx]
	set y [lindex $x0y0_list $y_idx]
	if { $point_count > 0 } {
	    if { $point_count > 1 } {
		set x_prev $x 
		set y_prev $y
		foreach xy_list $x_y_lists {
		    set x [lindex $xy_list $x_idx]
		    set y [lindex $xy_list $y_idx]
		    $drawName line $x $y
		    set x_prev $x 
		    set y_prev $y
		}
	    } else {
		# path is a point
		$drawName line $x $y $x $y
	    }
	} else {
	    set success_p 0
	}

    } else {
	# xy_lists is a one sequence of x and y's
	set point_count [expr { $point_count / 2 } ]
	set x [lindex $x_y_lists 0]
	set y [lindex $x_y_lists 1]
	if { $point_count > 0 } {
	    if { $point_count > 1 } {
		set x_prev $x 
		set y_prev $y
		foreach {x y} $x_y_lists {
		    $drawName line $x $y
		    set x_prev $x 
		    set y_prev $y
		}
	    } else {
		# path is a point
		$drawName line $x $y $x $y
	    }
	} else {
	    set success_p 0
	}
    }
    return $success_p
}

ad_proc gmtk::image_width_height { 
    filepathname 
} {
    returns the width and height in pixels of filename as a list: width, height.
} {
    # original from OpenACS photo-album pa_image_width_height
    set identify_string [exec gm identify $filepathname]
    regexp {[ ]+([0-9]+)[x]([0-9]+)[\+]*} $identify_string x width height
    return [list $width $height]
}




ad_proc gmtk::graph_lol { 
    filename 
    region 
    data_lists
    x_index 
    y_index 
    x_style 
    y_style 
    x_ticks_count 
    y_ticks_count 
    x_title 
    y_title
    {type "lin-lin"} 
} {
    # this proc is from mad-lab-lib. It is unported. It will get ported when a simple graph is needed.

    # if x_index or y_index is a list: 
    # 1 element in list: index
    # 2 elements in list: index, error (index value +/- this value)
    # 3 elements in list: index, low_error, high_error
    
    set time_start [clock seconds]
    # type: lin-lin lin-log log-lin log-log
    # filename: if doesn't exist, is created
    # region is box in filename defined by X1,Y1xX2,Y2 separated by commas or x thereby converted to list of 4 numbers
    # index is index number of list in lists of lists
    # style is of type bars (chart1), scatterplot (chart3), trendblock(chart2)

    # ..............................................................
    # Graph results.
    if { $filename eq "" } {
        set timestamp [clock format [clock seconds] -format "%Y%m%dT%H%M%S"]
        set filename "~/${timestamp}.png"
    }
    # Extract data and statistics 
    # ordered elements
    set xo_list [list ]
    set yo_list [list ]
    set pxy_lists [list ]
    set pxxm_lists [list ]
    set pyym_lists [list ]
    # Determine x_index_type and y_index_type
    if { [llength $x_index] > 1 } {
        set x3_index [lindex $x_index 2]
        set x2_index [lindex $x_index 1]
        set x1_index [lindex $x_index 0]
    } else {
        set x1_index $x_index
    }
    if { [info exists x3_index] } {
        if { $x3_index ne "" } {
            # separate full value ranges for x value high and low
            set x_index_type 3
        } elseif { $x2_index ne "" } {
            # use a single relative value for calculating x error (+/-)
            set x_index_type 2
        }
    } else {
        set x_index_type 1
    }
    if { [llength $y_index] > 1 } {
        set y3_index [lindex $y_index 2]
        set y2_index [lindex $y_index 1]
        set y1_index [lindex $y_index 0]
    } else {
        set y1_index $y_index
    }
    if { [info exists y3_index] } {
        if { $y3_index ne "" } {
            # separate full value ranges for y value high and low
            set y_index_type 3
        } elseif { $y2_index ne "" } {
            # use a single relative value for calculating x error (+/-)
            set y_index_type 2
        }
    } else {
        set y_index_type 1
    }
    # Extract and prepare datapoints from data_list_of_lists
    set ximin ""
    set ximax ""
    set yimin ""
    set yimax ""
    set first_dp_list [lindex $data_lists 0] 
    set x1_index_ck [regexp {[^0-9]+} [lindex $first_dp_list $x1_index] scratch]
    set x2_index_ck [regexp {[^0-9]+} [lindex $first_dp_list $x2_index] scratch]
    if { $x1_index_ck || $y1_index_ck } {
        # drop first row as a title row
        set di 1
    } else {
        set di 0
    }
    foreach dp_list [lrange $data_lists $di end] {
        set xi [lindex $dp_list $x1_index]
        lappend xo_list $xi
        switch -exact $x_index_type {
            2 {
                set xii [lindex $dp_list $x2_index]
                set ximin [expr { $xi - $xii } ]
                set ximax [expr { $xi + $xii } ]
                lappend xomin_list $ximin
                lappend xomax_list $ximax
            }
            3 {
                set ximin [lindex $dp_list $x2_index]
                set ximax [lindex $dp_list $x3_index]
                lappend xomin_list $ximin
                lappend xomax_list $ximax
            }
        }
        set pxx [list $ximin $ximax]
        lappend pxxm_lists $pxx
        set yi [lindex $dp_list $y1_index]
        lappend yo_list $yi
        switch -exact $y_index_type {
            2 {
                set yii [lindex $dp_list $y2_index]
                set yimin [expr { $yi - $yii } ]
                set yimax [expr { $yi + $yii } ]
                lappend yomin_list $yimin
                lappend yomax_list $yimax
            }
            3 {
                set yimin [lindex $dp_list $y2_index]
                set yimax [lindex $dp_list $y3_index]
                lappend yomin_list $yimin
                lappend yomax_list $yimax
            }
        }
        set pyy [list $yimin $yimax]
        lappend pyym_lists $pyy

        set pxy [list $xi $yi]
        lappend pxy_lists $pxy
    }

    set pcount [llength $pxy_lists]
    set x_graph_type [string range $type 0 2]
    set y_graph_type [string range $type 4 6]

    set xox_list [lsort -real $xo_list]
    set fx_min [lindex $xox_list 0]
    set fx_max [lindex $xox_list end]
 
    if { $x_index_type > 1 } {
        # determin max and mins from calculated min and calculated max
        set xoxmin_list [lsort -real $xomin_list]
        set fx2_min [lindex $xoxmin_list 0]
        set xoxmax_list [lsort -real $xomax_list]
        set fx2_max [lindex $xoxmax_list end]
        if { $fx2_min < $fx_min } {
            set fx_min $fx2_min
        } else {
            ns_log Notice  "gmtk::graph_lol(324): Why isn't fx2_min $fx2_min less than fx_min $fx_min ?"
        }
        if { $fx2_max > $fx_max } {
            set fx_max $fx2_max
        } else {
            ns_log Notice  "gmtk::graph_lol(327): Why isn't fx2_max $fx2_max greater than fx_max $fx_max ?"
        }
    }

    set yox_list [lsort -real $yo_list]
    set fy_min [lindex $yox_list 0]
    set fy_max [lindex $yox_list end]
    if { $y_index_type > 1 } {
        # determin max and mins from calculated min and calculated max
        set yoxmin_list [lsort -real $yomin_list]
        set fy2_min [lindex $yoxmin_list 0]
        set yoxmax_list [lsort -real $yomax_list]
        set fy2_max [lindex $yoxmax_list end]
        if { $fy2_min < $fy_min } {
            set fy_min $fy2_min
        } else {
            ns_log Notice  "gmtk::graph_lol(343): Why isn't fy2_min $fy2_min less than fy_min $fy_min ?"
        }
        if { $fy2_max > $fy_max } {
            set fy_max $fy2_max
        } else {
            ns_log Notice  "gmtk::graph_lol(348): Why isn't fy2_max $fy2_max greater than fy_max $fy_max ?"
        }
    }

    set fx_range [expr { $fx_max - $fx_min } ]
    set fy_range [expr { $fy_max - $fy_min } ]
#ns_log Notice  "fx_min $fx_min fx_max $fx_max fx_range $fx_range fy_min $fy_min fy_max $fy_max fy_range $fy_range"
    # Determine plot region
    set region_list [split $region ",: x"]    
    if { [llength $region_list] == 4 } {
        if { [lindex $region_list 0] < [lindex $region_list 2] } {
            set x1 [lindex $region_list 0]
            set y1 [lindex $region_list 1]
            set x2 [lindex $region_list 2]
            set y2 [lindex $region_list 3]
        } else {
            set x2 [lindex $region_list 0]
            set y2 [lindex $region_list 1]
            set x1 [lindex $region_list 2]
            set y1 [lindex $region_list 3]
        }
        if { $y2 < $y1 } {
            set y $y1
            set y1 $y2
            set y2 $y
        }
    } else {
        # create a plot region
        set margin 70
        set x1 $margin
        set y1 $margin
        if { [llength $region_list] > 0 } {
            # work with available inns_log Notice 
            set region_list [lsort -real $region_list]
            set x2 [lindex $region_list end] 
            set y2 $x2
        } else {
            # about a standard page size
            set x2 [expr { round( int( 1000. / $pcount ) * $pcount + ( $margin ) ) } ]
            set y2 [expr { round( int( 1400. / $pcount ) * $pcount + ( $margin ) ) } ]
        }
    }

    if { ![file exists $filename] } {
        # Create canvas image
        # to create a solid red canvas image:
        # gm convert -size 640x480 "xc:#f00" canvas.png
        # from: www.graphicsmagick.org/FAQ.html

        # Assume the same border for the farsides. It may be easier for a user to clip than to add margin.
        set width_px [expr { $x2 + 2 * $x1 } ]
        set height_px [expr { $y2 + 2 * $y1 } ]
        ns_log Notice  "gmtk::graph_lol.376: Creating ${width_px}x${height_px} image: $filename"
        exec gm convert -size ${width_px}x${height_px} "xc:#ffffff" $filename
    }

    # ..............................................................
    # Determine charting constants
    set x_delta [expr { $x2 - $x1 } ]
    set y_delta [expr { $y2 - $y1 } ]
    
    # statistics of data for plot transformations
    # fx_min, fx_max, fx_range
    # fy_min, fy_max, fy_range
    
    # ..............................................................
    # Create chart grid
    if { $x_ticks_count > -1 } {
        incr x_ticks_count -1
    }
    if { $y_ticks_count > -1 } {
        incr y_ticks_count -1
    }

    # Add an x or y origin line?
    if {  [string match "*origin*" $x_style] } {
        set x_0 [expr { round( $x1 + $x_delta * ( 0 - $fx_min ) / $fx_range ) } ]
        gmtk::draw_image_path_color $filename [list $x_0 $y1 $x_0 $y2] "#eeeeee"
    }
    if { [string match "*origin*" $y_style] } {
        set y_0 [expr { round( $y2 - $y_delta * ( 0 - $fy_min ) / $fy_range ) } ]
        gmtk::draw_image_path_color $filename [list $x1 $y_0 $x2 $y_0] "#eeeeee"
    }


    # x axis
    gmtk::draw_image_path_color $filename [list $x1 $y2 $x2 $y2] "#ccccff"
    # x axis ticks
    set y_tick [expr { $y2 + 4 } ]
    set k1 [expr { $x_delta / ( $x_ticks_count * 1. ) } ]
    for {set i 0} {$i <= $x_ticks_count } {incr i} {
        set x_plot [expr { round( $x1 + $k1 * ( $i * 1. ) ) } ]
        gmtk::draw_image_path_color $filename [list $x_plot $y2 $x_plot $y_tick] "#ccccff"
    }
    if { ![info exists width_px ] } {
        set width_px [lindex [gmtk::image_width_height $filename] 0]
    }
    # Rotate image, plot values for x-axis ticks
    exec gm convert -rotate 270 $filename $filename
    # swap x and y coordinates, since rotated by 90 degrees.
    set y_tick [expr { $y2 + 6 } ]
    set k2 [expr { $fx_range / ( $x_ticks_count * 1. ) } ]
    set x2_margin [expr { $width_px - $x2 } ]
    for {set i 0} {$i <= $x_ticks_count } {incr i} {
        set x_plot [expr { round( $x2_margin + ( $i * 1. ) * $k1 ) } ]
        set x [expr { $fx_max - $k2 * ( $i * 1. ) } ]
        gmtk::annotate_image_pos_color $filename $y_tick $x_plot "#aaaaff" [gmtk::pretty_metric $x "" 2 "c d da h"]
    }
    # rotate back.
    exec gm convert -rotate 90 $filename $filename

    # y axis, left side
    gmtk::draw_image_path_color $filename [list $x1 $y1 $x1 $y2] "#ffaaaa"
    # y axis ticks
    set x_tick [expr { $x1 - 40 } ]
    if { $x_tick < 0 } {
        set x_tick 1
    }
    set k1 [expr { $y_delta / ( 1. * $y_ticks_count ) } ]
    set k2 [expr { $fy_range / ( $y_ticks_count * 1. ) } ]
    for {set i 0} {$i <= $y_ticks_count } {incr i} {
        set y_plot [expr { round( $y2 - $k1 * $i ) } ] 
        gmtk::draw_image_path_color $filename [list $x1 $y_plot $x_tick $y_plot] "#ffaaaa"
        # add label
        set y_tick [expr { $y_plot - 6 } ]
        set y [expr { $k2 * ( $i * 1. ) + $fy_min } ]
        gmtk::annotate_image_pos_color $filename $x_tick $y_tick "#ffaaaa" "[gmtk::pretty_metric $y "" 2 "c d da h"]"
    }


    # ..............................................................
    # background 
    set i 0
    foreach p_x_y $pxy_lists {
        if { $x_index_type > 1 } {
            set yval [lindex $p_x_y 1]            
            set y [expr { round( $y2 - $y_delta * ( $yval - $fy_min ) / $fy_range ) } ] 
            set pxx [lindex $pxxm_lists $i] 
            set x_min [lindex $pxx 0]
            set x_max [lindex $pxx 1]
            set x [lindex $p_x_y 0]
            if { $x_min < $x && $x < $x_max } {
                # plot x min to max @ y
                set x_min [expr { round( $x1 + $x_delta * ( $x_min - $fx_min ) / $fx_range ) } ]
                set x_max [expr { round( $x1 + $x_delta * ( $x_max - $fx_min ) / $fx_range ) } ]
                gmtk::draw_image_path_color $filename [list $x_min $y $x_max $y] "#99ccff"
            } else {
                ns_log Notice  "gmtk::graph_lol.471: Warning: x_min $x_min < x $x < x_max $x_max"
            }
        }
        if { $y_index_type > 1 } {
            set xval [lindex $p_x_y 0]
            set x [expr { round( $x1 + $x_delta * ( $xval - $fx_min ) / $fx_range ) } ]
            set pyy [lindex $pyym_lists $i] 
            set y_min [lindex $pyy 0]
            set y_max [lindex $pyy 1]
            set y_min [expr { round( $y2 - $y_delta * ( $y_min - $fy_min ) / $fy_range ) } ] 
            set y_max [expr { round( $y2 - $y_delta * ( $y_max - $fy_min ) / $fy_range ) } ] 
            # plot y min to max @ x
            gmtk::draw_image_path_color $filename [list $x $y_min $x $y_max] "#ffcc99"
        }
        incr i
    }

    # Titles
    set y_plot [expr  { $y1 - 20 } ]
    if { $y_plot < 0 } {
        set y_plot 1
    }
    gmtk::annotate_image_pos_color $filename [expr { round( ( $x1 + $x2 - [string length $y_title] * 12 ) / 2. ) } ] [expr { $y_plot } ] "#ff0000" $y_title
    gmtk::annotate_image_pos_color $filename [expr { round( ( $x1 + $x2 - [string length $x_title] * 12 ) / 2. ) } ] [expr { $y_plot + 20 } ] "#0000ff" $x_title

    # foreground
    foreach p_x_y $pxy_lists {
        set xval [lindex $p_x_y 0]
        set yval [lindex $p_x_y 1]
        set x [expr { round( $x1 + $x_delta * ( $xval - $fx_min ) / $fx_range ) } ]
        set y [expr { round( $y2 - $y_delta * ( $yval - $fy_min ) / $fy_range ) } ] 
        # plot x, y
        gmtk::draw_image_path_color $filename [list $x $y] "#ff00ff"
    }

    set time_end [clock seconds]
    set time_elapsed [expr { ( $time_end - $time_start ) } ]
    ns_log Notice  "gmtk::graph_lol.508: Time elapsed: ${time_elapsed} seconds."
}
