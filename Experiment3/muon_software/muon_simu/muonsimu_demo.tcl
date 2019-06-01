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
load img12.dll


proc X2cacl { BB KK } {
    global y  width bins timescale
    
    set X2 0.0
    for {set VAL 0} {$VAL < $bins} {incr VAL} {
	set VAR [expr  (($VAL+0.5)*$width*$timescale)/$KK/600.]
	set X2 [expr $X2 + ($BB *exp( -$VAR)-$y($VAL))*($BB *exp( -$VAR)-$y($VAL)) ]
	
    }

    return $X2
}


proc timeprint { second } {

set H [expr $second / 3600 ]
set M [expr $second / 60 - $H * 60 ]
set S [expr $second - $H * 3600 - $M * 60 ]

return "$H:$M:$S"

}



#
# Begin to defint
#

set Font1 {Times 16}
set Font2 {Times 14}
set Font3 {Times 12}
set Font4 {Times 10}
set lifetime 2.2
set backg 0.05
set port "com0"
set readold 0
set timescale 20
set bins 20
set number 2000
set numdate 0
set time2 [clock format [clock scan now] -format %Y-%m-%d]
set time1 [clock format [expr [clock scan now] - 436800] -format %Y-%m-%d]
set counts 0
set STOP 1

set logl 0

set nmuon 0
set dmuon 0
set mrate 0
set drate 0
set eetime 0
set etime 0
set lastnmuon 0
set lastdmuon 0
set YAXIS 0.1

set thNumber 0

wm title . "Muon Lifetime Measurement"

frame .f1
frame .f2
frame .f2.1
frame .f2.2

labelframe .f2.1.1 -text "Control" -padx 2 -pady 2 -font $Font1
labelframe .f2.1.2 -text "Monitor" -padx 2 -pady 2 -font $Font1
labelframe .f2.1.3 -text "Rate Meter" -padx 2 -pady 2 -font $Font1

labelframe .f2.2.1 -text "Muon Decay Time Histogram" -padx 2 -pady 2 -font $Font1
labelframe .f2.2.2 -text "Muons through detector" -padx 2 -pady 2 -font $Font1

pack .f2.1.1 .f2.1.2 .f2.1.3 -side top -fill x
pack .f2.2.1 .f2.2.2 -side top

pack .f2.1 .f2.2 -side left
pack .f1 .f2 -side top

#
# Control buttons
#

button .f2.1.1.config -width 20 -text "Configure" -command { muonconfig } -font $Font2
button .f2.1.1.start -width 20 -text "Start" -command {

    set STIME [clock scan now]

    set message 0
    
    if {$message == 0 && [catch { expr $number * 1 }] == 1 } {
        tk_messageBox -message "The number you input: $number is not right"
        set message 1
    }
    
    if { $message == 0 && [ expr  $number < 200 ] == 1 } {
        tk_messageBox -message "Minimum event load is 200"
        set message 1
    }



    if { $message == 0 && [catch {clock scan $time1 }] == 1 } {
        tk_messageBox -message "From(Y-M-D): $time1 is not acceptable"
        set message 1
    }


    if { $message == 0 && [catch {clock scan $time2 }] == 1 } {
        tk_messageBox -message "To(Y-M-D): $time2 is not acceptable"
        set message 1
    }


    if { $message == 0 && [expr  [clock scan $time1] > [clock scan $time2] ] } {
        tk_messageBox -message "From: $time1 must eariler than To:$time2"
        set message 1
    }


        
    if { $message == 0 } {
        .f2.1.1.fitting config -state normal
        .f2.1.1.config config -state disabled
        


        
#
#       Set the new file name as the date. For example 2003-07-02-11-24.data
#
	set fpname [clock format [clock scan now] -format %y-%m-%d-%H-%M].data
	set fpmuon [open $fpname a+]
	fconfigure $fpmuon  -encoding binary -translation binary
	.f2.1.1.start config -state disabled
	set width [expr 600 /$bins ]
	set STOP 0
	muonrate
	after 60000 decayrate
	after 100 LoadOldData

	after 1000 readport
#	after 2000 setyaxis

        after 2000 Updateth

#	LoadOldData
	
         
    }
    
    

}  -font $Font2

button .f2.1.1.pause -width 20 -text "Pause" -command { set STOP [expr 1 -$STOP] ;\
       if { $STOP == 1 } {.f2.1.1.pause config -text "Resume" } else {.f2.1.1.pause config -text "Pause" };
       .f2.1.1.fitting config -state normal }  -font $Font2
button .f2.1.1.fitting -width 20 -text "Fit" -state disabled -command { muonfit ; .f2.1.1.fitting config -state normal }  -font $Font2
button .f2.1.1.viewraw -width 20 -text "View Raw Data" -command { viewraw }  -font $Font2

button .f2.1.1.quit -width 20 -text "Quit" -command { saveornot } -background red -fg white -font $Font2

pack .f2.1.1.config .f2.1.1.start .f2.1.1.pause .f2.1.1.fitting .f2.1.1.viewraw .f2.1.1.quit -pady 5 -padx 2


#
# Monitor labels
#

label .f2.1.2.label1 -text "This measurement"  -font $Font2
set Font {Times 12}
frame .f2.1.2.frame1
frame .f2.1.2.frame1.1
frame .f2.1.2.frame1.2

label .f2.1.2.frame1.1.label0 -text "Elapsed Time" -font $Font3
label .f2.1.2.frame1.1.label1 -text "Number of Muons" -font $Font3
label .f2.1.2.frame1.1.label2 -text "Muon Rate (per second)" -font $Font3
label .f2.1.2.frame1.1.label3 -text "Muon Decays" -font $Font3
label .f2.1.2.frame1.1.label4 -text "Decay Rate (per minute)" -font $Font3
pack .f2.1.2.frame1.1.label0 .f2.1.2.frame1.1.label1 .f2.1.2.frame1.1.label2 .f2.1.2.frame1.1.label3 .f2.1.2.frame1.1.label4 -side top -pady 5 -padx 2

