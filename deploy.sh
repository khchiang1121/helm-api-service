#!/bin/bash

# VirtFlow API Helm Chart 部署腳本

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數定義
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查 Helm 是否可用
check_helm() {
    if ! command -v helm &> /dev/null; then
        print_error "Helm 未安裝或不在 PATH 中"
        exit 1
    fi
    
    print_success "Helm 版本: $(helm version --short)"
}

# 檢查 kubectl 是否可用
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl 未安裝或不在 PATH 中"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "無法連接到 Kubernetes 集群"
        exit 1
    fi
    
    print_success "kubectl 配置正確"
}

# 驗證 Chart
validate_chart() {
    print_info "驗證 Helm Chart..."
    if helm lint ./virtflow-api; then
        print_success "Chart 驗證通過"
    else
        print_error "Chart 驗證失敗"
        exit 1
    fi
}

# 安裝 Chart
install_chart() {
    local release_name=$1
    local values_file=$2
    
    print_info "安裝 Helm Chart: $release_name"
    
    if [ -n "$values_file" ] && [ -f "$values_file" ]; then
        print_info "使用 values 文件: $values_file"
        helm install "$release_name" ./virtflow-api -f "$values_file" --wait --timeout 10m
    else
        helm install "$release_name" ./virtflow-api --wait --timeout 10m
    fi
    
    print_success "Chart 安裝完成"
}

# 升級 Chart
upgrade_chart() {
    local release_name=$1
    local values_file=$2
    
    print_info "升級 Helm Chart: $release_name"
    
    if [ -n "$values_file" ] && [ -f "$values_file" ]; then
        print_info "使用 values 文件: $values_file"
        helm upgrade "$release_name" ./virtflow-api -f "$values_file" --wait --timeout 10m
    else
        helm upgrade "$release_name" ./virtflow-api --wait --timeout 10m
    fi
    
    print_success "Chart 升級完成"
}

# 卸載 Chart
uninstall_chart() {
    local release_name=$1
    
    print_warning "卸載 Helm Chart: $release_name"
    read -p "確定要繼續嗎？(y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        helm uninstall "$release_name"
        print_success "Chart 卸載完成"
    else
        print_info "取消卸載操作"
    fi
}

# 檢查部署狀態
check_status() {
    local release_name=$1
    
    print_info "檢查部署狀態: $release_name"
    
    echo ""
    print_info "Helm Release 狀態："
    helm status "$release_name"
    
    echo ""
    print_info "Pod 狀態："
    kubectl get pods -l app.kubernetes.io/instance="$release_name"
    
    echo ""
    print_info "Service 狀態："
    kubectl get services -l app.kubernetes.io/instance="$release_name"
    
    echo ""
    print_info "Ingress 狀態："
    kubectl get ingress -l app.kubernetes.io/instance="$release_name"
    
    echo ""
    print_info "HPA 狀態："
    kubectl get hpa -l app.kubernetes.io/instance="$release_name"
}

# 查看日誌
show_logs() {
    local release_name=$1
    
    print_info "查看 Pod 日誌: $release_name"
    
    local pod_name=$(kubectl get pods -l app.kubernetes.io/instance="$release_name" -o jsonpath='{.items[0].metadata.name}')
    if [ -n "$pod_name" ]; then
        print_info "顯示 Pod $pod_name 的日誌："
        kubectl logs -f "$pod_name" -l app.kubernetes.io/instance="$release_name"
    else
        print_error "找不到 Pod"
    fi
}

# 查看生成的 YAML
show_template() {
    local release_name=$1
    local values_file=$2
    
    print_info "生成 YAML 模板: $release_name"
    
    if [ -n "$values_file" ] && [ -f "$values_file" ]; then
        helm template "$release_name" ./virtflow-api -f "$values_file"
    else
        helm template "$release_name" ./virtflow-api
    fi
}

