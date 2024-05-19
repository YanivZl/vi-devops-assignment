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

  access_entries = {
    for user_arn in local.eks_auth_users : 
    basename(user_arn) => {
      kubernetes_group = []
      principal_arn    = user_arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    gp-managed-node-group = {
      node_group_name = var.eks_intial_node_group_name
      instance_types  = ["t3.medium"]

      min_size     = var.eks_intial_node_group_min_size
      max_size     = var.eks_intial_node_group_max_size
      desired_size = var.eks_intial_node_group_desired_size
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
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

  tags = local.tags
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
  aws_load_balancer_controller        = {}

  # ArgoCD Addon
  enable_argocd = true
  argocd = {
    set = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      }
    ]
  }

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
