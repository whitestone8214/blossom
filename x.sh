#!/bin/bash

# In my case:
# ./zu.sh prepare clean; date > date.build.txt; ./zu.sh build; date >> date.build.txt; sudo ./zu.sh install /dev/sdc
# About 1 hour to build


_idCommitBRP2="55a00269fbb2e2a20c128778f49cad3395f67c66"
_idCommitBR="43de288bd1e11149068fe52595f56f33523e0159"
_edition="0"
_here="$(pwd)"


function announce {
	echo -e "\033[1;32m::\033[0m \033[1;37m${1}\033[0m"
}


if (test "${1}" = "prepare"); then
	# Remove?
	if (test "${2}" = "clean"); then
		#rm -rf ${_idCommitBRP2}.tar.gz ${_idCommitBR}.tar.gz buildroot_pinetab2-${_idCommitBRP2} buildroot-${_idCommitBR} || exit -1
		rm -rf buildroot_pinetab2-${_idCommitBRP2} buildroot-${_idCommitBR} || exit -1
	fi

	# Download?
	if (!(test -e "${_idCommitBRP2}.tar.gz")); then
		curl -L -O https://github.com/Danct12/buildroot_pinetab2/archive/${_idCommitBRP2}.tar.gz || exit -1
	fi
	if (!(test -e "${_idCommitBR}.tar.gz")); then
		curl -L -O https://github.com/buildroot/buildroot/archive/${_idCommitBR}.tar.gz || exit -1
	fi

	# Unpack?
	if (!(test -e "buildroot_pinetab2-${_idCommitBRP2}")); then
		tar -xf ${_idCommitBRP2}.tar.gz || exit -1
		cp -f ${_here}/modifications/extlinux-pinetab2v2.conf buildroot_pinetab2-${_idCommitBRP2}/board/pine64/pinetab2/ || exit -1
	fi
	if (!(test -e "buildroot-${_idCommitBR}")); then
		tar -xf ${_idCommitBR}.tar.gz || exit -1
		cp -f ${_here}/modifications/config buildroot-${_idCommitBR}/.config || exit -1
		sed -i 's|@PREFIX@|'${HOME}'/.cache/buildroot|g;' buildroot-${_idCommitBR}/.config || exit -1
		cp -f ${_here}/modifications/0001-swig4.5-compatibility.patch buildroot-${_idCommitBR}/boot/uboot/ || exit -1
		cp -f ${_here}/modifications/rcS buildroot-${_idCommitBR}/package/initscripts/init.d/ || exit -1
		
		# Preset
		cd buildroot-${_idCommitBR} || exit -1
		make BR2_EXTERNAL=${_here}/buildroot_pinetab2-${_idCommitBRP2} pinetab2v2_defconfig || exit -1
		cd .. || exit -1
	fi
elif (test "${1}" = "build"); then
	cd buildroot-${_idCommitBR} || exit -1
	
	if (test "${2}" = "adjust"); then
		make BR2_EXTERNAL=${_here}/buildroot_pinetab2-${_idCommitBRP2} nconfig || exit -1
	fi
	make BR2_EXTERNAL=${_here}/buildroot_pinetab2-${_idCommitBRP2} || exit -1
elif (test "${1}" = "install"); then
	_system="buildroot-${_idCommitBR}/output/images/sdcard.img"
	if (!(test -e "${_system}")); then
		echo "ERROR: ${_system} not found. Haven't you completed the build?"
		exit -1
	fi
	
	# /dev/sd...? /dev/mmc...? /dev/nvme...?
	rm -f isdisk || exit -1
	gcc -o isdisk -O3 -fPIC isdisk.c || exit -1
	_boot="${2}1"
	_type="$(./isdisk ${2})"
	if (test "${_type}" = "mm" -o "${_type}" = "nv"); then
		_boot="${2}p1"
	fi
	
	#if (!(test "${3}" = "force")); then
	#	echo "WARNING:"
	#	echo "This will erase everything on ${2}."
	#	printf "Are you sure? [Yes, do as I say!] "
	#	read _answer
	#	if (test "${_answer}" != "Yes, do as I say!"); then
	#		echo "Bailed out."
	#		exit -1
	#	fi
	#fi
	
	# Flash the image first
	dd if=${_system} of=${2} || exit -1
	
	# Mount the boot partition, and pack the initial ramdisk in it
	if (test -e "bootp"); then
		umount bootp
		rm -rf bootp || exit -1
	fi
	mkdir -p bootp || exit -1
	mount ${_boot} bootp || exit -1
	cp -f buildroot-${_idCommitBR}/output/images/rootfs.cpio bootp/ || exit -1
	umount bootp || exit -1
	rmdir bootp || exit -1
	
	# Wait until it is really done
	sync
fi
