###########################################################
# VPC
###########################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = var.name
  }

  tags = local.tags
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name                             = "${var.name}-eks"
  cluster_version                          = var.eks_cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    gp-managed-node-group = {
      node_group_name = var.eks_intial_node_group_name
      instance_types  = ["t3.medium"]

      min_size      = var.eks_intial_node_group_min_size
      max_size      = var.eks_intial_node_group_max_size
      desired_size  = var.eks_intial_node_group_desired_size

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }

  enable_efa_support = true


  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.name
  })
}

################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Deploy AWS Load Balancer Controller 
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {}

  # ArgoCD Addon
  # enable_argocd = true
  # argocd = {
  #   set = [
  #     {
  #       name  = "server.service.type"
  #       value = "LoadBalancer"
  #     }
  #   ]
  # }
  # enable_argo_rollouts = true

  # Prometheus Grafana
  # enable_kube_prometheus_stack = true

  helm_releases = {
    # mongodb = {
    #   name             = "mongodb"
    #   repository       = "https://charts.bitnami.com/bitnami"
    #   chart            = "mongodb"
    #   version          = "15.4.3"
    #   namespace        = "mongodb"
    #   create_namespace = true

    #   set = [
    #     {
    #       name  = "global.storageClass"
    #       value = "gp2"
    #     },
    #     {
    #       name  = "architecture"
    #       value = "replicaset"
    #     },
    #     # {
    #     #   name  = "service.type"
    #     #   value = "LoadBalancer"
    #     # },
    #     # {
    #     #   name = "auth.rootPassword"
    #     #   value = "mongoadmin123"
    #     # }
    #   ]
    # },
    # reflactor = {
    #   name       = "reflector"
    #   repository = "https://emberstack.github.io/helm-charts"
    #   chart      = "reflector"
    #   version    = "7.1.262"
    #   namespace  = "kube-system"
    # },
    # karpenter = {
    #   name       = "karpenter"
    #   repository = "oci://public.ecr.aws/karpenter"
    #   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    #   repository_password = data.aws_ecrpublic_authorization_token.token.password
    #   chart               = "karpenter"
    #   version             = "0.36.1"
    #   wait                = false
    #   namespace  = "kube-system"
    #   values = [
    #     <<-EOT
    #     nodeSelector:
    #       karpenter.sh/controller: 'true'
    #     tolerations:
    #       - key: CriticalAddonsOnly
    #         operator: Exists
    #       - key: karpenter.sh/controller
    #         operator: Exists
    #         effect: NoSchedule
    #     settings:
    #       clusterName: ${module.eks.cluster_name}
    #       clusterEndpoint: ${module.eks.cluster_endpoint}
    #       interruptionQueue: ${module.karpenter.queue_name}
    #     EOT
    #   ]
    # }
  }
}

################################################################################
# IRSA for EBS CSI
################################################################################

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

################################################################################
# ALB Ingress resource
################################################################################

# resource "kubernetes_ingress_v1" "alb_ingress" {
#   metadata {
#     name      = "alb-ingress"
#     namespace = "default"
#     annotations = {
#       "alb.ingress.kubernetes.io/scheme" : "internet-facing"
#       "alb.ingress.kubernetes.io/target-type" : "ip"
#     }
#   }
#   spec {
#     ingress_class_name = "alb"
#     rule {
#       host = "service1.vi-technologies.com"
#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "service1"
#               port {
#                 number = 3000
#               }
#             }
#           }
#         }
#       }
#     }

#     rule {
#       host = "service2.vi-technologies.com"
#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "service2"
#               port {
#                 number = 3001
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

################################################################################
# Karpenter Controller & Node IAM roles, SQS Queue, Eventbridge Rules, EC2NodeClass
################################################################################

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "0.36.1"
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.9"

  cluster_name = module.eks.cluster_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = var.name
  create_pod_identity_association = true

  tags = local.tags
}

resource "kubectl_manifest" "karpenter_node_pool" {
  depends_on = [
    helm_release.karpenter
  ]

  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        name: default
      requirements:
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["spot", "on-demand"]
        - key: "karpenter.k8s.aws/capacity-type"
          operator: In
          values: ["c", "m", "r"]
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["4", "8"]
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["2"]
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
  YAML
}

resource "kubectl_manifest" "karpenter_ec2_node_class" {
  depends_on = [
    helm_release.karpenter
  ]

  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: ${var.name}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${var.name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${var.name}
  tags:
    karpenter.sh/discovery: ${var.name}
  YAML
}

