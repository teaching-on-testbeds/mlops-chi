
### Install and configure Ansible

:::


::: {.cell .markdown}

Next, we'll set up Ansible! We will similarly to get the Ansible client, which we install in the following cell:

:::

::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
PYTHONUSERBASE=/work/.local pip install --user ansible-core==2.16.9 ansible==9.8.0
```
:::


::: {.cell .markdown}

The Ansible client has been installed to: `/work/.local/bin`. In order to run `ansible-playbook` commands, we will have to add this directory to our `PATH`, which tells the system where to look for executable files. We also need to let it know where to find the corresponding Python packages.

:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
export PATH=/work/.local/bin:$PATH
export PYTHONUSERBASE=/work/.local
```
:::


::: {.cell .markdown}

Let's make sure we can now run `ansible-playbook` commands. The following cell should print usage information for the `ansible-playbook` command, since we run it with `--help`:
:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
ansible-playbook --help
```
:::



::: {.cell .markdown}

Now, we'll configure Ansible. The `ansible.cfg` configuration file modifies the default behavior of the Ansible commands we're going to run. Open this file using the file browser on the left side.

:::

::: {.cell .markdown}


Our configuration will include:

```
[defaults]
stdout_callback = yaml
inventory = /work/gourmetgram-iac/ansible/inventory.yaml

```

The first line is just a matter of preference, and directs the Ansible client to display output from commands in a more structured, readable way. The second line specifies the location of a default *inventory* file - the list of hosts that Ansible will configure.

It will also include:

```
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s \
           -o StrictHostKeyChecking=off -o UserKnownHostsFile=/dev/null \
           -o ForwardAgent=yes \
           -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p cc@A.B.C.D"
pipelining = True
```

which says that when Ansible uses SSH to connect to the resources it is managing, it should "jump" through `A.B.C.D` and forward the keys from this environment, through `A.B.C.D`, to the final destination. (Also, we disable host key checking when using SSH, and configure it to minimize the number of SSH sessions and the number of network operations wherever possible.)

Now that you have provisioned resources, edit `A.B.C.D.`, and replace it with the floating IP assigned to your experiment. Then, save the updated config file.

Ansible will look in either `~/.ansible.cfg` or the directory that we run Ansible commands from, we will use the latter:

:::

::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
cp ansible.cfg /work/gourmetgram-iac/ansible/ansible.cfg
```
:::

::: {.cell .markdown}

### Configure the PATH

:::

::: {.cell .markdown}

Both Terraform and Ansible executables have been installed to a location that is not the system-wide location for executable files: `/work/.local/bin`. In order to run `terraform` or `ansible-playbook` commands, we will have to add this directory to our `PATH`, which tells the system where to look for executable files.

:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
export PATH=/work/.local/bin:$PATH
export PYTHONUSERBASE=/work/.local
```
:::

::: {.cell .markdown}

and, we'll have to do that in *each new Bash session*.

:::

::: {.cell .markdown}

### Prepare Kubespray

To install Kubernetes, we'll use Kubespray, which is a set of Ansible playbooks for deploying Kubernetes. We'll also make sure we have its dependencies now:

:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
PYTHONUSERBASE=/work/.local pip install --user -r /work/gourmetgram-iac/ansible/k8s/kubespray/requirements.txt
```
:::



