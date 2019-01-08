#!/bin/bash

zip=dkong.zip
ifiles=(c_5et_g.bin c_5ct_g.bin c_5bt_g.bin c_5at_g.bin c_5at_g.bin c_5at_g.bin v_3pt.bin v_3pt.bin v_5h_b.bin v_5h_b.bin c_5at_g.bin c_5at_g.bin l_4m_b.bin l_4m_b.bin l_4n_b.bin l_4n_b.bin l_4r_b.bin l_4r_b.bin l_4s_b.bin l_4s_b.bin s_3i_b.bin s_3j_b.bin c-2k.bpr c-2j.bpr v-5e.bpr ../empty.bin ../dk_wave.bin)
ofile=a.dkong.rom
ofileMd5sumValid="05fb1dd1ce6a786c538275d5776b1db1"

exit_with_error() {
  echo -e "\nERROR: ${1}\n" >&2
  exit 1
}

check_dependencies() {
  for j in mktemp unzip md5sum cat cut; do
    command -v ${j} > /dev/null 2>&1 || exit_with_error "This script requires ${j}"
  done
}

check_permissions () {
  if [ ! -w . ]; then
    exit_with_error "Cannot write to $PWD"
  fi
}

uncompress_zip() {
  if [ -f "${zip}" ]; then
    tmpdir=$(mktemp -d -p .)
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
  ofileMd5sumCurrent=$(md5sum ${tmpdir}/${ofile}|cut -f 1 -d " ")

  if [[ "${ofileMd5sumValid}" != "${ofileMd5sumCurrent}" ]]; then
    echo -e "\nExpected ${ofile} md5sum:\t${ofileMd5sumValid}"
    echo -e "Actual ${ofile} md5sum:\t${ofileMd5sumCurrent}"
    mv ${tmpdir}/${ofile} .
    rm -rf $tmpdir
    exit_with_error "Generated ${ofile} is invalid. This is more likely due to incorrect ${zip} content."
  else
    mv ${tmpdir}/${ofile} .
    rm -rf $tmpdir
    echo -e "\nmd5sum verification passed for ${ofile}\nCopy the ${ofile} file into root of SD card along with the rbf file.\n"
  fi
}

## verify dependencies
check_dependencies

## verify write permissions
check_permissions

## extract package
uncompress_zip

## build rom
generate_rom

## verify rom
validate_rom
