### Start the VMs in host ###

```
fab start:num={n} -f machine.py
```

- This command will start **n** VMs in hosts (every 30 seconds one VM).

### Run benchmark ###

```
fab ip animation -f animate.py
```

- `fab ip` wil get ips for every VM in host and then output to `ip_list.txt` file. 

- `fab animation` will read `ip_list.txt` file and then run benchmark in every VM.

### Restart host ###

```
fab restart -f machine.py
```

### More ###

- Modify `animation` function in `animate.py` file to run different benchmark (now it is `warsow`).