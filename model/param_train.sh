#! /bin/bash

HADOOP=/opt/meituan/hadoop/bin/hadoop
# 必须加上双引号
TRAIN_DATE="20160928-20161121"
TRAIN_DATA_PATH=liyubing/xgboost_rm/xgboost-feature/0-train
TRAIN_REDUCE_NUM=2024
TRAIN_IMPRESSION_SAMPLE_RATE=1
TRAIN_CLICK_SAMPLE_RATE=1
TRAIN_ORDER_SAMPLE_RATE=1
TRAIN_PAY_SAMPLE_RATE=1
#TRAIN_CLICK_SAMPLE_RATE=-0.00001
#TRAIN_ORDER_SAMPLE_RATE=-0.00001
#TRAIN_PAY_SAMPLE_RATE=1

# 必须加上双引号
TEST_DATE="20161123-20161127"
TEST_DATA_PATH=liyubing/xgboost_rm/xgboost-feature/0-test
TEST_REDUCE_NUM=512
TEST_IMPRESSION_SAMPLE_RATE=1
TEST_CLICK_SAMPLE_RATE=1
TEST_ORDER_SAMPLE_RATE=1
TEST_PAY_SAMPLE_RATE=1

QUEUE=root.hadoop-recsys.test
WORKER_NUM=16
WORKER_MEMORY=8192
WORKER_VCORES=2
HDFS_PATH=hdfs://hadoop-meituan/user/hadoop-recsys/
MODEL_NAME=xg_model
MODEL_PATH=liyubing/xgboost_rm/xgboost-model/0/$MODEL_NAME
#FEATURE_PATH=/user/hadoop-recsys/gulihong/rerank/homepage/cleaned_featureData/
FEATURE_PATH=/user/hadoop-recsys/liyubing/deleta_data_feature/join_feature/
#FEATURE_PATH=/user/hadoop-recsys/liyubing/deleta_data_feature/
FEATURE_MAPPING=feature_mapping10.homepage
JAR=target/xgboost-1.0-SNAPSHOT-jar-with-dependencies.jar
source /home/sankuai/bin/kerberos_setup_new.sh
GET_DATA_CMD="$HADOOP jar $JAR  com.meituan.recommend.xgboost.GetData -Dmapreduce.job.queuename=$QUEUE -Dmapreduce.jobtracker.split.metainfo.maxsize=100000000  -Dyarn.app.mapreduce.am.resource.mb=8196 "
#GET_DATA_CMD="$HADOOP jar $JAR  com.meituan.recommend.xgboost.GetData -Dmapreduce.job.queuename=$QUEUE "

#$HADOOP fs -rmr $TRAIN_DATA_PATH
#$HADOOP fs -rmr $TEST_DATA_PATH
#
#echo "[INFO]: step 1 ....."
#$GET_DATA_CMD $TRAIN_DATE $TRAIN_DATA_PATH  $TRAIN_REDUCE_NUM   $TRAIN_IMPRESSION_SAMPLE_RATE $TRAIN_CLICK_SAMPLE_RATE $TRAIN_ORDER_SAMPLE_RATE $TRAIN_PAY_SAMPLE_RATE $FEATURE_MAPPING $FEATURE_PATH
#if (( $? != 0));then
#	exit -1
#fi
#
#echo "[INFO]: step 2 ....."
#$GET_DATA_CMD  $TEST_DATE $TEST_DATA_PATH  $TEST_REDUCE_NUM  $TEST_IMPRESSION_SAMPLE_RATE $TEST_CLICK_SAMPLE_RATE $TEST_ORDER_SAMPLE_RATE $TEST_PAY_SAMPLE_RATE $FEATURE_MAPPING $FEATURE_PATH
#
#
#if (( $? != 0));then
#	exit -1
#fi
#
source ./etc/dmlc-env.sh
QUEUE=root.hadoop-recsys.recomm


python  $WORMHOLE_HOME/tracker/dmlc_yarn.py -q $QUEUE -n $WORKER_NUM -mem $WORKER_MEMORY --jobname 'liyubing_rm_moredata' --vcores $WORKER_VCORES --ship-libcxx $GCC_HOME/lib64  $WORMHOLE_HOME/bin/xgboost.dmlc xgboost.conf \
	data=$HDFS_PATH$TRAIN_DATA_PATH  \
	eval[test]=$HDFS_PATH$TEST_DATA_PATH \
	model_out=$HDFS_PATH$MODEL_PATH


source ./etc/dmlc-env.sh

HADOOP=$HADOOP_HOME/bin/hadoop

rm -f $MODEL_NAME
$HADOOP fs -get $MODEL_PATH $MODEL_NAME

cat $FEATURE_MAPPING |awk  '{print (NR-1)"\t"$1"\tfloat"}' >feature_index

java -cp $JAR  com.meituan.recommend.xgboost.XGFeatureWeight $MODEL_NAME feature_index >feature_weight

cat feature_weight|awk -F',' '{if(NF==3){print $1 " " $2 "," $3 } else if (NF==4){print $1,$2,$3 "," $4}else {print $0}}' |sort -k2 -nr -t','>feature_weight.sort

java -cp $JAR  com.meituan.recommend.xgboost.ConvertToTextModel  $MODEL_NAME $MODEL_NAME.text

java -cp $JAR  com.meituan.recommend.xgboost.FileEncoder  $MODEL_NAME.text $MODEL_NAME.text.encode
