# convert to CM and window averages
WINDOW="50000" # Window Size
WINKB="50" # Window Size in kb

for rmap in $(ls *.rmap |  cut -f1-2 -d '.')
do
#convert to CM
awk -f convert_Output_pyrho_cM_Mb.awk  ${rmap}.rmap > ${rmap}.rmapCM
#add chrom name to column1 required for window script below
awk '{print "'${rmap}'", $0}' ${rmap}.rmapCM > ${rmap}.rmap2
#50kb window
python3 Rec_windows.py ${rmap}.rmap2 ${WINDOW} > ${rmap}.rmap${WINKB}kb
done
rm *.rmap2
rm *.rmapCM