label .f2.1.2.frame1.2.ent0 -width 10  -font $Font3  -textvariable etime
label .f2.1.2.frame1.2.ent1 -width 10  -font $Font3  -textvariable nmuon
label .f2.1.2.frame1.2.ent2 -width 10  -font $Font3  -textvariable mrate
label .f2.1.2.frame1.2.ent3 -width 10  -font $Font3  -textvariable dmuon
label .f2.1.2.frame1.2.ent4 -width 10  -font $Font3  -textvariable drate

pack .f2.1.2.frame1.2.ent0 .f2.1.2.frame1.2.ent1 .f2.1.2.frame1.2.ent2 .f2.1.2.frame1.2.ent3 .f2.1.2.frame1.2.ent4 -pady 5 -padx 2

pack .f2.1.2.label1 .f2.1.2.frame1 -side top
pack .f2.1.2.frame1.1 .f2.1.2.frame1.2 -side left

#
#    Meter here:
#

canvas .f2.1.3.can -width 230 -height 130
pack .f2.1.3.can
.f2.1.3.can create text 20 10 -text "Evt/s"
.f2.1.3.can create text 20 20 -text "20"
.f2.1.3.can create text 20 65 -text "10"
.f2.1.3.can create text 20 110 -text "0"
.f2.1.3.can create text 40 120 -text "-60 s"
.f2.1.3.can create text 120 120 -text "-30 s"
.f2.1.3.can create text 210 120 -text "Now"
.f2.1.3.can create rectangle 40 10 220 111 -fill green -outline green


#
# Decay histgram here:
#
frame .f2.2.1.frame1 -width 40
button .f2.2.1.frame1.logl -text "Change Y scale: Linear/Log" -command { set logl [expr 1 - $logl ] ;
.f2.2.1.can1 delete fit
.f2.2.1.can1 create text 580 40 -text "Total Events: $counts" -fill red -font {Times 14} -tag fit
if {[info exist K]} {
    .f2.2.1.can1 create text 580 70 -text "\u03c4 = [format %2.3f $K] \u00B1 [format %2.3f $sigma] \u03bcs" -fill red -font {Times 14} -tag fit
    
.f2.2.1.can1 create text 580 100 -text "Chi2 /D.O.F = [format %2.1f $kx2] /[expr $bins -2] " -fill red -font {Times 14} -tag fit
#.f2.2.1.can1 create text 518 93 -text "2" -fill red -font {Times 8} -tag fit
}

if {$logl == 0 } {
    set YAXIS [format %3.2f [expr ($y(0)+1)/200.]]
    .f2.2.1.frame1.lab config -text "Linear scale"
    .f2.2.1.can1 delete axis
    for { set I 0 } { $I <=10 } { incr I } {
	.f2.2.1.can1 create line 80 [expr 320 - $I*30] 85 [expr 320 - $I*30] -width 1 -tag axis
	.f2.2.1.can1 create text 60 [expr 320 - $I*30] -text [format %4.0f [expr $I * 30 *$YAXIS ]] -tag axis
	.f2.2.1.can1 create text [expr 80 + $I*60 ] 340 -text [format %2.2f [expr $I * $timescale /10.]] -tag axis
	.f2.2.1.can1 create line [expr 80 + $I*60] 320 [expr 80 + $I*60] 315 -width 1 -tag axis
    }
    
    
    
    .f2.2.1.can1 delete point
    for {set VAL 0} {$VAL < $bins} {incr VAL} {
	set yerror [expr sqrt($y($VAL))]
	.f2.2.1.can1 create line [expr 80 + $VAL*$width ] [expr 320 -$y($VAL)/$YAXIS]  \
		[expr 80 + $VAL*$width +$width ] [expr 320 -$y($VAL)/$YAXIS]  -fill red -width 1 -tag point
	.f2.2.1.can1 create line [expr 80 + $VAL*$width + $width /2 ] [expr 320 - ($y($VAL)-$yerror)/$YAXIS ] \
		[expr 80 + $VAL*$width + $width /2 ] [expr 320 - ($y($VAL) + $yerror)/$YAXIS ] -fill red -width 1 -tag point
	
    }
    
    
} else {
    set YAXIS [format %3.5f [expr log($y(0)+1.1)/240.]]
    .f2.2.1.frame1.lab config -text "Log scale"
    .f2.2.1.can1 delete axis
    for { set I 0 } { $I <=10 } { incr I } {
	.f2.2.1.can1 create line 80 [expr 320 - $I*30] 85 [expr 320 - $I*30] -width 1 -tag axis
	.f2.2.1.can1 create text 60 [expr 320 - $I*30] -text\
		[format %4.0f [expr exp($I * 30 *$YAXIS )]] -tag axis
	.f2.2.1.can1 create text [expr 80 + $I*60 ] 340 -text [format %2.2f [expr $I*$timescale /10.]] -tag axis
	.f2.2.1.can1 create line [expr 80 + $I*60] 320 [expr 80 + $I*60] 315 -width 1 -tag axis
    }
    
    
    
    .f2.2.1.can1 delete point
    for {set VAL 0} {$VAL < $bins} {incr VAL} {
	set yerror [expr sqrt($y($VAL))]
	.f2.2.1.can1 create line [expr 80 + $VAL*$width ] [expr 320 -log(1 + $y($VAL))/$YAXIS]  \
		[expr 80 + $VAL*$width +$width ] [expr 320 -log(1+$y($VAL))/$YAXIS]  -fill red -width 1 -tag point
	
	.f2.2.1.can1 create line [expr 80 + $VAL*$width + $width /2 ]\
		[expr 320 - log(1+ ($y($VAL)-$yerror))/$YAXIS ] \
		[expr 80 + $VAL*$width + $width /2 ] [expr 320 - log(1+($y($VAL) + $yerror))/$YAXIS ]\
		-fill red -width 1 -tag point
	
    }
    
}

update
} -state disabled

label .f2.2.1.frame1.lab -width 60
button .f2.2.1.frame1.snap -text "Screen capture" -command {

image create photo snap -format window -data .f2.2.1.can1
snap write snap1.gif -format gif -from 0 0 700 400
image create photo snap -format window -data .f2.2.2.can1
snap write snap2.gif -format gif -from 0 0 700 200

}
pack .f2.2.1.frame1.logl  .f2.2.1.frame1.lab .f2.2.1.frame1.snap -side left -expand 0

