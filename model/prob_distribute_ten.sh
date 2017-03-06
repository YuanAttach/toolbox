# !/bin/bash
#set -e
#set -x
predict=$1
margin=9
label=0
while [ $label -ne 1 -o $margin -ne -1 ];
do
	whole_str=$label',1,0.'$margin
	count=`cat $predict | grep "$whole_str" |wc -l`
	echo $whole_str"    "$count
	margin=`expr $margin - 1`
	if [ $margin -eq -1 -a $label -eq 0 ]; then
		label=1
		margin=9
	fi
done
