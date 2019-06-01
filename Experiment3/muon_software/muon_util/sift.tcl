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


wm title . "Muon lifetime data file merge"

frame .buttons
pack .buttons -side bottom -fill x -pady 2m
button .buttons.dismiss -text Dismiss -command exit
button .buttons.code -text "Dump decay data" -command {
    set infile  [.input.ent get]
    set savefile  [.save.ent get]
    if { $infile != "" && $savefile != "" } { dumpdata $infile $savefile }
					 }
pack .buttons.dismiss .buttons.code -side left -expand 1

foreach i {input save} {
    set f [frame .$i]
    label $f.lab -text "Select a file to $i: " -anchor e
    entry $f.ent -width 20
    button $f.but -text "Browse ..." -command "fileDialog . $f.ent $i"
    pack $f.lab -side left
    pack $f.ent -side left -expand yes -fill x
    pack $f.but -side left
    pack $f -fill x -padx 1c -pady 3
}


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



proc dumpdata { infile savefile } {

    set fp1 [open $infile r]
    set fp2 [open $savefile w]
    
    while { ![eof $fp1] } {
	set data1 [gets $fp1]

	if { [lindex $data1 0] < 40000 } {
	    puts $fp2 $data1
	}
	
    }
    flush $fp2

}       
                


