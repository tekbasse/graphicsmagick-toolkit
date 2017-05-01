set title "File Types"
set context [list [list index "Documentation"] $title]

set identify_info [${bin_dir}gm identify]
if { ![regexp --nocase -- {feature support[\.\:]*} $identify_info support_set] } {
    set support_set "Unable to determine list of supported files at this time."
    ns_log Warning "graphicsmagic-toolkit/www/doc/file-types-supported: Cannot find list of supported files."
}
