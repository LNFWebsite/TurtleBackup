################################################################################
# TurtleBackup - backup.sh
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
PASSWORD="(enter a strong password here)"
# This is a cryptographic salt for use with encrypting the filenames (essentially a random string)
# Please run the following command on your system to generate a strong salt for use here (command from: https://unix.stackexchange.com/a/230676/101736):
# `head /dev/urandom | tr -dc A-Za-z0-9 | head -c 128 ; echo ''`
FILENAME_ENC_SALT="ReallyLongStringOfRandomCharactersGeneratedByTheCommandListedAbove"
# Enter directories which you would like to backup (make sure there is a leading and trailing slash, separate multiple directories by space)
DIRS_TO_BACKUP="/example/directory/to/backup/ /another/example/directory/"
# Enter the directory you chose to use with your uploader (no trailing slash, gdrive by default)
ROOT_DIRECTORY="/home/my_username/gdrive"
# Enter the subdirectory to put backup files in the root directory of your uploader (no trailing slash, will create if directory non-existent)
BACKUP_LOCATION="${ROOT_DIRECTORY}/backup"
# What command to run in order to upload (uses drive by default)
BACKUP_ENGINE_CMDS="cd \"${BACKUP_LOCATION}\"; drive push -no-prompt;"
################################################################################ That's it!

echo "TurtleBackup is starting...";

STAT_FILES_LOCATION="${ROOT_DIRECTORY}/statfiles"
ENC_FILE_EXTENSION=".tar.gz.enc"

function encrypt_path() {
  ENCRYPTED_PATH=""
  #create array based on directory/file names separated by slash
  IFS='/' read -r -a DIRECTORIES_ARRAY <<< "$1"
  #loop through them
  for element in "${DIRECTORIES_ARRAY[@]}"
  do
    #ignore the first empty element
    if [ ! -z "${element}" ]
    then
      #get the hash of this element
      ENC_FILE_HASHNAME=$(echo "${FILENAME_ENC_SALT}${element}" -n | openssl dgst -sha256);
      #strip the stuff that openssl adds in the beginning
      ENC_FILE_HASHNAME="${ENC_FILE_HASHNAME#"(stdin)= "}"
      #append to the ENCRYPTED_PATH
      ENCRYPTED_PATH="${ENCRYPTED_PATH}/${ENC_FILE_HASHNAME}"
    fi
  done
  echo "${ENCRYPTED_PATH}";
}

#if the backup location does not exist, create it
if [ ! -d ${BACKUP_LOCATION} ]
then
  echo "Creating empty backup directory...";
  `mkdir -p "${BACKUP_LOCATION}"`
fi

echo "Checking for updated files...";
#initialize ORIGIN_COMPARE for automatic file deletion
ORIGIN_COMPARE=""
#list all files within all directories and loop through them (https://unix.stackexchange.com/a/9499)
while IFS= read -r -d '' FILE_TO_CHECK;
do
  #encrypt all directory and file names with sha256 hash (needs to be unchanging relative to actual names, is not decrypted because tar includes original filenames and paths for uncompression)
  ENCRYPTED_PATH=$(encrypt_path "${FILE_TO_CHECK}")

  #specify the location of the backups
  ENC_FILE="${BACKUP_LOCATION}${ENCRYPTED_PATH}"
  ENC_FILE_DIR=$(dirname "${ENC_FILE}");
  #specify the location of the stat files
  OLD_STAT_FILE="${STAT_FILES_LOCATION}${ENCRYPTED_PATH}.txt"
  STAT_FILE_DIR=$(dirname "${OLD_STAT_FILE}");

  #append the path of this file to the ORIGIN_COMPARE variable
  ORIGIN_COMPARE="${ORIGIN_COMPARE}"$'\n'"${ENC_FILE}${ENC_FILE_EXTENSION}"

  #if the stat file directory does not exist, create it
  if [ ! -d $STAT_FILE_DIR ]
  then
    `mkdir -p "${STAT_FILE_DIR}"`
  fi
  #if the stat file exists, read its contents into OLD_STAT
  if [ -e ${OLD_STAT_FILE} ]
  then
    OLD_STAT=`cat "${OLD_STAT_FILE}"`
  else
    OLD_STAT="nothing"
  fi

  #run the stat command to store the last time this file has been edited
  NEW_STAT=`stat -c '%y' "${FILE_TO_CHECK}"`

  #if the file has changed as evident by the differing stat results to the old stat file
  if [ "${OLD_STAT}" != "${NEW_STAT}" ]
  then
    echo $'\n'"File ${FILE_TO_CHECK} has changed. Encrypting and backing up...";
    #if the path which the encrypted file will be in does not exist, make it
    if [ ! -d ${ENC_FILE_DIR} ]
    then
      `mkdir -p "${ENC_FILE_DIR}"`
    fi
    #create a compressed and encrypted backup file in the same directory structure (hashed now), except, in the backup folder
    tar cz -C / "${FILE_TO_CHECK#"/"}" | openssl enc -aes-256-cbc -pass pass:${PASSWORD} -e > "${ENC_FILE}${ENC_FILE_EXTENSION}";
    # update the OLD_STAT_FILE
    echo "${NEW_STAT}" > "${OLD_STAT_FILE}";
  else
    echo -n ".";
  fi
done < <(find ${DIRS_TO_BACKUP} -type f -print0)

#create the GDRIVE_COMPARE variable, listing the files in backup
GDRIVE_COMPARE=$(find "${BACKUP_LOCATION}" -type f);

#create the comparison files
if [ ! -e "${STAT_FILES_LOCATION}/gdrive.txt" ]
then
  `touch "${STAT_FILES_LOCATION}/gdrive.txt"`
fi
if [ ! -e "${STAT_FILES_LOCATION}/origin.txt" ]
then
  `touch "${STAT_FILES_LOCATION}/origin.txt"`
fi

#fill them with the list of files (with encrypted paths)
echo "${GDRIVE_COMPARE}" > "${STAT_FILES_LOCATION}/gdrive.txt"
echo "${ORIGIN_COMPARE}" > "${STAT_FILES_LOCATION}/origin.txt"

#compare the list of files newly-path-encrypted from origin to the already path-encrypted files in backup
COMPARE_RESULT=$(comm -23 <(sort "${STAT_FILES_LOCATION}/gdrive.txt") <(sort "${STAT_FILES_LOCATION}/origin.txt"));
#if there are any files that exist on gdrive yet not in origin
if [ "${COMPARE_RESULT}" ]
then
  #loop through all the files (https://superuser.com/a/284226)
  while read -r FILE_TO_DELETE;
  do
    #deleting every one of them
    echo $'\n'"Deleting non-existent file from backups...";
    `rm "${FILE_TO_DELETE}"`

    #likewise, delete the corresponding stat file
    STAT_FILE_DELETE="${STAT_FILES_LOCATION}${FILE_TO_DELETE#$BACKUP_LOCATION}"
    STAT_FILE_DELETE="${STAT_FILE_DELETE%$ENC_FILE_EXTENSION}.txt"
    `rm "${STAT_FILE_DELETE}"`
  done <<< "${COMPARE_RESULT}"
fi

echo $'\n'"Deleting any empty directories from backups...";
#delete all empty directories in backup and stat, at this point the backups are ready to be uploaded
`find ${BACKUP_LOCATION} ${STAT_FILES_LOCATION} -type d -empty -delete`

echo "Done! Files were encrypted and stored in the backups. Now starting Google Drive upload...";
#finally, backup all of the encrypted files to Google Drive
eval "${BACKUP_ENGINE_CMDS}"
echo "TurtleBackup is complete!";

exit 0
