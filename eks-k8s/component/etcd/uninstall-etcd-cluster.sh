
#!/usr/bin/env bash

set -euo pipefail

# 卸载 etcd 集群脚本（开发环境用）
# 功能：可选备份快照 -> 删除 StatefulSet/Service -> 删除 PVC -> 可选删除 Namespace
# 使用：
#   ./uninstall-etcd-cluster.sh            # 交互式确认后执行
#   ./uninstall-etcd-cluster.sh -y         # 不交互，直接执行
#   ./uninstall-etcd-cluster.sh --no-backup # 不做快照备份

NAMESPACE="component"
BACKUP=true
AUTO_YES=false

usage() {
	cat <<EOF
Usage: $0 [options]
Options:
	-y, --yes           Skip confirmation prompts
	--no-backup         Skip etcd snapshot backup
	-h, --help          Show this help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		-y|--yes) AUTO_YES=true; shift ;;
		--no-backup) BACKUP=false; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "Unknown option: $1"; usage; exit 1 ;;
	esac
done

confirm() {
	if [ "$AUTO_YES" = true ]; then
		return 0
	fi
	read -rp "$1 [y/N]: " ans
	case "$ans" in
		[Yy]*) return 0 ;;
		*) return 1 ;;
	esac
}

echo "目标命名空间: $NAMESPACE"

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
	echo "命名空间 $NAMESPACE 不存在，退出。"
	exit 1
fi

if [ "$BACKUP" = true ]; then
	if confirm "是否在继续之前为 etcd-cluster-0 做 snapshot 备份（推荐）?"; then
		echo "尝试在 pod etcd-cluster-0 上创建快照并拷贝到当前目录..."
		set +e
		kubectl exec -n "$NAMESPACE" etcd-cluster-0 -- etcdctl --endpoints=http://etcd-service.${NAMESPACE}.svc.cluster.local:2379 snapshot save /tmp/etcd-snap.db
		KUBECTL_EXIT=$?
		if [ $KUBECTL_EXIT -eq 0 ]; then
			SNAP_NAME="etcd-snap-$(date +%s).db"
			kubectl cp "$NAMESPACE"/etcd-cluster-0:/tmp/etcd-snap.db "./$SNAP_NAME" || echo "警告：快照拷贝失败，请手动检查 pod 内 /tmp/etcd-snap.db"
			echo "快照已保存为 ./$SNAP_NAME"
		else
			echo "警告：无法在 etcd-cluster-0 上创建快照（pod 可能不可用），跳过备份。"
		fi
		set -e
	else
		echo "跳过备份。"
	fi
else
	echo "备份已被禁用，继续。"
fi

if ! confirm "将删除 etcd StatefulSet、Service、PVC（这将丢失该节点上的数据）。确认继续?"; then
	echo "已取消操作。"
	exit 0
fi

echo "删除 etcd StatefulSet..."
kubectl delete statefulset etcd-cluster -n "$NAMESPACE" --ignore-not-found

echo "删除 etcd 服务..."
kubectl delete svc etcd-headless etcd-service -n "$NAMESPACE" --ignore-not-found

echo "等待 pods 被删除..."
kubectl wait --for=delete pod -l app=etcd-cluster -n "$NAMESPACE" --timeout=180s || echo "注意：pod 未完全删除，继续下一步。"

echo "删除 etcd PVCs（会删除持久数据）..."
kubectl delete pvc -l app=etcd-cluster -n "$NAMESPACE" --ignore-not-found

echo "完成资源删除。"

echo "注意：PV 的回收策略取决于 StorageClass（如为 Retain，则需要手动删除 PV）；如需删除命名空间也可执行："
echo "  kubectl delete namespace $NAMESPACE"

echo "脚本结束。请检查 PVC/PV 状态与集群健康。"

