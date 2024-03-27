# Getting started with auditd
As opposed to other operating systems, BSD comes with auditd functionality preinstalled.  All you have to do is set it up.  To set it up, add the following line to `/etc/rc.conf`: `auditd_enable="YES"`.  Then, all you have to do is run `service auditd start` and you are now auditing your BSD machine!

# Configuring auditd
Auditd looks almost unidentifiable on BSD.  This is due to it being a custom version of auditd.  To start with, there is no `/etc/audit` directory where you store all of your rules.  In fact, there is no way to really create a rule.  Instead you must rely on the builtin event classes and decide which classes to audit for which users.  The main way you configure the auditd service is by editing the file `/etc/securty/audit_control`

## audit\_control
This is the most important file when setting up auditd on your BSD machine.  It controls the global options for auditd, meaning these settings will apply to all users, even system/service users.  The important ones to look at are:
  - dir
  - flags
  - policy

The dir option controls where your log files are stored.  You can change this if you want, but all a threat actor would have to do to find the logs is view this file.  The flags option is how you specify what to audit, which I will go into momentarily.  Finally, the policy controls how it audits the machine

### flags
There are 20 flags in total, so I will not go into them all, but you can find them all [in the BSD docs](https://docs.freebsd.org/en/books/handbook/audit/#audit-config).  I recommend briefly reading through this page anyway as it is very helpful.  A few key flags are:
  - lo \(login and logoff\)
  - aa \(authentication and authorization\)
  - ad \(administrative actions\)
  - ex \(calls to execve\)
  - f\(m,r,w,d\) \(file attribute modification, read, write, and delete\)
  - nt \(network functions such as connect and accept\)
  - pc \(process execution\)

You can also add a few prefixes to these flags to control what is audited:
  - \+ \(successful events\)
  - \- \(failed events\)
  - ^ \(neither successful nor failed events\)
  - ^\+ \(don't audit successful events\)
  - ^\- \(don't audit failed events\)

For example, if you wanted to audit failed authentication, all login/logoff, and successful program execution, you would set the "flags" option to `-aa,lo,+ex`.

If you are ever curious about what triggers each flag, you can browse through `/etc/security/audit_events` to see what each flag corresponds to.

### policy
In addition to flags, policies also control what is audited on the system.  The main policies you want are:
  - cnt \(keeps the system runnning when an audit failure occurs\)
  - argv \(logs the arguments for execve calls\)
  - arge \(logs the environment variables arguments to execve calls\)

## audit\_user
This file is for fine tuning auditd to log specific things for specific users.  The format for this file is `username:alwaysaudit:neveraudit` with a new user on each line.  You use the same syntax as the "flags" option in `audit_control`.  For example, say you only want to audit successful calls to execve for the root user.  Then you would remove the `+ex` flag in `audit_control` and add the following line to `audit_user`: `root:+ex:`

Now that you have `audit_control` and `audit_user` configured to your liking, you can load the configuration by running `audit -s` or `service auditd restart` as root. 

**NOTE: If there are users currently logged in when you load the configuration, the new audit config will not apply to them.  It is recommended to restart the machine after loading auditd**

# Reading the logs
Another big difference between this and most other version of auditd is that the log files are not stored in plaintext.  Instead, they are held in trail files with the timestamp as the name.  In the trail files, they are encoded and in order to get them in human readable form, you must run the command `praudit <logfile>`.  In the `/var/audit/` directory there is also the "current" file.  This file is a symbolic link to the log file that is currently being written to.  You can call `praudit` on this file the same way you call it on a log file.

## Log Format
If you run `praudit` without any options, the logs will be formatted as tokens with a new token on each line.  Each log starts with a header token and ends with a trailer token with the contents of the log on the lines between them.  While this is good for human readability, this is not ideal for programmatically reading logs.  You can switch the format of the output using `-l` or `-x`.  `-l` outputs each log on a separate line and `-x` outputs each log in xml format.

## Forwarding logs
Okay, so auditd is great and all, but if you are managing 50+ machines, you don't want to have to log on to each machine and manually check the logs.  This is why we have SIEMs. Since BSD's auditd doesn't store the logs in plaintext anywhere, you can't immediately forward the logs to your chosen SIEM after setting up auditd.  We have to find a way to stream all new logs through `praudit` and append them to some centralized log file that we can then forward to our SIEM.

After some testing, I figured out a way to do just that.  I believe this is the intended way, but I couldn't find any documentation/forum posts about this.  I looked at the man page for `praudit` and discovered another option it has: `-p`. This allows `praudit` to take piped input from the command `tail`.  After I saw this, the solution was obvious.  In order to record all auditd logs in human readable format that can be forwarded, run this command: `tail -f -n 0 /var/audit/current | praudit -pl >> /var/log/audit.log &`.  This command converts all new auditd logs into human readable logs and stores them in `/var/log/audit.log`.  It also runs in the background and you can check it with the `jobs` command on the terminal you ran it from.  You can also look for it in the process list.

I would recommed creating a custom rc service to start this when the system starts up after auditd starts.  This way you capture every auditd log you can.  I have created one you can use and you can find it [here](https://github.com/Maxgriff/Maxgriff.github.io/blob/main/BSD/files/convert) and download it [here](convert).  Simply place this in your `/etc/rc.d/` directory, make it executable, and you can start the service.  For a comprehensive explanation on what this file does read [this page](https://docs.freebsd.org/en/articles/rc-scripting/) from the BSD documentation.

# Compatibility with Wazuh
Even though, according to Wazuh, BSD is not officially supported by Wazuh, it can be installed onto the machine without much trouble.  From here on out, this page will only be applicable if you are using Wazuh as your SIEM.  I could not find neither custom rules nor decoders written for BSD's version of auditd, so I decided to write them myself.  So far, I have created a decoder that decodes ssh logins, execve calls, and file write operations.  I have not yet created the rules based off the decoded logs, but they will be coming soon.  You can find the decoder [here](https://github.com/Maxgriff/Maxgriff.github.io/blob/main/BSD/files/auditd-bsd.xml) and download it [here](auditd-bsd.xml) file.  So far the decoder can deal with:
  - writing to files
  - OpenSSH logins (successful and unsuccessful login with password)
  - Running commands (Other than shell builtins such as "echo")

I would like to add decoders for the following actions:
  - adding users
  - changing passwords
  - connect(2) syscalls

The next step is writing rules for the decoded logs.  In the future I would like to create rules logging:
  - execution of suspicious binaries (nc, su, adduser, etc.)
  - successful and unsuccessful log ins
  - calls to connect(2) by user root
  - editing configuration files (.conf, .cfg, /etc/*, etc.)
  - stopping and starting services