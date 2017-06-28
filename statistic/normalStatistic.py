#!/usr/bin/python
#! -*- coding:utf-8 -*-

from pyspark import SparkContext
from datetime import timedelta,datetime
import sys
import math
DATA_PATH = ""
DATA_OUT_PATH= ""

def strEncode(_str):
    if isinstance(_str,unicode):
        _str = _str.encode('utf-8')
    return _str

def get_statistic(line):
    if(line is None or len(line)==0):
        return None
    #201706010202479-SEAT 6-0-11-0-0,0,0,0,0,0,0
    seg0 = line.split("\t")
    if(len(seg0) != 2):
        return None
    seg1 = seg0[1].split("-")
    if(len(seg1)== 5):
        #返回格式:
        #seg0[0]:201706010202479-SEAT \t
        # 均值-中位数-方差-众数:众数对应人数-最大复点天数-最小复点天数-点击用户-复点用户-总点击数-总复点数-复点次数按天分布
        #get_statistic_execute(seg1[4]) 只把分布放进去,需要多算一次点击总数,
        return seg0[0]+"\t"+get_statistic_execute(seg1[4])+"-"+seg0[1]
    else:
        return None

def get_statistic_execute(line):
    #注意除0的问题
    if(line is None or len(line) == 0):
        return None
    seg = line.split(",")
    i = 0
    ele_sum = 0
    right_border = 0 #复点天数最大边界
    left_border = 0 #复点天数最小边界
    left_border_flag = 0 #复点天数最小边界flag
    max_ele = 0 #众数对应的最大分布
    ele_num = len(seg) #元素个数
    plural = 0 #众数
    avg = 0 #均值
    var = 0 #方差
    #avg_sum 用来保存每次元素值*元素所在的区间 之后除以元素值总数就是期望
    #two_time_avg_sum 用来保存每次元素值平方*元素所在区间 之后除以元素值总数就是x^2的期望
    #用公式 D(X)=E(X^2)-[E(X)]^2就可以求到方差
    avg_sum = 0
    two_time_avg_sum = 0
    median = 0
    #第一遍循环,找元素和等值
    for ele in seg:
        ele_sum += ele
        avg_sum += i*ele
        two_time_avg_sum += i*i*ele
        if ele > 0 :
            right_border = i
            if(left_border_flag == 0):
                left_border = i
                left_border_flag = 1
            if(ele > max_ele):
                max_ele = ele
                plural = i
        i += 1
    if ele_sum == 0 :
        ele_sum = 0.001
    avg = round(avg_sum /float(ele_sum),3)
    var = round(two_time_avg_sum/float(ele_sum) -avg*avg,3)
    mid_num = math.floor(ele_sum/2.0)
    ele_sum_for_med = 0 #累加元素,第一次大于元素的一半时就是中位数
    i = 0
    seg = [int(ele) for ele in seg]
    for ele in seg:
        ele_sum_for_med += ele
        if ele_sum_for_med >= mid_num:
            median = i
            break
        i += 1
    return str(avg)+"-"+str(median)+"-"+str(var)+"-"+str(plural)+":"+str(max_ele)+"-"+str(right_border)+"-"+str(left_border)

def getDataStatistic(sc):
    rawData = sc.textFile(DATA_PATH).map(lambda line:get_statistic(strEncode(line))
                                         ).filter(lambda line : line is not None
                                                  )
    rawData.saveAsTextFile(DATA_OUT_PATH)

if __name__ == '__main__':
    sc = SparkContext(appName="getStatistic/liyubing@meituan.com")
    getDataStatistic(sc)



