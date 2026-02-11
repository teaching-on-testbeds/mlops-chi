
::: {.cell .markdown}

## Deploy Kubernetes using Ansible

Now that we understand a little bit about how Ansible works, we will use it to deploy Kubernetes on our three-node cluster! 

We will use Kubespray, an Ansible-based tool, to automate this deployment.

![Using Ansible for software installation and system configuration.](images/step2-ansible.svg)


:::


::: {.cell .markdown}

### Preliminaries

:::

::: {.cell .markdown}

As before, let's make sure we'll be able to use the Ansible executables. We need to put the install directory in the `PATH` inside each new Bash session.

:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
export PATH=/work/.local/bin:$PATH
export PYTHONUSERBASE=/work/.local
```
:::



::: {.cell .markdown}

### Run a preliminary playbook

Before we set up Kubernetes, we will run a preliminary playbook to:

* disable the host firewall on the nodes in the cluster. (The cloud infrastructure provider will anyway block all traffic except for SSH traffic on port 22, as we specified in the security group configuration.) We will also configure each node to permit the local container registry.
* and, configure Docker to use the local registry. (We prefer to do this before deploying Kubernetes, to avoid restarting Docker when there is a live Kubernetes deployment using it already...)

:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
cd /work/gourmetgram-iac/ansible
ansible-playbook -i inventory.yml pre_k8s/pre_k8s_configure.yml
```
:::


::: {.cell .markdown}

### Run the Kubespray play

Then, we can run the Kubespray playbook! Inside the `ansible/k8s` subdirectory:

* we have a "copy" of Kubespray as a submodule
* and we have a minimal `inventory` directory, which describes the specific Kubespray configuration for our cluster

The following cell will run for a long time - potentially up to an hour! - and install Kubernetes on the three-node cluster.

When it is finished the "PLAY RECAP" should indicate that none of the tasks failed.

:::

::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
export ANSIBLE_CONFIG=/work/gourmetgram-iac/ansible/ansible.cfg
export ANSIBLE_ROLES_PATH=roles
```
:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
cd /work/gourmetgram-iac/ansible/k8s/kubespray
ansible-playbook -i ../inventory/mycluster --become --become-user=root ./cluster.yml
```
:::
