# Directory containing the source files
set source_dir [file normalize "../ip_cores/general-cores"]

if {![file isdirectory $source_dir]} {
    error "Directory not found: $source_dir"
}

# Normalize paths for comparison
set source_dir [string map {\\ /} $source_dir]
set source_prefix "${source_dir}/"

# Find all VHDL files already added to the Vivado project
set vhdl_files {}

foreach f [get_files -all -filter {FILE_TYPE =~ VHDL*}] {

    set fpath [string map {\\ /} [file normalize [get_property NAME $f]]]

    # Include files in the directory and all its subdirectories
    if {[string first $source_prefix $fpath] == 0} {
        lappend vhdl_files $f
    }
}

# Check whether any files were found
if {[llength $vhdl_files] == 0} {
    error "No VHDL files found under $source_dir"
}

# Assign the library
set_property LIBRARY general_cores $vhdl_files

# Report the changes
puts "Assigned [llength $vhdl_files] VHDL files to library 'general_cores':"

foreach f $vhdl_files {
    puts "  [get_property NAME $f]"
}
