module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version  = "~> 21.0"

  name  = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  endpoint_public_access  = true
  enable_cluster_creator_admin_permissions  = true

  vpc_id  = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets

  addons = {
    vpc-cni = {
      before_compute  = true
    }
    kube-proxy  = {}
    coredns  = {}
    aws-ebs-csi-driver  = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types  = ["t3.medium"]
      min_size  = 2
      max_size  = 2
      desired_size  = 2

      iam_role_additional_policies = {
        ebs = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
}

resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner  = "ebs.csi.aws.com"
  volume_binding_mode  = "WaitForFirstConsumer"
  parameters = {
    type = "gp3"
  }
}
