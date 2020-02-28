Xargs always confuses me

```
cat show.sh 
#!/bin/bash
echo -n "-> "; for a in "$@"; do echo -n "\"$a\" "; done; echo
```

```
printf "foo\nbar\n" | xargs ./show.sh 
-> "foo" "bar" 
```

now split each line
```
printf "foo\nbar\n" | xargs -n1 ./show.sh 
-> "foo" 
-> "bar" 
```