canvas .f2.2.1.can1 -width 700 -height 400

pack .f2.2.1.frame1 .f2.2.1.can1 -side top


#
# Though this detector
#

canvas .f2.2.2.can1 -width 700 -height 200 -background LightBlue2

pack .f2.2.2.can1


#
#
#  Histogram plot
#
#
.f2.2.1.can1 create rectangle 80 20 680 320 -fill white -tag box
.f2.2.1.can1 create rectangle 480 20 680 120 -fill LightBlue1 -tag box
.f2.2.1.can1 create text 22 12 -text "Evt/Bin"

for { set I 0 } { $I <=10 } { incr I } {
    .f2.2.1.can1 create text [expr 80 + $I*60 ] 340 -text [format %2.1f [expr $I*0.6]] -tag axis  
    .f2.2.1.can1 create line [expr 80 + $I*60] 320 [expr 80 + $I*60] 315 -width 1 -tag axis
    .f2.2.1.can1 create text 60 [expr 320 - $I*30] -text [expr $I * 30 ] -tag axis
    .f2.2.1.can1 create line 80 [expr 320 - $I*30] 85 [expr 320 - $I*30] -width 1 -tag axis
}

.f2.2.1.can1 create text 360 360 -text "Muon Decay Time (\u03bcsec)" -font $Font2 




proc muonconfig { } {

     global port readold timescale bins number time1 time2 Font3 numdate lifetime
     set readold 0
     set numdate 0
     set lifetime 2.2
     catch { destroy .config }
     toplevel .config
     wm title .config "Config"
     frame .config.1
     frame .config.2
     pack .config.1 .config.2 -side top
#
#    port select
#
     labelframe .config.1.1 -text " "  -font $Font3
     label .config.1.1.lab1 -text "Decay time (\u03bcsec)"
     scale .config.1.1.lifetime  -from 1.1 -to 4.1 -variable lifetime -orient horizontal -resolu .01
	label .config.1.1.lab0 -text " "
     label .config.1.1.lab2 -text "Background level"
     scale .config.1.1.backg  -from 0.01 -to 0.2 -variable backg -orient horizontal -resolu .001

     pack .config.1.1.lab1 .config.1.1.lifetime .config.1.1.lab0 .config.1.1.lab2 .config.1.1.backg -side top

#     foreach value { /dev/ttyS0 /dev/ttyS1 /dev/ttyS2 /dev/ttyS3  } {
#             radiobutton .config.1.1.$value -text "$value" -variable port -value $value -font $Font3
#             pack .config.1.1.$value
#     }

#
#    Time scale
#

     labelframe .config.1.2 -text "Histogram time scale"  -font $Font3
     foreach value { 3 6 12 20  } {
             radiobutton .config.1.2.$value -text "$value \u03bcsec" -variable timescale -value $value -font $Font3
             pack .config.1.2.$value
     }

#
#    Bin width
#

     labelframe .config.1.3 -text "Number of Bins" -font $Font3
     foreach value { 60 30 20 10 5 } {
             radiobutton .config.1.3.$value -text "$value " -variable bins -value $value -font $Font3
             pack .config.1.3.$value
     }
#
#    Read old data or not?
#

     pack .config.1.1 .config.1.2 .config.1.3 -side left -fill y

     proc ifEnableRead { w } {
	 foreach child [winfo children $w] {
	     if {$child == "$w.readold"} continue
	     if {$::readold} {
		 $child configure -state normal
	     } else {
		 $child configure -state disabled
	     }
	 }
     }

     proc ifEnableDate { w } {
	 foreach child [winfo children $w] {
	     if {$child == "$w.numdate"} continue
	     if {$::numdate} {
		 $child configure -state normal
	     } else {
		 $child configure -state disabled
	     }
	 }
     }




     labelframe .config.2.1 -padx 2 -pady 2
     checkbutton .config.2.1.readold -text "Read the old data" -variable readold -command\
	     { ifEnableRead .config.2.1 ; set numdate [expr 1 - $readold] ; ifEnableDate .config.2.2}
     .config.2.1 configure -labelwidget .config.2.1.readold
#     grid .config.2.1 -row 0 -column 1 -pady 2m -padx 2m


#
#    Readout label and entry
#

     label .config.2.1.lab1 -text "Number of Events" -state disabled
     entry .config.2.1.number -text "Number of event want read" -textvariable number -state disabled
     pack .config.2.1.lab1 .config.2.1.number -side top

#
#    Read from date
#

     labelframe .config.2.2 -padx 2 -pady 2
     checkbutton .config.2.2.numdate -text "Specify the date" -variable numdate -command\
	     { ifEnableDate .config.2.2; set readold [expr 1 - $numdate] ;ifEnableRead .config.2.1 }
     .config.2.2 configure -labelwidget .config.2.2.numdate


     label .config.2.2.lab1 -text "From:(Y-M-D) " -state disabled
     entry .config.2.2.ent1 -width 10 -textvariable time1 -state disabled

     label .config.2.2.lab2 -text "To:  (Y-M-D)" -state disabled
     entry .config.2.2.ent2 -width 10 -textvariable time2 -state disabled

     pack .config.2.2.lab1 .config.2.2.ent1 .config.2.2.lab2 .config.2.2.ent2  -side top




#
#    Set button
#
     button .config.2.set -text "Save&Exit" -background SteelBlue2 -command {\
	     catch { destroy .config } }
     pack .config.2.1 .config.2.2 .config.2.set -side left -fill y -fill x



}

