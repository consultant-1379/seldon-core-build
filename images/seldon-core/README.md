# seldon-core dockerfiles

## Open source to Model-lcm migration Notes

* Open source `seldon-core-operator` image contains `/tmp/operator-resources/` dir containing manifests created using `kustomize`.
  These manifests (configmap, validatingwebhookconfiguration, webhook-service, crds) are deployed by the `operator` onto the cluster if the helm chart is deployed with `managerCreateResources` set to `true`
  These files are not part of `Dockerfile.operator` because in `eric-aiml-model-lcm` we want all resources to be deployed explicitly using the helm chart and do not want the `seldonController` to create resources automatically.

* `seldon-core` has separate license files for `executor` and `operator`. These are saved under `license` folder in open source docker image.
   For `model-lcm`, it is not necessary to save these licenses into the `docker image`

* Open source `seldon-core` images have all `MPL Source code` from dependencies archived and saved in the `docker image`.
  This is not done in `model-lcm` as dependencies would be captured by FOSS process
