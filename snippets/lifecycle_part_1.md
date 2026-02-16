::: {.cell .markdown}

## Model and application lifecycle - Part 1

With all of the pieces in place, we are ready to follow a GourmetGram model through its lifecycle!

We will start with the first stage, where:

* **Something triggers model training**. It may be a schedule, a monitoring service that notices model degradation, or new training code pushed to a Github repository from an interactive experiment environment like a Jupyter service. In this example, we are going to manually trigger a training job.
* **A model is trained**. The model will be trained, generating a model artifact. Then, it will be evaluated, and if it passes some initial test criteria, it will be registered in the model registry.
* **A container is built**: When a new "development" model version is registered, it will trigger a container build job. If successful, this container image will be ready to deploy to the staging environment.


![Part 1 of the ML model lifecycle: from training to new container image.](images/stage1-build.svg)



### The training procedure

When triggered, model training runs as a Kubernetes pod managed by Argo Workflows. The workflow first checks if the training code has changed (by comparing git commits) or if there is not already a training container image, and builds the training container image if needed.

The training script ([`flow.py`](https://github.com/teaching-on-testbeds/gourmetgram-train/blob/mlops/flow.py)) inside the training container performs several steps:

1. **Emulate training**: For this demo, it loads a pre-trained model checkpoint as a fake "training" step
2. **Run pytest tests**: Evaluates the model using automated tests. The script uses `pytest` to evaluate the model. Tests are organized in a `tests/` directory, and pytest runs them, capturing the output which is logged to MLflow as an artifact alongside the model.
3. **Register model**: If tests pass, registers the model in the MLFlow model registry, and records the version number
4. **Handle failures**: If tests fail, prints detailed output to logs and exits with an error code



Note that our "test suite" has tests organized into two files:

* [`tests/test_model_structure.py`](https://github.com/teaching-on-testbeds/gourmetgram-train/blob/mlops/tests/test_model_structure.py) - Validates that the model can be loaded and has the expected input and output shape.
* [`tests/test_model_accuracy.py`](https://github.com/teaching-on-testbeds/gourmetgram-train/blob/mlops/tests/test_model_accuracy.py) - Validates model performance. In this "dummy" example, we've made the test return 0.85 accuracy 70% of the time, and 0.75 accuracy 30% of the time, and we have set a 0.8 threshold for "passing" the test. This means that sometimes, our model may fail, and we'll be able to see how the pipeline responds.




### Run a training job

We have already set up an Argo workflow template to run the training job. If you have the Argo Workflows dashboard open, you can see it by:

* clicking on "Workflow Templates" in the left side menu (mouse over each icon to see what it is)
* then clicking on the "train-model" template



We will use this as an example to understand how an Argo Workflow template is developed. An Argo Workflow is defined as a sequence of steps in a graph.

At the top, we have some basic metadata about the workflow:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: train-model
```

then, the name of the first "node" in the graph (`training-and-build` in this example). This workflow accepts a `branch` parameter to specify which branch of the training repository to use (defaults to `mlops`):

```yaml
spec:
  entrypoint: training-and-build
  arguments:
    parameters:
    - name: branch
      value: mlops
```

Now, we have a sequence of steps that run in order:

```yaml
  templates:
  - name: training-and-build
    steps:
      # Step 1: Clone repo and check if code has changed
      - - name: check-code-changes
          template: check-and-clone
          arguments:
            parameters:
            - name: branch
              value: "{{workflow.parameters.branch}}"
      # Step 2: Conditionally rebuild training image if code changed
      - - name: rebuild-training-image
          template: buildkit-rootless
          arguments:
            parameters:
            - name: git-commit
              value: "{{steps.check-code-changes.outputs.parameters.git-commit}}"
          when: "'{{steps.check-code-changes.outputs.parameters.needs-rebuild}}' == 'true'"
      # Step 3: Run training
      - - name: run-training
          template: run-training
      # Step 4: Tag model as development in MLflow (latest trained)
      - - name: tag-model-development
          template: set-development-alias
          arguments:
            parameters:
            - name: model-version
              value: "{{steps.run-training.outputs.parameters.modelversion}}"
          when: "'{{steps.run-training.outputs.parameters.modelversion}}' != ''"
      # Step 5: Trigger app container build if model was registered
      - - name: build-container
          template: trigger-build
          arguments:
            parameters:
            - name: model-version
              value: "{{steps.run-training.outputs.parameters.modelversion}}"
          when: "'{{steps.run-training.outputs.parameters.modelversion}}' != ''"
```

The workflow has five steps:

1. `check-code-changes`: Clones the training repo and checks if the code has changed by comparing git commit hashes with a label on the existing image in the registry. If using a non-default branch, it always rebuilds.

2. `rebuild-training-image`: Conditionally rebuilds the training container image if code changed (or if using a non-default branch). This step is skipped if the image is up-to-date.

3. `run-training`: Runs the training script in the (possibly just-built) training container.

4. `tag-model-development`: Updates the MLflow registered-model alias `development` to point at the newly-registered model version.

5. `build-container`: Triggers the app container build workflow, but only if a model version was successfully registered (i.e., tests passed).

This design ensures the training image is always current without requiring a separate manual build step.


We can look more closely at the `run-training` step, which runs the training container as a Kubernetes pod:

```yaml
  - name: run-training
    outputs:
      parameters:
      - name: modelversion
        valueFrom:
          path: /var/run/argo/outputs/parameters/modelversion
    container:
      image: registry.kube-system.svc.cluster.local:5000/gourmetgram-train:latest
      command: [sh, -c]
      args:
        - |
          set -eu
          python flow.py

          # Argo requires output parameters to be written
          # under /var/run/argo/outputs/parameters/
          mkdir -p /var/run/argo/outputs/parameters
          if [ -f /tmp/model_version ]; then
            cp /tmp/model_version /var/run/argo/outputs/parameters/modelversion
          else
            # Avoid hard failure if training didn't emit a version.
            : > /var/run/argo/outputs/parameters/modelversion
          fi
      env:
        - name: MLFLOW_TRACKING_URI
          value: "http://mlflow.gourmetgram-platform.svc.cluster.local:8000"
```

This part:

 - Launches a pod with the training container image from the local registry
 - Runs `python flow.py` which handles training, testing, and model registration
 - Sets the MLFlow tracking URI to reach the MLFlow model registry inside the cluster
 - Captures the model version from `/tmp/model_version` as an output parameter

If tests pass and a model is successfully registered, the training script writes the model version to `/tmp/model_version`. Otherwise, it writes an empty file. Either way, subsequent steps can access it.

Note that if pytest tests fail (for example, if the random "accuracy" test returns a value below the threshold), the `run-training` step will fail with a non-zero exit code. When this happens:

 - The workflow will show as **failed** at the `run-training` node in the Argo UI
 - The detailed pytest output will be printed to the container logs (check the "Logs" tab for the failed `run-training` node in Argo Workflows)
 - The test results are also saved in MLflow (find the relevant run in the "food11-classifier" experiment and view the `test_logs/pytest_output.txt` artifact)
 - No model version will be registered in MLflow
 - The `build-container` step will be skipped (since there's no model version to build with)

The pipeline gates model registration and deployment to "staging" on passing tests.


Finally, we can see the `trigger-build` part:

```yaml
  - name: trigger-build
    inputs:
      parameters:
      - name: model-version
    resource:
      action: create
      manifest: |
        apiVersion: argoproj.io/v1alpha1
        kind: Workflow
        metadata:
          generateName: build-container-image-
        spec:
          workflowTemplateRef:
            name: build-container-image
          arguments:
            parameters:
            - name: model-version
              value: "{{inputs.parameters.model-version}}"
```

This template uses a resource with `action: create` to trigger a new workflow - our "build-container-image" workflow! (You'll see that one shortly.)

Note that we pass along the `model-version` parameter from the training step to the container build step, so that the container build step knows which model version to use.



Now, we can submit this workflow! In Argo:

* Click on "Workflow Templates" in the left sidebar
* Click on "train-model"
* Click "Submit" in the top right
* Click "Submit" again (we don't need to modify any parameters)

This will start the training workflow.




In Argo, you can watch the workflow progress in real time:

* Click on "Workflows" in the left side menu
* Then find the workflow whose name starts with "train-model"
* Click on it to open the detail page

You can click on any step to see its logs, inputs, outputs, etc. For example, click on the "run-training" node to see the training logs. You should see pytest output showing which tests passed or failed.

Wait for it to finish. (It may take 10-15 minutes for the entire pipeline to complete, including the container build.)

If your training run fails because its "accuracy" is not good enough, resubmit until you have a passing run! (If it passes, you can also try a few more runs to get it to fail, so you can see what happens.)



### Check the model registry

After training completes successfully (and tests pass), you should see a new model version registered in MLflow. Open the MLFlow UI at `http://A.B.C.D:8000` (substituting your floating IP address).

* Click on "Models" in the menu on the side
* Click on "GourmetGramFood11Model"
* You should see a new version with the alias "development"

Take a screenshot for your reference.

* Click on the model (e.g. the "Version 1" hyperlink)
* Near the top, find the "Source Run" link and click on it
* Note that in the "Overview" page, the number of tests ran, passed, and failed are logged
* Click on "Artifacts" > "test_logs" > "pytest_output.txt" and note the specific output per test

:::



::: {.cell .container}

### Next: Container build

When training completes successfully, the workflow automatically triggers the process to build a new container image for the GourmetGram application, with the updated model baked in. In the next section, we'll examine how that container build workflow:

1. Clones the application repository
2. Downloads the model from MLflow model registry
3. Builds a new container image with the updated model
4. Deploys to the staging environment

This completes Part 1 of the model lifecycle!

:::