proc muonstart { a } {
     global port timescale bins fpmuon STOP YAXIS y counts width K  B logl sigma kx2


     if {![info exist y ]} {
         for { set VAL 0 } { $VAL < $bins } {incr VAL 1 } {
         lappend alist [expr $VAL]
         lappend alist 0 }
         array set y $alist
	 .f2.2.1.frame1.logl config -state normal

     }


#     switch log/line
#
     if { $logl == 0 } {
	 if { $STOP != 1  && $a < [expr $timescale * 1000 ] && $bins > 0 } then {

#	 puts $fpmuon "$a [clock seconds]"
	     set a [expr  int( $a * $bins /$timescale /1000 ) ]
	     incr y($a)
	     if { $y($a) + [expr sqrt($y($a))] >= [expr 300 * $YAXIS] } { set YAXIS [expr $YAXIS * 2 ] }

	     incr counts

#          flush $fpmuon
#
#	Add the scale change part, and plot.
#

	     .f2.2.1.can1 delete fit

	     .f2.2.1.can1 create text 580 40 -text "Total Events: $counts" -fill red -font {Times 14} -tag fit
	     if {[info exist K]} {
		 .f2.2.1.can1 create text 580 70 -text "\u03c4 = [format %2.3f $K] \u00B1 [format %2.3f $sigma] \u03bcs" -fill red -font {Times 14} -tag fit
		 
.f2.2.1.can1 create text 580 100 -text "Chi2 /D.O.F = [format %2.1f $kx2] /[expr $bins -2] " -fill red -font {Times 14} -tag fit
#.f2.2.1.can1 create text 518 93 -text "2" -fill red -font {Times 8} -tag fit	     
}


	     .f2.2.1.can1 delete axis
             for { set I 0 } { $I <=10 } { incr I } {
                 .f2.2.1.can1 create line 80 [expr 320 - $I*30] 85 [expr 320 - $I*30] -width 1 -tag axis
                 .f2.2.1.can1 create text 60 [expr 320 - $I*30] -text [format %4.0f [expr $I * 30 *$YAXIS ]] -tag axis
                 .f2.2.1.can1 create text [expr 80 + $I*60 ] 340 -text [format %2.2f [expr $I * $timescale /10.]] -tag axis
                 .f2.2.1.can1 create line [expr 80 + $I*60] 320 [expr 80 + $I*60] 315 -width 1 -tag axis
             }
	     
	     
	     
	     .f2.2.1.can1 delete point
             for {set VAL 0} {$VAL < $bins} {incr VAL} {
		 set yerror [expr sqrt($y($VAL))]
		 .f2.2.1.can1 create line [expr 80 + $VAL*$width ] [expr 320 -$y($VAL)/$YAXIS]  \
			 [expr 80 + $VAL*$width +$width ] [expr 320 -$y($VAL)/$YAXIS]  -fill red -width 1 -tag point
		 .f2.2.1.can1 create line [expr 80 + $VAL*$width + $width /2 ] [expr 320 - ($y($VAL)-$yerror)/$YAXIS ] \
			 [expr 80 + $VAL*$width + $width /2 ] [expr 320 - ($y($VAL) + $yerror)/$YAXIS ] -fill red -width 1 -tag point
		 
           }
	   


        }
        } else {
#
#
#       this is log scale
#


	    if { $STOP != 1  && $a < [expr $timescale * 1000 ] && $bins > 0 } then {

		set a [expr  int( $a * $bins /$timescale /1000 ) ]
		incr y($a)
		if { [expr log( 1 +$y($a) + [expr sqrt($y($a))])] >= [expr 300 * $YAXIS] } \
		    { set YAXIS [expr $YAXIS +0.00231  ] }
		
		incr counts

#
#	Add the scale change part, and plot.
#

                 
	    .f2.2.1.can1 delete fit
            .f2.2.1.can1 create text 580 40 -text "Total Events: $counts" -fill red -font {Times 14} -tag fit
             if {[info exist K]} {
             .f2.2.1.can1 create text 580 70 -text "\u03c4 = [format %2.3f $K] \u00B1 [format %2.3f $sigma] \u03bcs" -fill red -font {Times 14} -tag fit
.f2.2.1.can1 create text 580 100 -text "Chi2 /D.O.F = [format %2.1f $kx2] /[expr $bins -2] " -fill red -font {Times 14} -tag fit
#.f2.2.1.can1 create text 518 93 -text "2" -fill red -font {Times 8} -tag fit             
}




	     .f2.2.1.can1 delete axis
             for { set I 0 } { $I <=10 } { incr I } {
                 .f2.2.1.can1 create line 80 [expr 320 - $I*30] 85 [expr 320 - $I*30] -width 1 -tag axis
                 .f2.2.1.can1 create text 60 [expr 320 - $I*30] -text\
			 [format %4.0f [expr exp($I * 30 *$YAXIS )]] -tag axis
                 .f2.2.1.can1 create text [expr 80 + $I*60 ] 340 -text [format %2.2f [expr $I*$timescale /10.]] -tag axis
                 .f2.2.1.can1 create line [expr 80 + $I*60] 320 [expr 80 + $I*60] 315 -width 1 -tag axis
             }



	     .f2.2.1.can1 delete point
             for {set VAL 0} {$VAL < $bins} {incr VAL} {
		set yerror [expr sqrt($y($VAL))]
		.f2.2.1.can1 create line [expr 80 + $VAL*$width ] [expr 320 -log(1 + $y($VAL))/$YAXIS]  \
		[expr 80 + $VAL*$width +$width ] [expr 320 -log(1+$y($VAL))/$YAXIS]  -fill red -width 1 -tag point

		 .f2.2.1.can1 create line [expr 80 + $VAL*$width + $width /2 ]\
			[expr 320 - log(1+ ($y($VAL)-$yerror))/$YAXIS ] \
		[expr 80 + $VAL*$width + $width /2 ] [expr 320 - log(1+($y($VAL) + $yerror))/$YAXIS ]\
		-fill red -width 1 -tag point

           }



        }



        }

    update
}


proc readport { } {

    global  fpmuon nmuon dmuon STOP thNumber READ

#    set data [read $serial]  ;# read ALL incoming bytes
    set data [generate ]
    if {$STOP == 0} {


	regsub "\n" $data "" data
	set size [string length $data]      ;# number of received byte, may be 0

	if { $size } {
	    incr nmuon
	    incr thNumber
	    
	    if { ! [regexp -all "3E8" $data] } {
		set AA "0x$data"
		incr dmuon 1
		if { [catch {set AA [expr $AA * 20 ]}] } {
		} else {
		    if { $AA <= 20000 } {
			muonstart $AA
			puts $fpmuon "$AA [clock seconds]"
			if { $dmuon > 20 } {
				muonfit
			}
		    }
		}
	    }
	    update
	} 

    }


    after 50 { readport ; set READ 0 }
}


