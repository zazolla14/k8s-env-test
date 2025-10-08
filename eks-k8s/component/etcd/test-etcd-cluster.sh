#!/bin/bash

# etcd集群测试脚本

echo "etcd集群状态测试"
echo "=================="

echo "1. 检查集群成员状态："
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 member list

echo ""
echo "2. 检查集群健康状态："
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 endpoint health

echo ""
echo "3. 检查集群状态："
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 endpoint status --write-out=table

echo ""
echo "4. 测试数据写入和读取："
echo "写入测试数据..."
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 put test-key "Hello etcd Cluster"

echo "从不同节点读取数据..."
for i in 0 1 2; do
    echo "从 etcd-cluster-${i} 读取："
    kubectl exec etcd-cluster-${i} -n component -- etcdctl --endpoints=http://etcd-cluster-${i}.etcd-headless.component.svc.cluster.local:2379 get test-key || echo "节点 ${i} 可能还在启动中"
done

echo ""
echo "5. 检查所有键值："
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 get --prefix ""

echo ""
echo "etcd集群测试完成！"
