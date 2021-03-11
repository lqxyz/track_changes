#!/bin/bash
# Generate track-changes from old and new tex-file archives (.zip files)
#
# For example, the archives (.zip) could be downloaded from Overleaf based on label versions

# The names of the old and new archive files
old_zip="manuscript_draft_old.zip"
new_zip="manuscript_draft_new.zip"

# Old and new tex file names that have changes (Names should be the same)
tex_fn="manuscript.tex"
# Output file name
diff_tex="diff.tex"

check_zip_file()
{
    [[ ! -f "$1" ]] && echo "$1" does not exist, please check again. && exit 1
}

check_zip_file "$old_zip"
check_zip_file "$new_zip"

old_dir=old
new_dir=new

# unzip will create exdir (-d) if it does not exist
unzip -o "$old_zip" -d $old_dir
unzip -o "$new_zip" -d $new_dir

diff_dir=diff_test
[[ ! -d $diff_dir ]] && mkdir $diff_dir

# check if $tex_fn exists in unzipped directory
# otherwise find the tex file within the unzipped directory
cd $old_dir
if [[ ! -f "$tex_fn" ]]; then
    num=$(ls '.tex' | wc -l)
    if [[ $num -gt 1 ]]; then
        echo "Multiple tex files! Please specify the main tex file name." && exit 1
    else
        tex_fn=$(ls *.tex)
    fi
    echo $tex_fn
fi
cd ..

old_tex='old.tex'
new_tex='new.tex'

compile_old_new_files()
{
    # $1 is the directory name (old or new)
    tex_nm=${tex_fn/.tex/}_"$1".tex
    cd $1
    mv "$tex_fn" "$tex_nm"
    latexmk -f -pdf -xelatex -interaction=nonstopmode "$tex_nm"
    cp -r ./* ../"$diff_dir"
    cd ..

    [[ "$1" == *"old"* ]] && old_tex="$tex_nm"
    [[ "$1" == *"new"* ]] && new_tex="$tex_nm"
}

# Copy files from new and old directories to diff_dir
compile_old_new_files $old_dir
echo $old_tex
compile_old_new_files $new_dir
echo $new_tex

# Now go into the diff_dir
cd $diff_dir

# Get and compile the diff.tex
echo Getting "$diff_tex"
latexdiff "$old_tex" "$new_tex"  > "$diff_tex"

# https://tex.stackexchange.com/questions/478124/latexdiff-dont-work-in-table-with-scalebox 
# If the statement above could not track some changes within certain latex commands,
# you can use '--append-textcmd' to add them.
#
# For example, for journal GMD (https://www.geoscientific-model-development.net/), we can use:
# latexdiff --flatten --append-textcmd=resizebox --append-textcmd=codedataavailability \
#           --append-textcmd=authorcontribution "$old_tex" "$new_tex"  > "$diff_tex"

# Or use the latexdiffcite to track citation changes nicely
# Need to change latexdiff argument via 'append_args' in latexdiffcite.py
#
# python latexdiffcite.py file "$old_tex" "$new_tex" -o "$diff_tex"

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

