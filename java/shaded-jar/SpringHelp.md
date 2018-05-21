When using https://maven.apache.org/plugins/maven-shade-plugin/ you will get a "collapsed" jar as a result. That collapsing 
means that any files in respective jars, having the same name will overwrite. That's bad for Spring!

See the transformer example for spring here
https://maven.apache.org/plugins/maven-shade-plugin/examples/resource-transformers.html
```
                          <transformers>
                                <transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                                    <resource>META-INF/spring.handlers</resource>
                                </transformer>
                                <transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
                                    <resource>META-INF/spring.schemas</resource>
                                </transformer>
                                <transformer
                                    implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                                    <manifestEntries>
                                        <Main-Class>com.something.App</Main-Class>
                                        <Build-Number>1</Build-Number>
                                    </manifestEntries>
                                </transformer>
                          </transformers>
 ```
