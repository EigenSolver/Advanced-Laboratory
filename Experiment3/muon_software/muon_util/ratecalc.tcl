#!/bin/sh
#	
####################################################
#
# MATPHYS Dec. 10, 2003
#
####################################################
#
#\
exec wish "$0" "$@"

set font {Helvetica 10}


wm title . "Muon rate calculator"

frame .buttons
pack .buttons -side bottom -fill x -pady 2m
button .buttons.dismiss -text Dismiss -command exit
button .buttons.code -text "Calculate" -command {
    set infile  [.input.ent get]
    if { $infile != "" } { 
	ratedata $infile 
	set rate "[format %2.2f [expr $rate/$count]] +/- [format %2.2f [expr sqrt($rate)/$count]]"
	set drate "[format %2.2f [expr 60 * $drate/$count]] +/- [format %2.2f [expr 60 * sqrt($drate)/$count]]"
	set numinput $count
    }
}


pack .buttons.dismiss .buttons.code -side left -expand 1

foreach i {input } {
    set f [frame .$i]
    label $f.lab -text "Select a file to $i: " -anchor e -width 22
    entry $f.ent -width 20
    button $f.but -text "Browse ..." -command "fileDialog . $f.ent $i"
    pack $f.lab -side left
    pack $f.ent -side left -expand yes -fill x
    pack $f.but -side left
    pack $f -fill x -padx 1c -pady 3
}

set numinput 1000
frame .numinput
label .numinput.label -text "Number of records" -width 22

entry .numinput.entry -textvariable numinput -width 20
pack .numinput.label .numinput.entry -side left
pack .numinput -side top -fill x -padx 1c -pady 3

frame .output1
label .output1.label -text "Muon rate per sec" -width 22
entry .output1.entry -textvariable rate -width 20
pack .output1.label .output1.entry -side left
frame .output2
label .output2.label -text "Muon decay rate per min" -width 22
entry .output2.entry -textvariable drate -width 20
pack .output2.label .output2.entry -side left

pack .output1 .output2 -side top -fill x -padx 1c -pady 3


proc fileDialog {w ent operation} {
    #   Type names              Extension(s)    Mac File Type(s)
    #
    #---------------------------------------------------------
    set types {
        {"Data files"           {.data}     }
        {"All files"            *}
    }
    if {$operation != "save"} {
        set file [tk_getOpenFile -filetypes $types -parent $w]
    } else {
        set file [tk_getSaveFile -filetypes $types -parent $w \
            -initialfile Untitled -defaultextension .txt]
    }
    if {[string compare $file ""]} {
        $ent delete 0 end
        $ent insert 0 $file
        $ent xview end
    }
}



proc ratedata { infile  } {
    global numinput rate drate count
    
    set fp1 [open $infile r]
    set count 0
    set drate 0
    set rate 0
    while { ![eof $fp1] && $count <= $numinput } {
	set data1 [gets $fp1]

	if { [lindex $data1 0] < 40000 } {
	    incr drate
      	} else {
	    incr rate [expr [lindex $data1 0] -40000]
	    incr count
	}

    }
    
}       
                


