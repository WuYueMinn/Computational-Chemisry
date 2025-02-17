# User-defined parameters
set residue_name_cation "OCT"
set residue_name_anion "Tf2"
set z_min_cat 20.5
set z_max_cat 26.5
set z_min_anod 109.5 
set z_max_anod 115.5

# Load the PDB and DCD files
mol new start_drudes.pdb
mol addfile FV_NVT.dcd

# Open and read charge file
set chargeFile [open "charges.dat" r]
set charges [read $chargeFile]
close $chargeFile
set chargeData [split $charges "\n"]

# Delete any existing representations
mol delrep all top

# Find the actual min/max charges from the data for better scaling
set min_charge 0
set max_charge 0
foreach line $chargeData {
    set values [split $line " "]
    foreach charge $values {
        if {$charge != ""} {
            if {$charge < $min_charge} {
                set min_charge $charge
            }
            if {$charge > $max_charge} {
                set max_charge $charge
            }
        }
    }
}

color scale method BWR
# Function to convert charge value to RGB color (BWR scheme)
proc charge_to_color {charge min_charge max_charge} {
    # Normalize charge to [-1, 1] range
    set range [expr {max(abs($min_charge), abs($max_charge))}]
    set normalized [expr {$charge / $range}]
    
    if {$normalized < 0} {
        # Blue to White (negative)
        set intensity [expr {1.0 + $normalized}]
        return [list $intensity $intensity 1.0]
    } else {
        # White to Red (positive)
        set intensity [expr {1.0 - $normalized}]
        return [list 1.0 $intensity $intensity]
    }
}

# Create representations for each chain

# Chain A (positive electrode)
mol representation VDW 1.0
mol selection "chain A"
mol color User
mol addrep top
mol modmaterial 0 top Opaque

# Chain B (negative electrode)
mol representation VDW 1.0
mol selection "chain B"
mol color User
mol addrep top
mol modmaterial 1 top Opaque

# Cations near positive electrode
mol representation Licorice 0.3
mol selection "same residue as (resname $residue_name_cation and z > $z_min_cat and z < $z_max_cat)"
mol color ColorID 32
mol addrep top
mol modmaterial 2 top Opaque

# Cations near negative electrode
mol representation Licorice 0.3
mol selection "same residue as (resname $residue_name_cation and z > $z_min_anod and z < $z_max_anod)"
mol color ColorID 32
mol addrep top
mol modmaterial 3 top Opaque

# Anions near positive electrode
mol representation VDW 0.7
mol selection "same residue as (resname $residue_name_anion and z > $z_min_cat and z < $z_max_cat)"
mol color Name
mol addrep top
mol modmaterial 4 top Opaque

# Anions near negative electrode
mol representation VDW 0.7
mol selection "same residue as (resname $residue_name_anion and z > $z_min_anod and z < $z_max_anod)"
mol color Name
mol addrep top
mol modmaterial 5 top Opaque

# Process each frame
# set numFrames [molinfo top get numframes]
# for {set frame 0} {$frame < $numFrames} {incr frame} {
for {set frame 0} {$frame < 10} {incr frame} {
    # Move to current frame
    animate goto $frame
    
    # Get charge data for current frame
    set frameData [lindex $chargeData $frame]
    set chargeList [split $frameData " "]
    
    # Process Chain A (positive electrode)
    set index 0
    set grpA_atoms [atomselect top "chain A"]
    $grpA_atoms frame $frame
    set chainA_charges {}
    foreach atom [$grpA_atoms list] {
        set charge [lindex $chargeList $index]
        # Normalize charge for coloring
        set normalized_charge [expr {($charge - $min_charge) / ($max_charge - $min_charge)}]
        lappend chainA_charges $normalized_charge
        incr index
    }
    $grpA_atoms set user $chainA_charges
    
    # Process Chain B (negative electrode)
    set grpB_atoms [atomselect top "chain B"]
    $grpB_atoms frame $frame
    set chainB_charges {}
    foreach atom [$grpB_atoms list] {
        set charge [lindex $chargeList $index]
        # Normalize charge for coloring
        set normalized_charge [expr {($charge - $min_charge) / ($max_charge - $min_charge)}]
        lappend chainB_charges $normalized_charge
        incr index
    }
    $grpB_atoms set user $chainB_charges
    
    # Clean up selections
    $grpA_atoms delete
    $grpB_atoms delete
    
    # Update display
    display update
}

# Set final coloring and materials
mol modcolor 0 top User
mol modmaterial 0 top Opaque
mol modcolor 1 top User
mol modmaterial 1 top Opaque
color Display Background 8
display projection Orthographic
display depthcue off
axes location off

# Center and reset view
display resetview
display update


puts "Visualization completed with charge range: $min_charge to $max_charge"
