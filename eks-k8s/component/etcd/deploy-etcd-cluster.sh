#!/bin/bash

# etcd集群部署脚本

set -e

echo "开始部署etcd集群..."

# 2. 部署etcd StatefulSet
echo "2. 部署etcd StatefulSet..."
kubectl apply -f etcd-statefulset.yml

# 3. 创建Service
echo "3. 创建etcd服务..."
kubectl apply -f etcd-service.yml

# 4. 等待所有Pod准备就绪
echo "4. 等待etcd节点启动..."
kubectl wait --for=condition=ready pod -l app=etcd-cluster -n component --timeout=300s

echo "etcd集群部署完成！"

# 显示集群状态
echo "检查集群状态："
kubectl get pods -l app=etcd-cluster -n component
kubectl get svc etcd-headless -n component

echo ""
echo "连接etcd集群示例："
echo "kubectl exec -it etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 endpoint health"

echo ""
echo "检查集群成员："
echo "kubectl exec -it etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 member list"
