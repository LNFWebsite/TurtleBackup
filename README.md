# TurtleBackup

Make simple, encrypted backups to your cloud of choice

![1](https://raw.githubusercontent.com/LNFWebsite/TurtleBackup/master/examples/1.jpg)

## Description

If you've ever wanted to backup all your important files to a cloud service like Google Drive, but didn't like the idea of them having access to your files, you probably would wind up writing some sort of script to automate encrypting and uploading your files.

So, you'd probably start out by moving all your files to a single directory, encrypting that directory, and uploading...

But then you'd realize that, by encrypting your files, the uploader which you have chosen would not be able to recognize that your files didn't change, because... they did change... They were encrypted.

On top of this, for any single file change, the entire backup would have to be re-uploaded, which is dumb and wasteful.

So you go back to the drawing board...

You need to:

- Encrypt each file individually so that file changes may be uploaded as they occur without re-uploading everything

- Check whether changes indeed occurred before pulling out the file, encrypting, and putting it in the uploader directory (otherwise the uploader will see the newly encrypted file, re-uploading)

- Preserve the directory structure, which must be encrypted as well

- Have a way to easily decrypt backups

When you're done doing all of this, you'll wind up with TurtleBackup!

## Getting Started

### Installation

Installing TurtleBackup is simple!

#### Backup Engine

First, install your backup engine. TurtleBackup works with https://github.com/odeke-em/drive out of the box, making backups to Google Drive, so let's do that:

[Installing Drive](https://github.com/odeke-em/drive#installing)

I find the [platform packages](https://github.com/odeke-em/drive/blob/master/platform_packages.md) to be the easiest, so try to find your distro in that list.

Since I run Ubuntu, I'll put those instructions right here:

```
sudo add-apt-repository ppa:twodopeshaggy/drive
sudo apt-get update
sudo apt-get install drive
```

#### Clone TurtleBackup

Great, now either clone or download TurtleBackup into your directory of choice:

```
git clone https://github.com/LNFWebsite/TurtleBackup.git
```

And edit the configuration parameters at the top of the script:

![2](https://raw.githubusercontent.com/LNFWebsite/TurtleBackup/master/examples/2.jpg)

Terrific, now you're ready for your first backup!

### Usage

#### Backup and Upload

To backup and upload your files, just run the following in a terminal or in a Cron job:

```
sudo bash /path/to/TurtleBackup/backup.sh
```

#### Download and Decrypt

To download and decrypt your backups, take a glance at the `decrypt.sh` script, configuring as necessary, then run:

```
cd /path/to/where/you/want/the/encrypted/backups
drive pull # or whatever you use to download your backups

sudo bash /path/to/TurtleBackup/decrypt.sh
```

Voila! You're files should be placed in the directory specified in the script, with preserved file paths, filenames, and permissions.
