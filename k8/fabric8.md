# Example of how to bind a configmap to a pod
This one took me a good 45 mins to deduce. The internet was no help!

In essense you are just duplicating the pattern you would see in yaml

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: goodstuff-deployment
  namespace: yourns
spec:
    replicas: 1
    template:
      metadata:
        namespace: yourns
      spec:       
        containers:
          - name: goodstuff
            image: yourrepo/somethinggood:1.0                         
            volumeMounts:
            - name: config-volume
              mountPath: /app/config            
        volumes:
          - name: config-volume
            configMap:
              name: lab-aor-config-volume
              items:
              - key: service-properties
                path: service.properties
              - key: env-properties
                path: env.properties
```
Turns into...
```java
        final PodSpecFluent.ContainersNested<PodFluent.SpecNested<PodBuilder>> containerSpec = new PodBuilder()
        ...
        containerSpec
        .addNewVolumeMount()
        .withName("config-volume")
        .withMountPath("/app/config)
        .endVolumeMount();        
        ...
        ConfigMapVolumeSource source = new ConfigMapVolumeSource();
        List<KeyToPath> items = new LinkedList<>();
        KeyToPath keyToPath = new KeyToPath();
        keyToPath.setKey("service-properties");
        keyToPath.setPath("service.properties");
        items.add(keyToPath);

        source.setItems(items);
        source.setName("lab-aor-config-volume");
        podSpec
          .addNewVolume()
          .withName("config-volume")
          .withConfigMap(source)
          .endVolume();
```
