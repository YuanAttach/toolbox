# !/bin/bash
#set -e
#set -x
predict=$1
margin=9
label=0
sum0=`cat $predict | grep "0,1,0" | wc -l`
sum1=`cat $predict | grep "1,1,0" | wc -l`
aggr=0
sum=$sum0
echo 'sum0:'$sum0
echo 'sum1:'$sum1
while [ $label -ne 1 -o $margin -ne -1 ];
do
	sub_margin=9
	while [ $sub_margin -ne -1 ];
	do
		whole_str=$label',1,0.'$margin$sub_margin
		count=`cat $predict | grep "$whole_str" |wc -l`
		aggr=`expr $aggr + $count`
		#echo $aggr
		#ratio=`echo "sclae=3;$aggr/$sum"|bc`
		echo $whole_str"    "$count"    "$aggr
		sub_margin=`expr $sub_margin - 1`
	done
	margin=`expr $margin - 1`
	if [ $margin -eq -1 -a $label -eq 0 ]; then
		label=1
		margin=9
		aggr=0
		sum=$sum1
	fi
done
