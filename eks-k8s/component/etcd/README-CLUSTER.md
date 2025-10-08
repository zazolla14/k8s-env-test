# etcd 集群部署指南

## 概述

本配置将部署一个包含3个节点的etcd集群，提供高可用的分布式键值存储服务。

## 文件说明

- `etcd-statefulset.yml` - etcd集群StatefulSet配置
- `etcd-service.yml` - etcd集群服务配置
- `deploy-etcd-cluster.sh` - 自动部署脚本
- `test-etcd-cluster.sh` - 集群测试脚本

## 集群架构

- **节点数量**: 3个节点
- **集群令牌**: etcd-cluster-token
- **数据持久化**: 每个节点10Gi存储
- **端口**: 
  - 2379 - 客户端通信端口
  - 2380 - 节点间通信端口

## 部署步骤

### 1. 快速部署（推荐）

```bash
cd /Users/wei/Documents/copilot-work/akachat/component/etcd
./deploy-etcd-cluster.sh
```

### 2. 手动部署

```bash
# 1. 创建命名空间
kubectl apply -f ../namespace.yml

# 2. 部署StatefulSet
kubectl apply -f etcd-statefulset.yml

# 3. 创建服务
kubectl apply -f etcd-service.yml

# 4. 等待Pod启动
kubectl wait --for=condition=ready pod -l app=etcd-cluster -n component --timeout=300s
```

## 验证部署

### 检查Pod状态
```bash
kubectl get pods -l app=etcd-cluster -n component
```

### 检查服务状态
```bash
kubectl get svc etcd-service -n component
```

### 运行集群测试
```bash
./test-etcd-cluster.sh
```

## 连接etcd集群

### 从Pod内连接
```bash
kubectl exec -it etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 endpoint health
```

### 应用程序连接

**服务地址**: `etcd-service.component.svc.cluster.local:2379`

**Go客户端配置示例**:
```go
import (
    clientv3 "go.etcd.io/etcd/client/v3"
)

config := clientv3.Config{
    Endpoints:   []string{"etcd-service.component.svc.cluster.local:2379"},
    DialTimeout: 5 * time.Second,
}
client, err := clientv3.New(config)
```

**Python客户端配置示例**:
```python
import etcd3

etcd = etcd3.client(
    host='etcd-service.component.svc.cluster.local',
    port=2379
)
```

## etcd管理命令

### 查看集群成员
```bash
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 member list
```

### 检查集群健康状态
```bash
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 endpoint health
```

### 查看集群状态
```bash
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 endpoint status --write-out=table
```

### 数据操作
```bash
# 写入数据
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 put key1 value1

# 读取数据
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 get key1

# 列出所有键
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 get --prefix ""

# 删除数据
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 del key1
```

## 故障排除

### 1. Pod无法启动
```bash
kubectl describe pod etcd-cluster-0 -n component
kubectl logs etcd-cluster-0 -n component
```

### 2. 集群无法形成
检查网络连接和DNS解析：
```bash
kubectl exec etcd-cluster-0 -n component -- nslookup etcd-cluster-1.etcd-headless.component.svc.cluster.local
```

### 3. 重新初始化集群
```bash
# 删除现有集群
kubectl delete statefulset etcd-cluster -n component
kubectl delete pvc etcd-data-etcd-cluster-0 etcd-data-etcd-cluster-1 etcd-data-etcd-cluster-2 -n component

# 重新部署
./deploy-etcd-cluster.sh
```

### 4. 数据备份
```bash
# 创建快照
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 snapshot save /etcd-data/backup.db

# 恢复快照（需要停止etcd服务）
kubectl exec etcd-cluster-0 -n component -- etcdctl snapshot restore /etcd-data/backup.db --data-dir /etcd-data-restore
```

## 扩展和维护

### 添加新成员
```bash
# 1. 添加成员到集群
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 member add etcd-cluster-3 --peer-urls=http://etcd-cluster-3.etcd-headless.component.svc.cluster.local:2380

# 2. 增加StatefulSet副本数
kubectl scale statefulset etcd-cluster --replicas=4 -n component
```

### 移除成员
```bash
# 1. 获取成员ID
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 member list

# 2. 移除成员
kubectl exec etcd-cluster-0 -n component -- etcdctl --endpoints=http://etcd-service.component.svc.cluster.local:2379 member remove <MEMBER_ID>

# 3. 减少StatefulSet副本数
kubectl scale statefulset etcd-cluster --replicas=2 -n component
```

## 性能优化建议

1. **资源配置**: 根据实际负载调整CPU和内存限制
2. **存储**: 使用高IOPS的SSD存储
3. **网络**: 确保集群节点间的网络延迟尽可能低
4. **压缩**: 启用自动压缩以减少存储空间使用
5. **监控**: 部署etcd监控工具

## 安全注意事项

- 在生产环境中启用TLS加密
- 配置客户端认证
- 限制网络访问权限
- 定期备份数据
- 监控集群健康状态

## 注意事项

- etcd集群需要奇数个节点来避免脑裂
- 建议至少3个节点以保证高可用性
- 确保有足够的资源（CPU、内存、存储、网络）来支持集群运行
- etcd对网络延迟比较敏感，建议部署在同一可用区内