proc generate { } {
    global  fpmuon nmuon dmuon STOP thNumber lifetime backg
    if { [expr rand()] < $backg } {
	set Rand [format %0x [expr int( rand() * 10000 )] ]
	return $Rand
    } else {

	if { [expr rand()] > 0.70 } {
	    set Rand [expr -log([expr rand()])*$lifetime*50 ] 
	    set Rand [format %5.0f $Rand]
	    set Rand [format %0x $Rand]
	    
	} else  {
	    set Rand "3E8\n"
	}
	return $Rand
    }

}

proc muonrate { } {
    global nmuon mrate lastnmuon fpmuon STIME etime STOP eetime
    set mrate [expr $nmuon - $lastnmuon ]
    puts $fpmuon "[expr 40000 + $mrate] [clock seconds]"
    if { $mrate >= 20 } { set mrate 20 }
     set NUM [.f2.1.3.can create rectangle 214 110 217 [expr 110 -$mrate*5 ] \
	     -fill blue -outline green -tag muonrate]
    .f2.1.3.can move muonrate -3 0

     incr NUM -58
    if { $NUM > 8 } { .f2.1.3.can delete $NUM }
    set lastnmuon $nmuon
    if { $STOP != 1 } { incr eetime }
    set etime [timeprint $eetime ]
    after 1000 muonrate
}


proc decayrate { } {
    global dmuon drate lastdmuon  fpmuon STIME etime
    set drate [format %2.1f [expr $dmuon * 60. /([clock second] - $STIME) ]]
    set lastdmuon $dmuon
    flush $fpmuon
    after 60000 decayrate
}




proc muonfit { } {
    global timescale bins Font2 STOP YAXIS y counts width K B logl sigma kx2
    set X2MIN 100000000.
    set lifetime 2.15
    set TEMPS $STOP
    set STOP 0
    set wxx 0.
    set wx 0.
    set wc 0.
    set wxc 0.
    set sigw 0.
    set kx2 0.

#
#        Caculate the sigma here
#
#        Sig2 = $bins * 0.05^2/ Det
#        Det = $bins * sx2 - (sx)^2
#        WW              wxx   wx2
#
    set bgbins 0
    set bg 0.
    if { $timescale > 12 } {
	for { set i [expr int($bins * 12/$timescale) ] } { $i <[expr int($bins * 20/$timescale) ] && $i < $bins } { incr i } {
	    incr bgbins
	    set bg [expr $bg + $y($i)]
	}

	if { $bgbins > 0 } {set bg [expr $bg / $bgbins ] }
    }

    for { set i 0 } { $i < [expr $bins * 12./$timescale ] && $i < $bins } { incr i } {
	
	if { $y($i) - $bg > 0 } {
	    set C log($y($i)-$bg)
	    set w [expr $y($i) -$bg ]
	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    puts "$x $w [expr sqrt($w)]"
	    set wxx [expr $wxx + $w*$x*$x]
	    set wx [expr $wx + $w * $x ]
	    set wc [expr $wc +$w * $C ]
	    set wxc [expr $wxc + $w*$x*$C]
	    set sigw [expr $sigw + $w]
	    
	}

    }


    set deta [ expr $sigw *$wxx  - $wx*$wx ]
    set B [expr exp(($wc*$wxx - $wx * $wxc)/$deta) ]
    set K [expr -1/(($sigw*$wxc - $wx*$wc)/$deta) ]

#    set deta [expr $sigw*$sigwx2 - $sigVx1*$sigVx1]
    set sigma [expr $K*$K*sqrt($sigw/$deta)]
    puts " $wxx $wx $wxc $sigw $deta $B $K $sigma"

    for { set i 0 } { $i < $bins } { incr i } {
#
#       Change !!
#	
	if { $y($i)-$bg > 1 } {
	    set w [expr $y($i) -$bg]
	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    set kx2 [expr $kx2 + ($w - $B*exp(-$x/$K))*($w -$B*exp(-$x/$K))/$w]
	}
    }

#
#   Second time
#
#


    set X2MIN 100000000.
    set lifetime 2.15
    set wxx 0.
    set wx 0.
    set wc 0.
    set wxc 0.
    set sigw 0.
    set kx2 0.
    set bgbins 0
    set bg 0.

    if { $timescale > 12 } {
	for { set i [expr int($bins * 12/$timescale) ] } { $i <[expr int($bins * 20/$timescale) ] && $i < $bins } { incr i } {

	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    incr bgbins
	    set bg [expr $bg + $y($i) - $B*exp(-$x/$K)]
	}

	if { $bgbins > 0 } {set bg [expr $bg / $bgbins ] }
    }
    if { $bg < 0 } { set bg 0. }

    for { set i 0 } { $i < [expr $bins * 12./$timescale ] && $i < $bins } { incr i } {
	
	if { $y($i) - $bg > 0 } {
	    set C log($y($i)-$bg)
	    set w [expr $y($i) -$bg ]
	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    puts "$x $w [expr sqrt($w)]"
	    set wxx [expr $wxx + $w*$x*$x]
	    set wx [expr $wx + $w * $x ]
	    set wc [expr $wc +$w * $C ]
	    set wxc [expr $wxc + $w*$x*$C]
	    set sigw [expr $sigw + $w]
	    
	}

    }


    set deta [ expr $sigw *$wxx  - $wx*$wx ]
    set B [expr exp(($wc*$wxx - $wx * $wxc)/$deta) ]
    set K [expr -1/(($sigw*$wxc - $wx*$wc)/$deta) ]

#    set deta [expr $sigw*$sigwx2 - $sigVx1*$sigVx1]
    set sigma [expr $K*$K*sqrt($sigw/$deta)]
    puts " $wxx $wx $wxc $sigw $deta $B $K $sigma"

    for { set i 0 } { $i < $bins } { incr i } {
#
#       Change !!
#	
	if { $y($i)-$bg > 1 } {
	    set w [expr $y($i) -$bg]
	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    set kx2 [expr $kx2 + ($w - $B*exp(-$x/$K))*($w -$B*exp(-$x/$K))/$w]
	}
    }


#
#
#
#

    set X2MIN 100000000.
    set lifetime 2.15
    set wxx 0.
    set wx 0.
    set wc 0.
    set wxc 0.
    set sigw 0.
    set kx2 0.
    set bgbins 0
    set bg 0.

    if { $timescale > 12 } {
	for { set i [expr int($bins * 12/$timescale) ] } { $i <[expr int($bins * 20/$timescale) ] && $i < $bins } { incr i } {

	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    incr bgbins
	    set bg [expr $bg + $y($i) - $B*exp(-$x/$K)]
	}

	if { $bgbins > 0 } {set bg [expr $bg / $bgbins ] }
    }
    if { $bg < 0 } { set bg 0. }

    for { set i 0 } { $i < [expr $bins * 12./$timescale ] && $i < $bins } { incr i } {
	
	if { $y($i) - $bg > 0 } {
	    set C log($y($i)-$bg)
	    set w [expr $y($i) -$bg ]
	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    puts "$x $w [expr sqrt($w)]"
	    set wxx [expr $wxx + $w*$x*$x]
	    set wx [expr $wx + $w * $x ]
	    set wc [expr $wc +$w * $C ]
	    set wxc [expr $wxc + $w*$x*$C]
	    set sigw [expr $sigw + $w]
	    
	}

    }


    set deta [ expr $sigw *$wxx  - $wx*$wx ]
    set B [expr exp(($wc*$wxx - $wx * $wxc)/$deta) ]
    set K [expr -1/(($sigw*$wxc - $wx*$wc)/$deta) ]

#    set deta [expr $sigw*$sigwx2 - $sigVx1*$sigVx1]
    set sigma [expr $K*$K*sqrt($sigw/$deta)]
    puts " $wxx $wx $wxc $sigw $deta $B $K $sigma"

    for { set i 0 } { $i < $bins } { incr i } {
#
#       Change !!
#	
	if { $y($i)-$bg > 1 } {
	    set w [expr $y($i) -$bg]
	    set x [ expr ($i+0.5)*$timescale/$bins  ]
	    set kx2 [expr $kx2 + ($w - $B*exp(-$x/$K))*($w -$B*exp(-$x/$K))/$w]
	}
    }


#
#
#
#

    .f2.2.1.can1 delete fit
    .f2.2.1.can1 create text 580 40 -text "Total Events: $counts" -fill red -font $Font2 -tag fit
    .f2.2.1.can1 create text 580 70 -text "\u03c4 = [format %2.3f $K] \u00B1 [format %2.3f $sigma] \u03bcs" -fill red -font $Font2 -tag fit
    .f2.2.1.can1 create text 580 100 -text "Chi2 /D.O.F = [format %2.1f $kx2] /[expr $bins -2] " -fill red -font $Font2 -tag fit
#    .f2.2.1.can1 create text 518 93 -text "2" -fill red -font {Times 8} -tag fit

    if { $logl == 0 } {

	
    for { set i 0 } { $i < 600 } { incr i } {
#
#      Change!!
#
	set yexp [ expr 320 - ($B * exp( - $i*$timescale/$K/600 )+ $bg )/$YAXIS ]
	if {$yexp > 20 && $yexp < 320 } { lappend a [expr 80 + $i ] $yexp }
    }
    
    .f2.2.1.can1 create line $a -fill blue -width 1 -smooth 1 -tag fit
   }

    if {$logl == 1} {

    for { set i 0 } { $i < 600 } { incr i} {
#
#      Change!!
#

	set yexp [ expr 320 -(log($B*exp(-$i*$timescale/$K/600) +$bg ))/$YAXIS ]
	if {$yexp > 20 && $yexp < 320 } {lappend a [expr 80 + $i ] $yexp }
     }
     
     .f2.2.1.can1 create line $a -fill blue -width 1 -smooth 1 -tag fit
    }

    set STOP $TEMPS
}


