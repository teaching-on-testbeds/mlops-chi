::: {.cell .markdown}

## Model and application lifecycle - Part 3

So far, you mostly saw the pipeline working when everything goes well (with the exception of some random "accuracy" failures). Now you’re going to deliberately push a "bad" model through and watch staging protect you.

:::

::: {.cell .markdown}

We're going to train the model using a different branch of the "gourmetgram-train" repo. In this branch, only the model state dictionary is saved to the `.pth` file, whereas previously we were saving the full model object. The training tests will pass - they have been updated to reflect the new type of model artifact - but our integration test in the staging environment will fail, because this model artifact is not compatible with the GourmetGram app code that expects a full model object.

Start the training run like you did before, but change the branch:

1. In the Argo Workflows UI, open “Workflow Templates” and click `train-model`.
2. Click “Submit”, set the `branch` parameter to `mlops-bad`, and submit.
3. Wait for the run to finish and for the downstream workflows to run. You’re looking for the staging test workflow (usuly named something like `test-staging`) that runs after the staging deployment.

Once the staging tests run, open the `test-staging` workflow and click into the integration test step. Read the logs and confirm that the integration check failed. The pod running the new model will crash each time it is loaded. The integration test checks to confirm (among other things) that the service is running the expected model version; this will fail because there will not be a running pod. 

Verify that the broken model is *not* promoted to "canary" by visiting `http://A.B.C.D:8081/version` (replace `A.B.C.D` with your floating IP). You should see that canary is still using the old "working" model.

:::

::: {.cell .markdown}

### Scheduled training 

Until now, we have been manually "triggering" each training run. A scheduled training job (`cron-train`) was already set up in Argo when you applied the other workflow templates. Now, you’ll verify it’s present and working.

1. In the Argo Workflows UI, go to “Cron Workflows” tab and open `cron-train`.
2. Confirm it references the existing `train-model` workflow template and uses the default training branch (either by relying on the template’s default parameter value, or by explicitly setting the `branch` parameter).
3. It is currently set up to train once daily, at 2:00AM UTC. Click on the "Cron" tab and set the schedule to `*/15 * * * *`, which means "Every 15 minutes". Click the "Update" button.
3. Go back to the main Workflows view. Wait for the scheduled run to kick off, and confirm it creates new `train-model` workflows automatically.

:::
