# Local Kubernetes Cluster

## From Archived repo:
https://github.com/PsimonL/Kubernetes-Cluster-Setup/blob/main/K8S-vms-kubeadm-cluster/README.md

## Project contains two folders:
1. local-cluster ---> Is based on local cluster infrastructure, based on hypervisor like Virtual Box, of course used K8S, Docker, Ansible, and tools from Hashicorp like Vagrant and Terraform.  
2. Azure cluster ---> Based on Azure Cloud or AWS Cloud - access granted by unversity and faculty. 
Cloud provider is available at: https://github.com/PsimonL/K8S-AWS-cluster     
Azure Cloud have been picked finally, cause AWS student account run out of license validity period.

### The local cluster description:  
I've used VirtualBox as my hypervisor, but analogically VMWare, Hyper-V should also work as well.  
- First of all, I've used Vagrant to automatically configure environmets for cluster which contains of 3 machines (1 controlplane and 2 workers, of course there should be back up controlplane as "good practices" suggest in Kubernetes documentation, but it's for pure learning purposes so I'll skip this step). 
- Originally I've wanted to use Ansible but my physical OS is Windows so, it wasn't possible due to Ansible's core design ideas, but It's good to remember that it can easily configure Windows host and use Powershell. 
- I've also used "ansible_local" provisioner for which is triggered by Vagrantfile, and by synced folder sent to certain host, runs locally. Ansible configures cluster and controlplane basic set up, downloads required dependencies and sets up cluster nodes in "Ready" status. 
- To play with Kubernetes I've used Terraform and classic yaml files for example for deployments, scalling, etc.
- There are also usefull scripts in Bash and Python.

#### TODO:
Finish deployments and strictly cluster side, with Ingress, Services, Security stuff etc. Also add simple app deployment like Nginx server just to test the monitor of the cluster work itself.

## Helpful resources and links:
- [https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [https://security.padok.fr/en/blog/role-based-access-kubernetes](https://security.padok.fr/en/blog/role-based-access-kubernetes)
- [https://developer.hashicorp.com/vagrant/docs/synced-folders/basic_usage](https://developer.hashicorp.com/vagrant/docs/synced-folders/basic_usage)
- [https://security.padok.fr/en/blog/role-based-access-kubernetes](https://security.padok.fr/en/blog/role-based-access-kubernetes)
- [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)
- [https://kubernetes.io/docs/reference/labels-annotations-taints/](https://kubernetes.io/docs/reference/labels-annotations-taints/)
- [https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- [https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/](https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/)
- [https://developer.hashicorp.com/vagrant/docs/synced-folders/basic_usage](https://developer.hashicorp.com/vagrant/docs/synced-folders/basic_usage)
- [https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/](https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/)
- [https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_local](https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_local)
- [https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises)
- [https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)
- [https://computingforgeeks.com/deploy-kubernetes-cluster-using-vagrant-terraform/?expand_article=1#google_vignette](https://computingforgeeks.com/deploy-kubernetes-cluster-using-vagrant-terraform/?expand_article=1#google_vignette)
- [https://computingforgeeks.com/deploy-kubernetes-cluster-using-vagrant-terraform/?expand_article=1#google_vignette](https://computingforgeeks.com/deploy-kubernetes-cluster-using-vagrant-terraform/?expand_article=1#google_vignette)
- [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)
- [https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)
- [https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises)
- [(https://www.tecmint.com/deploy-nginx-on-a-kubernetes-cluster/](https://www.tecmint.com/deploy-nginx-on-a-kubernetes-cluster/)
- [https://computingforgeeks.com/deploy-kubernetes-cluster-using-vagrant-terraform/?expand_article=1#google_vignette](https://computingforgeeks.com/deploy-kubernetes-cluster-using-vagrant-terraform/?expand_article=1#google_vignette)
- [https://docs.ansible.com/](https://docs.ansible.com/)
- [https://kubernetes.io/docs/concepts/scheduling-eviction/](https://kubernetes.io/docs/concepts/scheduling-eviction/)
- [https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/)
- [https://grafana.com/docs/loki/latest/installation/docker/](https://grafana.com/docs/loki/latest/installation/docker/)
- [https://grafana.com/docs/loki/latest/installation/](https://grafana.com/docs/loki/latest/installation/)
- [https://grafana.com/docs/grafana/latest/setup-grafana/installation/redhat-rhel-fedora/](https://grafana.com/docs/grafana/latest/setup-grafana/installation/redhat-rhel-fedora/)
- [https://grafana.com/docs/loki/latest/send-data/promtail/](https://grafana.com/docs/loki/latest/send-data/promtail/)
- [https://docs.ansible.com/](https://docs.ansible.com/)
- [https://www.proxmox.com/en/downloads](https://www.proxmox.com/en/downloads)
- [https://www.velia.net/shop/region/strasbourg](https://www.velia.net/shop/region/strasbourg)
- [https://www.openstack.org/](https://www.openstack.org/)