proc LoadOldData { } {
    global readold number time1 time2 numdate thDetector bsecond thYaxis thXaxis Now timestart dmuon READ

    toplevel .load
    button .load.button -text "Loading Data ... "
    pack .load.button

    set thYaxis 1
    set thXaxis 1
    set READ 1

    for { set VAL 0 } { $VAL < 100 } {incr VAL 1 } {
	lappend alist [expr $VAL]
	lappend alist 0
    }
    array set thDetector $alist


    
    set Now [clock seconds]
    set timestart  [expr $Now -500 ]
    set bsecond 10

    if { [catch {set fpmuon [open muon.data r] } ] } {
	set number 0
	set numdate 0
	set testfp [open muon.data w]
	close $testfp
    }


    if { $readold == 1 && $number > 0 && $numdate == 0 } {

	if { [catch {seek $fpmuon "-[expr int($number*10)]" end } ]} {
	   seek $fpmuon  0 start
	}
	catch { set data [gets $fpmuon] }
	catch { set data [gets $fpmuon] }

	set timestart [lindex $data 1]
	set Now [clock seconds]
	if { [catch { set bsecond [expr int(($Now -$timestart) /50) ]} ] } { 
            
        setyaxis


        return  }

	while {![eof $fpmuon]} {
	    vwait READ
	    for { set i 0 } { $i < 100 } { incr i } { 
		set data [gets $fpmuon]
		if { [llength $data]>0 } {
		    set decaytime [lindex $data 0]
		    if { $decaytime < 20000 } { 
			oldstatic $decaytime 
		    }
		
		    set times [lindex $data 1]
		    set bin [expr int (( $times - $timestart ) /$bsecond) ]
		    if { $bin >=0 } {
			if { [expr [lindex $data 0] - 40000 ] > 0 } {
			    incr thDetector($bin) [expr [lindex $data 0] - 40000 ]
			} else { 

			}
			
			if { $thDetector($bin) > 150 * $thYaxis } {
			    set thYaxis [ expr $thYaxis * 2]
			}
			
		    }
		}
	    } 
	}
	
	close $fpmuon
        extrastatic $decaytime
    }


    if { $readold == 0 && $numdate  == 1 } {
	
	seek $fpmuon  0 start
	set timestart [clock scan $time1]
	set data [gets $fpmuon]
	set data [gets $fpmuon]

	if { [clock seconds] < [clock scan $time2] } { set Now [clock scan now] }
	set bsecond [expr int(($Now -$timestart) /50) ]
	if { $bsecond == 0 } { continue }

	while {![eof $fpmuon]} {
	    vwait READ
	    for { set i 0 } { $i < 100 } { incr i } { 
		set data [gets $fpmuon]
		if { [llength $data]>0 } {
		    set decaytime [lindex $data 0]
		    if { $decaytime < 20000 } { 
			oldstatic $decaytime ;
#			incr dmuon -1
		    }
		    set times [lindex $data 1]
		    set bin [expr int (( $times - $timestart ) /$bsecond) ]
		    if { $bin >=0 && $times > $timestart && $times <= $Now  } {
			if { [expr [lindex $data 0] - 40000 ] > 0 } {
			    incr thDetector($bin) [expr [lindex $data 0] - 40000 ]
			} else { 
#			    incr thDetector($bin) 
			}
			
			if { $thDetector($bin) > 150 * $thYaxis } {
			    set thYaxis [ expr $thYaxis * 2]
			}
		    }
		}
		
	    }
	    
	}
	close $fpmuon
	extrastatic $decaytime
    }


    set NUM [.f2.2.2.can1 create rectangle 80 10 680 160 -fill LightBlue1 -outline LightBlue4]
    for {set I [expr $NUM -200] } { $I < $NUM } { incr I } {
	.f2.2.2.can1 delete $I
    }
    
    for {set VAL 0} { $VAL < 50 } {incr VAL } {
	
	.f2.2.2.can1 create rectangle [expr 80+ $VAL *6] 160 [expr $VAL *6 +86] \
		[expr 160 - $thDetector($VAL)/$thYaxis] -fill red -outline LightBlue4
	
	
    }



    for {set VAL 0} { $VAL < 50 } {incr VAL 10 } {

	set timeV [expr $timestart + $bsecond * $VAL ]
	.f2.2.2.can1 create text [expr 80+$VAL*6] 170 -text [clock format $timeV -format %y/%m/%d]
	.f2.2.2.can1 create text [expr 80+$VAL*6] 180 -text [clock format $timeV -format %H:%M:%S]
    }

    for {set VAL 60 } { $VAL <= 100 } {incr VAL 10 } {

	set timeV [expr $timestart + $bsecond * $VAL ]
	.f2.2.2.can1 create text [expr 80+$VAL*6] 170 -text [clock format $timeV -format %y/%m/%d]
	.f2.2.2.can1 create text [expr 80+$VAL*6] 180 -text [clock format $timeV -format %H:%M:%S]
     }

     .f2.2.2.can1 create text 380 170 -text "Today"
     .f2.2.2.can1 create text 380 180 -text [clock format [clock seconds] -format %H:%M:%S]

     .f2.2.2.can1 create text 60 155 -text 0
     .f2.2.2.can1 create text 60 80 -text [expr 75*$thYaxis]
     .f2.2.2.can1 create text 60 15 -text [expr 150*$thYaxis]
     .f2.2.2.can1 create line 80 47 680 47 -dash . -fill black
     .f2.2.2.can1 create line 80 80 680 80 -dash . -fill black
     .f2.2.2.can1 create line 80 117 680 117 -dash . -fill black
     .f2.2.2.can1 create text 600 25 -text \
	     "Time:[clock format [clock seconds] -format %H:%M:%S]"
     .f2.2.2.can1 create text 600 35 -text \
	     "Bin Width:[clock format  $bsecond -gmt 1 -format %H:%M:%S]/bin"





    for {set I 50 } { $I < 100 } { incr I} {
	set thDetector($I) 0
    }
    setyaxis

#    Updateth
    puts "This loadold data over!"
    catch { destroy .load }
     
}