# 測試部署
test_deployment() {
    local release_name=$1
    
    print_info "測試部署: $release_name"
    
    # 等待 Pod 就緒
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance="$release_name" --timeout=300s
    
    # 獲取服務 URL
    local service_name=$(kubectl get service -l app.kubernetes.io/instance="$release_name" -o jsonpath='{.items[0].metadata.name}')
    local service_port=$(kubectl get service -l app.kubernetes.io/instance="$release_name" -o jsonpath='{.items[0].spec.ports[0].port}')
    
    print_info "服務名稱: $service_name"
    print_info "服務端口: $service_port"
    
    # 測試健康檢查端點
    print_info "測試健康檢查端點..."
    kubectl run test-health --image=curlimages/curl --rm -it --restart=Never -- curl -f "http://$service_name:$service_port/health/"
    
    if [ $? -eq 0 ]; then
        print_success "健康檢查通過"
    else
        print_error "健康檢查失敗"
    fi
}

# 顯示幫助信息
show_help() {
    echo "VirtFlow API Helm Chart 部署腳本"
    echo ""
    echo "用法: $0 [命令] [選項]"
    echo ""
    echo "命令:"
    echo "  install <release-name> [values-file]    安裝 Chart"
    echo "  upgrade <release-name> [values-file]   升級 Chart"
    echo "  uninstall <release-name>               卸載 Chart"
    echo "  status <release-name>                  檢查部署狀態"
    echo "  logs <release-name>                    查看應用程式日誌"
    echo "  template <release-name> [values-file]  查看生成的 YAML"
    echo "  test <release-name>                    測試部署"
    echo "  validate                                驗證 Chart"
    echo "  help                                    顯示此幫助信息"
    echo ""
    echo "範例:"
    echo "  $0 install virtflow-dev values-dev.yaml"
    echo "  $0 upgrade virtflow-prod values-prod.yaml"
    echo "  $0 status virtflow-dev"
    echo "  $0 test virtflow-prod"
    echo ""
}

# 主程序
main() {
    case "${1:-help}" in
        install)
            if [ -z "$2" ]; then
                print_error "請提供 release 名稱"
                echo "用法: $0 install <release-name> [values-file]"
                exit 1
            fi
            check_helm
            check_kubectl
            validate_chart
            install_chart "$2" "$3"
            check_status "$2"
            ;;
        upgrade)
            if [ -z "$2" ]; then
                print_error "請提供 release 名稱"
                echo "用法: $0 upgrade <release-name> [values-file]"
                exit 1
            fi
            check_helm
            check_kubectl
            validate_chart
            upgrade_chart "$2" "$3"
            check_status "$2"
            ;;
        uninstall)
            if [ -z "$2" ]; then
                print_error "請提供 release 名稱"
                echo "用法: $0 uninstall <release-name>"
                exit 1
            fi
            check_helm
            check_kubectl
            uninstall_chart "$2"
            ;;
        status)
            if [ -z "$2" ]; then
                print_error "請提供 release 名稱"
                echo "用法: $0 status <release-name>"
                exit 1
            fi
            check_kubectl
            check_status "$2"
            ;;
        logs)
            if [ -z "$2" ]; then
                print_error "請提供 release 名稱"
                echo "用法: $0 logs <release-name>"
                exit 1
            fi
            check_kubectl
            show_logs "$2"
            ;;
        template)
            if [ -z "$2" ]; then
                print_error "請提供 release 名稱"
                echo "用法: $0 template <release-name> [values-file]"
                exit 1
            fi
            check_helm
            show_template "$2" "$3"
            ;;
        test)
            if [ -z "$2" ]; then
                print_error "請提供 release 名稱"
                echo "用法: $0 test <release-name>"
                exit 1
            fi
            check_kubectl
            test_deployment "$2"
            ;;
        validate)
            check_helm
            validate_chart
            ;;
        help|*)
            show_help
            ;;
    esac
}

# 執行主程序
main "$@" 