

::: {.cell .markdown}

### Run a post-install playbook

After our Kubernetes install is complete, we run some additional tasks to further configure and customize our Kubernetes deployment. Our post-install playbook will:

* Configure the `kubectl` command so that we can run it directly on "node1" as the `cc` user, and allow the `cc` user to run Docker commands.
* Change the networking configuration on the cluster to make it more stable with respect to Chameleon's network.
* Configure the Kubernetes dashboard, which we can use to monitor our cluster.
* Install [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) CLI, [Argo Workflows](https://argoproj.github.io/workflows/), and [Argo Events](https://argoproj.github.io/events/). (Argo CD itself was already installed with Kubespray.) We will use Argo CD for application and service bootstrapping, and Argo Events/Workflows for application lifecycle management on our Kubernetes cluster.

:::


::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
export PATH=/work/.local/bin:$PATH
export PYTHONUSERBASE=/work/.local
```
:::

::: {.cell .markdown}

In the output below, make a note of the Kubernetes dashboard token and the Argo admin password, both of which we will need in the next steps.

:::



::: {.cell .code}
```bash
# runs in Chameleon Jupyter environment
cd /work/gourmetgram-iac/ansible
ansible-playbook -i inventory.yml post_k8s/post_k8s_configure.yml
```
:::


::: {.cell .markdown}

### Access the Kubernetes dashboard

To check on our Kubernetes deployment, let's keep an eye on the dashboard. 

First, since we did not configure security group rules to permit any ports besides SSH, we need to use SSH port forwarding to open a tunnel between our *local* device and the remote cluster. Then, since the service is configured only for internal access within the cluster, we need to use port forwarding to also make it available on the host. 

Run the command below in your *local* terminal (not the terminal in the Chameleon Jupyter environment!) and substitute:

* in place of `~/.ssh/id_rsa_chameleon`, the path to your own key
* in place of `A.B.C.D`, the floating IP assigned to your "node1" instance

```bash
# runs in your **local** terminal
ssh -L 8443:127.0.0.1:8443 -i ~/.ssh/id_rsa_chameleon cc@A.B.C.D
```


then, inside that terminal, run

```bash
# runs on node1 
kubectl port-forward -n kube-system svc/kubernetes-dashboard 8443:443
```

and leave it running.

Now, in a browser, you may open

```
https://127.0.0.1:8443/
```

You will see a warning about an invalid certificate, which you may override and choose the "Advanced" option to proceed. Then, you will be prompted to log in.

From the output of the post-install playbook above, find the "Dashboard token" and paste it into the token space, then log in. You will see the Kubernetes dashboard.

(Note: if your token expires, you can generate a new one with `kubectl -n kube-system create token admin-user`.)

For now, there is not much of interest in the dashboard. You can see some Kubernetes system services in the "kube-system" namespace, and Argo-related services in the "argo", "argocd", and "argo-events" namespaces. We have not yet deployed our GourmetGram services, but we'll do that in the next step!

:::




::: {.cell .markdown}

### Access the ArgoCD dashboard

Similarly, we may access the Argo CD dashboard. In the following command, substitute

* in place of `~/.ssh/id_rsa_chameleon`, the path to your own key
* in place of `A.B.C.D`, the floating IP assigned to your "node1" instance

```bash
# runs in your **local** terminal
ssh -L 8888:127.0.0.1:8888 -i ~/.ssh/id_rsa_chameleon cc@A.B.C.D
```

then, inside that terminal, run

```bash
# runs on node1 
kubectl port-forward svc/argocd-server -n argocd 8888:443
```

and leave it running.

Now, in a browser, you may open

```
https://127.0.0.1:8888/
```

You will see a warning about an invalid certificate, which you may override and choose the "Advanced" option to proceed. Then, you will be prompted to log in.

From the output of the post-install playbook above, find the "ArgoCD Password" and paste it into the password space, use `admin` for the username, then log in. 

For now, there is not much of interest in Argo CD. We have not yet configured Argo with for any deployments, but we'll do that in the next step!

:::


::: {.cell .markdown}

### Access the Argo Workflows dashboard

Finally, we may access the Argo Workflows dashboard. In the following command, substitute

* in place of `~/.ssh/id_rsa_chameleon`, the path to your own key
* in place of `A.B.C.D`, the floating IP assigned to your "node1" instance

```bash
# runs in your **local** terminal
ssh -L 2746:127.0.0.1:2746 -i ~/.ssh/id_rsa_chameleon cc@A.B.C.D
```

then, inside that terminal, run

```bash
# runs on node1 
kubectl -n argo port-forward svc/argo-server 2746:2746
```

and leave it running.

Now, in a browser, you may open

```
https://127.0.0.1:2746/
```

You will see a warning about an invalid certificate, which you may override and choose the "Advanced" option to proceed. Then, you will be able to see the Argo Workflows dashboard.

Again, there is not much of interest - but there will be, soon.


:::


