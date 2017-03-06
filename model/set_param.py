import os
import time
import re

#ISOTIMEFORMAT="%Y-%m-%d"
#print time.strftime(ISOTIMEFORMAT,time.localtime())
def set_conf(eta,depth,colsample,subsample,trees,min_child,period,conf):
    fi = open(conf)
    fo = open("tmp.conf","w")
    for line in fi:
        if line[0] == "#":
            print >> fo, line.strip()
        elif "eta" in line:
            print >> fo, "eta=" + str(eta)
        elif "max_depth" in line:
            print >> fo, "max_depth=" + str(depth)
        elif "colsample_bytree" in line:
            print >> fo, "colsample_bytree=" + str(colsample)
        elif "subsample" in line:
            print >> fo, "subsample=" + str(subsample)
        elif "num_round" in line:
            print >> fo, "num_round=" + str(trees)
        elif "min_child_weight" in line:
            print >> fo, "min_child_weight=" + str(min_child)
        else:
            print >> fo, line.strip()
    fi.close()
    fo.close()
    os.system('mv tmp.conf '+conf)

d = []
d_eval = {}
tree = 100
period = 100
d_evals = {}
#eta = [0.13,0.15,0,17,0.19,0.2,0.21,0.23,0.25]
eta = [0.15]
depth = [9]
#depth = [8]
#colsample = [0.8,0.85,0.9,0.95,1]
colsample = [0.8,0.9]
#minchild = [1,3,5]
minchild = [1]
#subsample = [0.8,0.9]
subsample = [0.8,0.9]
conf = "xgboost.conf"
for dep in depth:
    for col in colsample:
        for e in eta:
            for child in minchild:
                for sub in subsample:
                    set_conf(e,dep,col,sub,tree,child,period,conf)
                    os.system("bash param_train.sh &> run.log ")
                    fi = open('run.log')
                    for line in fi:
                        if '[99]' in line and 'INFO' not in line:
                            key = 'dep:'+str(dep)+' col:'+str(col)+' e:'+str(e)+' child:'+str(child)+' sub:'+str(sub)
                            auc = re.split('\t|:',line.strip())[2]
                            d.append((key,auc))
                    fi.close()
                    filename = str(dep)+'_'+str(child)+'_'+str(col*10)+'_'+str(sub*10)+'_'+str(e*100)
                    os.system("rm -r "+filename)
                    os.system("mkdir "+filename)
                    os.system("mv run.log "+filename)
                    os.system("mv feature_weight.sort "+filename)
                    os.system("cp xgboost.conf "+filename)
sorted(d,key=lambda line:line[1],reverse=True )
fo = open('param_result','w')
print >> fo,[str_res[0]+'\t'+str_res[1] for str_res in d ]
fo.close()