proc Updateth { } {

    global bsecond thDetector thNumber thYaxis thXaxis Now timestart
    
    puts "$thNumber" 

    if {! [info exist bsecond] } {
        set bsecond 10
	set timestart [expr $Now - 50*$bsecond]
        set thYaxis 1
        set thXaxis 1
	
    }

     set VAR [expr int (50 + ([clock seconds] - $Now)/$bsecond )]

     if { $thNumber > [expr 150*$thYaxis] } {set thYaxis [expr ( 1 + $thNumber /150 )]}
     incr thDetector($VAR) $thNumber
     set thNumber 0

    set NUM [.f2.2.2.can1 create rectangle 80 10 680 160 -fill LightBlue1 -outline LightBlue4]
    for {set I [expr $NUM -250] } { $I < $NUM } { incr I } {
        .f2.2.2.can1 delete $I
    }

    for {set VAL 0} { $VAL < 100 } {incr VAL } {

	.f2.2.2.can1 create rectangle [expr 80+ $VAL *6] 160 [expr $VAL *6 +86] \
		[expr 160 - $thDetector($VAL)/$thYaxis] -fill red -outline LightBlue4


    }


    for {set VAL 0} { $VAL < 110 } {incr VAL 10 } {

	set timeV [expr $timestart + $bsecond * $VAL ]
	.f2.2.2.can1 create text [expr 75+$VAL*6] 170 -text [clock format $timeV -format %y/%m/%d]
	.f2.2.2.can1 create text [expr 75+$VAL*6] 180 -text [clock format $timeV -format %H:%M:%S]
     }

     .f2.2.2.can1 create line 80 47 680 47 -dash . -fill black
     .f2.2.2.can1 create line 80 80 680 80 -dash . -fill black
     .f2.2.2.can1 create line 80 117 680 117 -dash . -fill black

     .f2.2.2.can1 create text 25 10 -text "Evt/bin"
     .f2.2.2.can1 create text 60 155 -text 0
     .f2.2.2.can1 create text 60 117 -text [expr int (37.5*$thYaxis)]
     .f2.2.2.can1 create text 60 80 -text [expr 75*$thYaxis]
     .f2.2.2.can1 create text 60 47 -text [expr int (112.5*$thYaxis)]
     .f2.2.2.can1 create text 60 15 -text [expr 150*$thYaxis]
     .f2.2.2.can1 create text 600 25 -text \
	     "Time:[clock format [clock seconds] -format %H:%M:%S]"
     .f2.2.2.can1 create text 600 35 -text \
	     "Bin Width:[clock format  $bsecond -gmt 1 -format %H:%M:%S]/bin"

    if { $VAR == 99 } {
	set Now [expr $Now + 50*$bsecond]
	set thXaxis [expr $thXaxis * 2 ]
	set bsecond [expr $bsecond * 2 ]

        for {set I 0 } { $I < 50 } { incr I 1 } {
            set thDetector($I) [expr $thDetector([expr $I*2]) + $thDetector([expr 2*$I +1])]
	    if {$thDetector($I) > 150*$thYaxis } { set thYaxis [expr $thYaxis * 2] }
	}

        for {set I 50 } { $I < 100 } { incr I} {
            set thDetector($I) 0
	}
	

    }
    
    after [expr 1000 * $bsecond] Updateth
}

