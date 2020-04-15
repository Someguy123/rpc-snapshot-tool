This is a semi-automated Hive/Steem/Golos RPC snapshot tool, designed for use with https://github.com/Privex/hive-rpcs-docker/

Expects an RPC setup similar to this guide: https://hackmd.io/@KoCktFVzTnePd9BdXfC7og/HJxKBAhyv8

Usage
=====

```sh
git clone https://github.com/Someguy123/rpc-snapshot-tool.git
```

If you're using bash as your shell, open `.bashrc` in nano/vim/whatever,

If you're using zsh as your shell, open `.zshrc` in nano/vim/whatever,

then append to the bottom:

```sh
DEFAULT_VG="nvraid"         # Set this to the VG containing your RPC nodes' data/shm volumes
BASE_RPC_DIR="${HOME}/rpc"  # Set this to the folder containing Privex/hive-rpcs-docker

# Adjust the path to rpc-snapshot-tool if it's somewhere else. It's intended to be ran as root.
rpc-snapshot() {
    /root/rpc-snapshot-tool/rpc-snapshot-tool.sh "$@" 
}
```

NOTE: Depends on various things from my someguy-scripts repo ( https://github.com/Someguy123/someguy-scripts )

If someguy-scripts can't be found globally, it'll download it locally within this repo folder.



```
+===================================================+
|                 © 2020 Someguy123                 |
|            https://github.com/Someguy123          |
+===================================================+
|                                                   |
|        RPC Snapshot Tool                          |
|        License: X11/MIT                           |
|                                                   |
|        Core Developer(s):                         |
|                                                   |
|          (+)  Chris (@someguy123) [Privex]        |
|                                                   |
+===================================================+

RPC Snapshot Tool - a ZSH shell script for easy snapshots of Hive/Steem/Golos etc. RPC nodes
Copyright (c) 2020    Someguy123 ( https://github.com/Someguy123 )
```


Screenshots
===========

![](https://i.imgur.com/TWEdyuY.png)

![](https://i.imgur.com/2NyxhBW.png)


License
=======

Licensed under X11/MIT

