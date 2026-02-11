::: {.cell .markdown}

## Model and application lifecycle - Part 2

Once we have a container image, the progression through the model/application lifecycle continues as the new version is promoted through different environments:

* **Staging**: The container image is deployed in a staging environment that mimics the "production" service but without live users. In this staging environment, we can perform automated integration tests against the service.
* **Canary** (or other "preliminary" live environment): From the staging environment, the service can be promoted to a canary or other preliminary environment, where it gets requests from a small fraction of live users. In this environment, we are closely monitoring the service, its predictions, and the infrastructure for any signs of problems.
* **Production**: Finally, after a thorough offline and online evaluation, we may promote the model to the live production environment, where it serves most users. We will continue monitoring the system for signs of degradation or poor performance.


![Part 2 of the ML model lifecycle: from staging to production.](images/stage2-promote.svg)



### Verify that the new model is deployed to staging


Our `build-container-image` workflow automatically triggers two workflows if successful:

1. `deploy-container-image`: Updates the staging deployment via ArgoCD
2. `test-staging`: Runs automated tests against the staging deployment

In Argo Workflows:

* Click on "Workflows" in the left side menu (mouse over each icon to see what it is)
* Note that a `deploy-container-image` workflow follows each `build-container-image` workflow. After this runs, switch to the Argo CD dashboard and open the "gourmetgram-staging" application; you should see that the old pod is being replaced, with a new one that uses the updated container image.
* You should also see a `test-staging` workflow that runs after deployment completes

Then, open the staging service:

* Visit `http://A.B.C.D:8082` (substituting the value of your floating IP)

[This version of the `gourmetgram` app](https://github.com/teaching-on-testbeds/gourmetgram/tree/workflow) has a `versions` endpoint. So you can visit `http://A.B.C.D:8082/version`, and you should see the model version you just promoted to staging.

**Note on our deployment approach:** In usual GitOps workflows, the `deploy-container-image` workflow would:
1. Update the Helm chart or Kubernetes manifest in Git to specify the new container image tag
2. Commit and push the change to the Git repository
3. ArgoCD would detect the Git change and automatically sync the deployment

This makes Git the "single source of truth" for infrastructure state. However, for this lab environment, to avoid requiring all students to:

- Fork the infrastructure repository
- Update *all* repository path references throughout the codebase to point to their own fork
- Set up Git credentials with push access

We instead use a simplified approach where the workflow directly calls ArgoCD's API to update the deployment. This bypasses Git and directly modifies the ArgoCD application's Helm values. For demos and learning environments this is fine, but real systems should use the Git-based approach.





### Automated testing in staging

Before promoting a model to the canary or production environment - where real users will interact with it! - we should validate that:

1. The model works correctly with the application code (integration testing)

That's exactly what the `test-staging` workflow does! You can check the logs to see the results.

After running the integration test, the workflow branches based on results. This is a key concept in MLOps: automated decision-making based on test outcomes.

```yaml
# From test-staging.yaml
steps:
  # ... tests run sequentially ...

  # Step 2: Mark as approved if integration test passes
  - - name: mark-staging-approved
      template: set-staging-approved
      when: "'{{steps.integration-test.outputs.parameters.result}}' == 'pass'"

  # Step 3: Branching based on test results
  - - name: promote-on-success
      template: trigger-promote
      when: "'{{steps.integration-test.outputs.parameters.result}}' == 'pass'"
```

There are two possible outcomes:

1. All tests pass:
   - Model gets `staging-approved` alias in MLflow. In case we need to revert to this model after testing a later version, we know that it is "known good" (in staging, at least).
   - Automatically trigger `promote-model` workflow to deploy the successful container image to the canary environment
2. Integration test fails: The workflow fails and no promotion happens

This branching is implemented using Argo Workflows' `when` conditions. Each branch is evaluated independently, and only the matching branch executes.



### Observing automated promotion (happy path)

In the Argo Workflows UI, watch the `test-staging` workflow after a successful staging deployment:

1. `integration-test` step runs - logs should show ✓ PASSED
2. `promote-on-success` step triggers - creates a new `promote-model` workflow

Click on the new `promote-model` workflow to watch it execute:

1. Retags the container image from `staging-1.0.X` to `canary-1.0.X`
2. Updates the MLFlow alias from "staging" to "canary". The "staging", "canary", or "production" alias reflects the environment in which the model is currently deployed (if any)
3. Triggers ArgoCD to sync the canary deployment

After the workflow completes, verify the promotion:

* Visit `http://A.B.C.D:8081/` and `http://A.B.C.D:8081/version` (canary runs on port 8081)
* You should see the same model version that was just tested in staging

In the MLFlow UI:

* Click on "GourmetGramFood11Model"
* The model version should now have the "canary" alias (in addition to "development")
* The "staging" alias remains on the same version

Take screenshots of:

1. The completed `test-staging` workflow showing all tests passed
2. The triggered `promote-model` workflow
3. The canary `/version` endpoint showing the new version
4. The MLFlow UI showing the "canary" alias


### Promotion to production

Until now, we have directly accessed different versions of our service in different stages by changing the port number; we put each service on a different port. Users, however, will access our service on the standard port (port 80 for HTTP service) and, as part of our "platform", we have [a service](https://github.com/teaching-on-testbeds/gourmetgram-iac/blob/main/k8s/platform/templates/httproute.yaml) that routes 10% of requests to the canary service, and the remaining 90% to the production service.

Try this for yourself - visit `http://A.B.C.D/version` (using your own public IP) repeatedly, and observe that sometimes you get the production service; sometimes you get the canary service.

After some careful monitoring in canary with real users, the model may be promoted to a "production" environment. Let's do that, too. From the Argo Workflows UI, find the `promote-model` workflow template and click "Submit".

* specify "canary" as the source environment
* specify "production" as the target environment
* and, specify the version number of the model again

Then, run the workflow. Check the version that is deployed to the "production" environment (`http://A.B.C.D:8080/version`) to verify.

Take a screenshot, with both the address bar showing the URL and the response showing the version number visible in the screenshot. Also, take a screenshot of the updated list of model versions in the MLFlow UI (the alias list will have changed!).

:::
