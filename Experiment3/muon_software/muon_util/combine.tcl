#!/bin/sh
#	
####################################################
#
#        MATPHYS  4/3/2008
#
####################################################
#
#\
exec wish "$0" "$@"

set font {Helvetica 10}


wm title . "Muon lifetime data file merge"

frame .buttons
pack .buttons -side bottom -fill x -pady 2m
button .buttons.dismiss -text Dismiss -command "destroy ."
button .buttons.code -text "Merge 2 files" -command {
    set infile1  [.input1.ent get]
    set infile2  [.input2.ent get]
    set savefile  [.save.ent get]
    if { $infile1 != "" && $infile2 != "" && $savefile != "" } { combinfiles $infile1 $infile2 $savefile }
					 }
pack .buttons.dismiss .buttons.code -side left -expand 1

foreach i {input1 input2 save} {
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



proc combinfiles { infile1 infile2 savefile } {

    set fp1 [open $infile1 r]
    set fp2 [open $infile2 r]
    set fp3 [open $savefile w]
    set data1 [gets $fp1]
    set data2 [gets $fp2]
    
	while { ![eof $fp1] && ![eof $fp2] } {
	    
	    set dtime1 [lindex $data1 0]
	    set times1 [lindex $data1 1]
	    set dtime2 [lindex $data2 0]
	    set times2 [lindex $data2 1]
	    
	    if { $times1 <= $times2 } {
		puts $fp3 $data1
		set data1 [gets $fp1]
		
	    } else {
		puts $fp3 $data2
		set data2 [gets $fp2]
		
	    }
	    
	}
    
    
	

    if { [eof $fp1] } {
	while { ![eof $fp2] } {
	    
	    set data2 [gets $fp2]
	    puts $fp3 $data2
	}
    }


    if { [eof $fp2] } {
	while { ![eof $fp1] } {
                
	    set data1 [gets $fp1]
	    puts $fp3 $data1
	}       
    }       
                

}


