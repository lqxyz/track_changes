#!/bin/bash
# Generate track-changes from old and new tex-file archives (.zip files)
#
# For example, the archives (.zip) could be downloaded from Overleaf based on label versions

# The names of the old and new archive files
old_zip='manuscript_draft_old.zip'
new_zip='manuscript_draft_new.zip'
# Old and new tex file names that have changes (Names should be the same)
tex_fn="manuscript_draft.tex"

# Output file name
diff_tex="track_changes.tex"


check_zip_file()
{
    [[ ! -f "$1" ]] && echo "$1" does not exist, please check again. && exit 1
}

check_zip_file "$old_zip"
check_zip_file "$new_zip"

old_dir='old'
new_dir='new'

# unzip will create exdir (-d) if it does not exist
unzip -o "$old_zip" -d $old_dir
unzip -o "$new_zip" -d $new_dir

diff_dir='diff'
[[ ! -d $diff_dir ]] && mkdir $diff_dir

# Copy files from new and old directories to diff_dir
cp -r $new_dir/* $diff_dir/

old_tex=${tex_fn/.tex/_old.tex}
cp "$old_dir/$tex_fn" "$diff_dir/$old_tex"

# Now go into the diff_dir
cd $diff_dir

# Get and compile the diff.tex
echo Getting "$diff_tex"
# latexdiff "$old_tex" "$tex_fn"  > "$diff_tex"
# https://tex.stackexchange.com/questions/478124/latexdiff-dont-work-in-table-with-scalebox 
latexdiff --append-textcmd="resizebox" --append-textcmd="codedataavailability" "$old_tex" "$tex_fn"  > "$diff_tex"

echo Compiling "$diff_tex"
# https://mg.readthedocs.io/latexmk.html
# https://tex.stackexchange.com/questions/120019/make-latexmk-ignore-errors-and-finish-compiling
#latexmk -f -pdf -xelatex -interaction=nonstopmode "$diff_tex"
latexmk -pdf -interaction=nonstopmode "$diff_tex"

# Clean up the temporary files
# https://tex.stackexchange.com/questions/498338/latexmk-clean-c-some-beamer-related-files-are-not-deleted
# Note that -C also cleans up the actual output (e.g. pdf), so use -c instead
latexmk -c "$diff_tex"

# Deal with the output file
output_pdf=${diff_tex/.tex/.pdf}
if [ ! -f "$output_pdf" ]; then
    echo ""
    echo "Error(s) in latexmk. No pdf file produced. Check the $diff_dir/$diff_tex file."
    exit 1
fi

mv "$output_pdf" ..

# Delete temporary directories
cd ..
rm -r "$old_dir" "$new_dir" "$diff_dir"

echo ""
echo Done! The output file is "$output_pdf".
