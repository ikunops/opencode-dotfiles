# K8S 知识库索引

## 课程总览
| 文件 | 说明 |
|------|------|
| 01-课程笔记总结.md | 课程整体笔记总结 |
| 02-学习路线图.md | 13 阶段学习路线 |
| 03-思维导图.md | 全课程思维导图（XMind 可导入） |

## 基础篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 01-Docker容器基础.md | Docker 概念、架构、安装、镜像、Dockerfile、Volume、网络模式 | docker, image, container, dockerfile, volume |
| 02-Pod入门与实战.md | Pod 定义、生命周期、重启策略、Init 容器、Sidecar | pod, init container, sidecar, yaml |
| 03-kubectl命令行工具.md | kubectl 语法、常用命令、输出格式 | kubectl, apply, get, describe, logs, exec |
| 04-Pod启动探测.md | livenessProbe、readinessProbe、startupProbe | probe, health check, liveness, readiness |
| 05-临时容器.md | kubectl debug、临时容器调试 | ephemeral, debug, kubectl debug |

## 控制器篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 06-ReplicaSet和Deployment控制器.md | ReplicaSet 副本控制、Deployment 滚动更新/回滚 | replicaset, deployment, rollout, rolling update |
| 07-StatefulSet控制器.md | 有状态服务、稳定网络标识、有序启停 | statefulset, headless service, stateful |
| 08-DaemonSet控制器.md | 每个 Node 一个 Pod、日志收集、监控 | daemonset, daemon, node agent |

## 网络篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 09-Service负载均衡.md | ClusterIP/NodePort/LB/ExternalName、CoreDNS | service, clusterip, nodeport, coredns |
| 10-CNI网络插件.md | Flannel/Calico/Canal 部署与切换 | cni, flannel, calico, network plugin |
| 11-kube-proxy IPVS模式.md | iptables vs ipvs、性能优化 | kube-proxy, ipvs, iptables, 性能 |
| 12-IngressController高可用.md | Ingress Controller 安装、高可用部署 | ingress, controller, 高可用 |
| 13-Ingress灰度发布.md | header/cookie/weight 灰度策略 | ingress, canary, 灰度发布, traffic split |

## 配置与存储篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 14-ConfigMap配置管理.md | ConfigMap 创建、挂载、热更新 | configmap, 配置, 挂载 |
| 15-Secret配置管理.md | Secret 类型、创建、挂载 | secret, 密码, tls, docker-registry |
| 16-持久化存储PV-PVC.md | PV/PVC/StorageClass、动态供给 | pv, pvc, storageclass, 持久化 |
| 17-Ceph分布式存储.md | Ceph 部署、RBD、CephFS | ceph, rbd, cephfs, 分布式存储 |

## 安全篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 18-RBAC安全机制.md | Role/ClusterRole/RoleBinding/ServiceAccount | rbac, role, sa, 权限, 安全 |

## 集群搭建篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 19-kubeadm单master集群搭建.md | kubeadm 单节点部署 | kubeadm, 单master, 部署 |
| 20-kubeadm多master高可用集群.md | 多 master + keepalived + haproxy | kubeadm, 高可用, 多master, keepalived |
| 21-kubeadm快速初始化集群.md | 快速部署脚本 | kubeadm, 快速, 初始化 |
| 22-kubeadm初始化1.23版-containerd.md | containerd 运行时、1.23 版本 | kubeadm, 1.23, containerd |
| 23-kubeadm安装1.24高可用集群.md | 1.24 版本新特性、高可用 | kubeadm, 1.24, 高可用 |
| 24-二进制安装多master集群.md | 二进制手动部署、证书签发 | 二进制, 手工部署, 证书, tls |
| 25-Rancher管理k8s集群.md | Rancher 部署、集群管理 | rancher, 多集群管理 |
| 26-K3s轻量级k8s.md | K3s 安装、边缘场景 | k3s, 轻量级, edge, iot |

## 运维与扩展篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 27-Helm包管理工具.md | Helm chart、模板、仓库 | helm, chart, 包管理 |
| 28-HPA-VPA自动扩缩容.md | HPA/VPA/metrics-server | hpa, vpa, autoscale, metrics |
| 29-CRD自定义资源.md | CRD、Operator、controller-runtime | crd, operator, 自定义资源 |

## 实战与监控篇
| 文件 | 专题 | 关键词 |
|------|------|--------|
| 30-SpringCloud电商项目实战.md | SpringCloud 微服务上 K8s | springcloud, 微服务, 实战 |
| 31-Prometheus+Grafana监控系统.md | Prometheus 部署、Grafana 面板 | prometheus, grafana, 监控 |
| 32-日志收集平台.md | EFK/ELK、Filebeat、Logstash | 日志, efk, elk, filebeat, logstash |
| 33-全链路监控.md | Jaeger、SkyWalking、链路追踪 | 链路追踪, jaeger, skywalking |
| 34-Jenkins+DevOps容器云平台.md | Jenkins pipeline、GitOps | jenkins, devops, ci/cd, pipeline |
| 35-Tekton原生CI-CD.md | Tekton pipeline、task、trigger | tekton, ci/cd, pipeline as code |
| 36-Istio服务网格.md | Istio 安装、流量管理、安全、可观测性 | istio, 服务网格, sidecar, 流量管理 |
