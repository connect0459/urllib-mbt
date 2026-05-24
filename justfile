# Initialize WPT submodule (run once after clone)
setup:
    git submodule update --init --recursive
    moon update

# Regenerate combining mark table from the system Unicode database
gen-combining-mark:
    python3 tools/gen_combining_mark.py

# Regenerate IDNA mapping tables from IdnaMappingTable.txt
# Usage: just gen-idna                         (reads /tmp/IdnaMappingTable.txt)
#        just gen-idna /path/to/IdnaMappingTable.txt
gen-idna input='/tmp/IdnaMappingTable.txt':
    python3 tools/gen_idna_mapping.py {{input}}
