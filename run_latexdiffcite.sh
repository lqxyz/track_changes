
#!/bin/bash

old_tex=manuscript_old.tex 
new_tex=manuscript_new.tex 

diff_tex=track_changes.tex

# If don't use -o option, the default output file is 'diff.tex'
python latexdiffcite.py file $old_tex $new_tex -o $diff_tex
latexmk -f -pdf -xelatex -interaction=nonstopmode $diff_tex

