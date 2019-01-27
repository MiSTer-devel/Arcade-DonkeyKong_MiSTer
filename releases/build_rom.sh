#!/bin/bash

exit_with_error() {
  echo -e "\nERROR: ${1}\n" >&2
  exit 1
}

check_dependencies() {
  if [[ $OSTYPE == darwin* ]]; then
    for j in unzip md5 cat cut; do
      command -v ${j} > /dev/null 2>&1 || exit_with_error "This script requires ${j}"
    done
  else
    for j in unzip md5sum cat cut; do
      command -v ${j} > /dev/null 2>&1 || exit_with_error "This script requires ${j}"
    done
  fi
}

check_permissions () {
  if [ ! -w . ]; then
    exit_with_error "Cannot write to $PWD"
  fi
}

read_ini () {
  if [ ! -f ./build_rom.ini ]; then
    exit_with_error "Cannot find build_rom.ini file."
  else
    source ./build_rom.ini
  fi
}

uncompress_zip() {
  if [ -f "${zip}" ]; then
    tmpdir=tmp.`date +%Y%m%d%H%M%S%s`
    unzip -d ${tmpdir}/ ${zip}
    if [ $? != 0 ] ; then
      rm -rf $tmpdir
      exit_with_error "Something went wrong when extracting ${zip}"
    fi
  else
    exit_with_error "Cannot find ${zip} file."
  fi
}

generate_rom() {
  for i in "${ifiles[@]}"; do
      # ensure provided zip contains required files
      if [ ! -f "${tmpdir}/${i}" ]; then
	rm -rf $tmpdir
        exit_with_error "Provided ${zip} is missing required file: ${i}"
      else
        cat ${tmpdir}/${i} >> ${tmpdir}/${ofile}
     fi
  done
}

validate_rom() {

  if [[ $OSTYPE == darwin* ]]; then
    ofileMd5sumCurrent=$(md5 -r ${tmpdir}/${ofile}|cut -f 1 -d " ")
  else
    ofileMd5sumCurrent=$(md5sum ${tmpdir}/${ofile}|cut -f 1 -d " ")
  fi

  if [[ "${ofileMd5sumValid}" != "${ofileMd5sumCurrent}" ]]; then
    echo -e "\nExpected ${ofile} checksum:\t${ofileMd5sumValid}"
    echo -e "Actual ${ofile} checksum:\t${ofileMd5sumCurrent}"
    mv ${tmpdir}/${ofile} .
    rm -rf $tmpdir
    exit_with_error "Generated ${ofile} is invalid. This is more likely due to incorrect ${zip} content."
  else
    mv ${tmpdir}/${ofile} .
    rm -rf $tmpdir
    echo -e "\nChecksum verification passed for ${ofile}\nCopy the ${ofile} file into root of SD card along with the rbf file.\n"
  fi
}

## verify dependencies
check_dependencies

## verify write permissions
check_permissions

## load ini
read_ini

## extract package
uncompress_zip

## build rom
generate_rom

## verify rom
validate_rom
