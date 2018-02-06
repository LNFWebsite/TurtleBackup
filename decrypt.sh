################################################################################
# TurtleBackup - decrypt.sh
#
# TurtleBackup is a multi-purpose backup script which encrypts your data before
# uploading to your cloud of choice.
#
# By default, it's set up to use Google Drive using the Drive program:
#
# https://github.com/odeke-em/drive
#
# Instructions:
#
# All you need to do is change a couple settings below...
#
PASSWORD="(enter your password here)"
# Specify the directory containing encrypted files/directories
DIR_TO_CHECK="/home/server/gdrive/backup/"
# Specify where to put the decrypted files
DIR_TO_PUT="/home/server/gdrive/backupdecrypted/"
################################################################################ That's it!

echo "TurtleBackup decrypter is starting...";

#list all files within all directories and loop through them
for FILE_TO_CHECK in $(find $DIR_TO_CHECK -mindepth 1 -type f);
do
  echo "Decrypting" $FILE_TO_CHECK "...";

  #if the path which the encrypted file will be in does not exist, make it
  if [ ! -d $DIR_TO_PUT ]
  then
         `mkdir -p $DIR_TO_PUT`
  fi
  #unencrypt and uncompress!
  cd ${DIR_TO_PUT}
  openssl enc -aes-256-cbc -pass pass:${PASSWORD} -d -in ${FILE_TO_CHECK} | tar xz;
done
echo "TurtleBackup decryption is complete!";

exit 0