proc saveornot { } {
    global fpmuon STOP
    set STOP 1
    catch {destory .topsave }
    toplevel .topsave
    wm title .topsave "Save the Data"

    focus -force .topsave
    frame .topsave.f1 -width 50
    label .topsave.f1.text -text "Do you want save the Data collected this time?"
    frame .topsave.f2 -width 50
    button .topsave.f2.no -width 20 -text "No"  -command { exit }
    button .topsave.f2.yes -width 20 -text "Yes" -command {
	set fpold  [open muon.data a+]
	seek $fpmuon 0 start
        fcopy $fpmuon $fpold
        close $fpold
        close $fpmuon
        exit

    }

    pack .topsave.f1 .topsave.f2 -side top
    pack .topsave.f1.text
    pack .topsave.f2.no .topsave.f2.yes -side left
}

proc viewraw { } {

global fpname

catch { destory .toptext }
toplevel .toptext

wm title .toptext "Show the raw data"

focus -force .toptext

frame .toptext.button -width 200

pack .toptext.button -side bottom -fill x -pady 2m

label .toptext.button.label1 -text "Number of raw\n events want read"
entry .toptext.button.entry -width 6 -textvariable COUNTS
set COUNTS 100
button .toptext.button.read -text "Read" -command {

    set fp [open $fpname r]
    fconfigure $fp  -encoding binary -translation binary
    catch { seek $fp -[expr int (13.20 * $COUNTS)] end }
    set data [gets $fp]
    
    while { ![eof $fp] } {
    set data [gets $fp] 
	if { [llength $data] } {   
	    set life [lindex $data 0]
	    set dtime [clock format [lindex $data 1] -format %y/%m/%d-%H:%M:%S]
	    .toptext.text insert @0,0 "$dtime   $life\n"
	    
	}
	
    }
    .toptext.text insert @0,0 "Measure time:   Lifetime\u03bc S\n"

    close $fp
}


button .toptext.button.dismiss -text "Dismiss" \
	-command "destroy .toptext"

pack .toptext.button.label1  .toptext.button.entry .toptext.button.read .toptext.button.dismiss -side left -expand 1

text .toptext.text -relief sunken -bd 2 -yscrollcommand \
	".toptext.scroll set" -setgrid 1 \
	-height 30 -width 10 -undo 1 -autosep 1

scrollbar .toptext.scroll -command ".toptext.text yview"

pack .toptext.scroll -side right -fill y
pack .toptext.text -expand yes -fill both




}



proc oldstatic { a } {
    global  timescale bins  STOP y counts logl  YAXIS

    
    if {![info exist y ]} {
	for { set VAL 0 } { $VAL < $bins } {incr VAL 1 } {
	    lappend alist [expr $VAL]
	    lappend alist 0 }
	    array set y $alist
	    .f2.2.1.frame1.logl config -state normal
	    
    }


#     switch log/line
#
    
    if { $STOP != 1  && $a < [expr $timescale * 1000 ] && $bins > 0 } then {

	if { [expr fmod( $counts , 1000 )] < 1 } { muonstart $a }
#	 puts $fpmuon "$a [clock seconds]"
	set a [expr  int( $a * $bins /$timescale /1000 ) ]
	incr y($a)
	incr counts
	
    }

    if {$logl == 0 } {
        set YAXIS [format %3.2f [expr ($y(0)+1)/200.]]
        .f2.2.1.frame1.lab config -text "Linear scale"
    } else {
        set YAXIS [format %3.5f [expr log($y(0)+1)/240.]]
        .f2.2.1.frame1.lab config -text "Log scale"
    }
        

}


proc setyaxis { } {

    global YAXIS y logl

    if { [info exist y ] } {

	if {$logl == 0 } {
	    set YAXIS [format %3.2f [expr ($y(0)+1)/200.]]
	    .f2.2.1.frame1.lab config -text "Linear scale"
	} else {
	    set YAXIS [format %3.5f [expr log($y(0)+1)/240.]]
	    .f2.2.1.frame1.lab config -text "Log scale"
	}
    }
}




proc extrastatic { a } {
    global  timescale bins  STOP y logl  YAXIS

    
    if {![info exist y ]} {
	for { set VAL 0 } { $VAL < $bins } {incr VAL 1 } {
	    lappend alist [expr $VAL]
	    lappend alist 0 }
	    array set y $alist
	    .f2.2.1.frame1.logl config -state normal
	    
    }


#     switch log/line
#
    
    if { $STOP != 1  && $a < [expr $timescale * 1000 ] && $bins > 0 } then {
	muonstart $a 
    }

    if {$logl == 0 } {
        set YAXIS [format %3.2f [expr ($y(0)+1)/200.]]
        .f2.2.1.frame1.lab config -text "Linear scale"
    } else {
        set YAXIS [format %3.5f [expr log($y(0)+1)/240.]]
        .f2.2.1.frame1.lab config -text "Log scale"
    }
        

}

















































































