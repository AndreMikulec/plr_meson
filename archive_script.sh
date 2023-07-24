
cd "$(dirname "$0")"

. ./init.sh

logok "BEGIN after_build.sh"

set -v -x -e
# set -e

# put this in all non-init.sh scripts - PGROOT is empty, if using a mingw binary
# but psql is already in the path
if [ -f "${PGROOT}/bin/psql" ]
then
  export PATH=${PGROOT}/bin:${PATH}
fi
#
# cygwin # PGROOT: /usr - is the general location of binaries (psql) and already in the PATH
#
# $ echo $(cygpath "C:\cygwin\bin")
# /usr/bin
#
# cygwin # initdb, postgres, and pg_ctl are here "/usr/sbin"
if [ -f "${PGROOT}/sbin/postgres" ]
then
  export PATH=${PGROOT}/sbin:${PATH}
fi


pg_ctl -D ${PGDATA} -l logfile start

if [ "${compiler_style}" == "mingw" ]
then
  winpty -Xallow-non-tty psql -d postgres --quiet --tuples-only -c "\pset footer off" -c "\timing off" -c "select current_setting('server_version_num')::integer;" --output=${GITHUB_WORKSPACE}/server_version_num.txt
else
                         psql -d postgres --quiet --tuples-only -c "\pset footer off" -c "\timing off" -c "select current_setting('server_version_num')::integer;" --output=${GITHUB_WORKSPACE}/server_version_num.txt
fi

# done with "pg-online"
# must stop, else the job will hang.
pg_ctl -D ${PGDATA} -l logfile stop



# also used in compiler - msvc
#
./server_version_num.sh
export server_version_num=$(cat ${GITHUB_WORKSPACE}/server_version_num.txt)
loginfo "server_version_num ${server_version_num}"
#
# also works
# export A_VAR=$(echo -n $(sed -r 's/\s+//g' a_version.txt))

loginfo "server_version_num ${server_version_num}"
loginfo "OLD pgversion ${pgversion}"
loginfo "OLD pg ${pg}"
#
# override - mingw and cygwin binary case
if [ "${pg}" == "repository" ]
  then
  export pg=$(postgres -V | grep -oP '(?<=\) ).*$')
  loginfo "NEW pg ${pg}"
  if [ ${server_version_num} -gt 999999 ]
  then
    export pgversion=$(echo ${pg} | grep -oP '^\d+')
  else
    export pgversion=$(echo ${pg} | grep -oP '^\d+[.]\d+')
  fi
  loginfo "NEW pgversion ${pgversion}"
fi
loginfo "OLD or NEW pgversion ${pgversion}"

#
# export pgversion
#
echo "pgversion=${pgversion}" >> ${GITHUB_ENV}


pg_config | grep "^PKGLIBDIR\|^SHAREDIR" | sed "s/ = /=/" | sed s"/^/export /" > newvars.sh
. ./newvars.sh

mkdir                                 tmp
cp LICENSE                            tmp/PLR_LICENSE
mkdir -p                              tmp/lib
cp ${PKGLIBDIR}/plr.dll               tmp/lib
mkdir -p                              tmp/share/extension
cp ${SHAREDIR}/extension/plr.control  tmp/share/extension
cp ${SHAREDIR}/extension/plr--*.sql   tmp/share/extension
#
if [ "${rversion}" == "repository" ]
then
  # later(now) - dynamically determing the R version
  #
  # Tomas Kalibera custom build may contain spaces 
  # so gsub replaces spaces with underscores
  # 
  # avoid cywin error - WARNING: ignoring environment value of R_HOME
  export R_HOME_OLD=${R_HOME}
  unset R_HOME
  export rversion=$(Rscript --vanilla -e 'cat(gsub('\'' '\'', replacement = '\''_'\'', x = paste0(R.version$major,'\''.'\'',R.version$minor,tolower(R.version$status))))' 2>/dev/null)
  export R_HOME=${R_HOME_OLD}
  #
  # export rversion
  #
  echo "rversion=${rversion}" >> ${GITHUB_ENV}

fi


export var7z=plr-${gitrevshort}-${os}-pg${pgversion}-R${rversion}-${Platform}-${Configuration}-${compiler}-${builder}.7z
#
echo "var7z=${var7z}" >> ${GITHUB_ENV}
#
loginfo "${var7z}"

echo ${GITHUB_WORKSPACE}

loginfo "BEGIN plr 7z CREATION"
7z a -t7z -mmt24 -mx7 -r  ${GITHUB_WORKSPACE}/${var7z} ./tmp/*
ls -alrt                  ${GITHUB_WORKSPACE}/${var7z}
loginfo "BEGIN plr 7z LISTING"
# 7z l                      ${GITHUB_WORKSPACE}/${var7z}
loginfo "END   plr 7z LISTING"
loginfo "END plr 7z CREATION"


#
#                                     # not yet tried/tested in cygwin
#                                     # cygwin case
if [ -f "${PGROOT}/bin/postgres" ] || [ -f "${PGROOT}/sbin/postgres" ]
then
  loginfo "BEGIN pg 7z CREATION"
  export varpg7z=pg-${os}-pg${pg}-${Platform}-${Configuration}-${compiler}-${builder}.7z
  #
  echo "varpg7z=${varpg7z}" >> ${GITHUB_ENV}
  #
  loginfo "${varpg7z}"
  cd ${PGROOT}
  ls -alrt
  
  loginfo                                       "${varpg7z}"
  7z a -t7z -mmt24 -mx7 -r   ${GITHUB_WORKSPACE}/${varpg7z} *
  # 7z l                       ${GITHUB_WORKSPACE}/${varpg7z}
  ls -alrt                   ${GITHUB_WORKSPACE}/${varpg7z}
  export  pg_7z_size=$(find "${GITHUB_WORKSPACE}/${varpg7z}" -printf "%s")
  loginfo "pg_7z_size $pg_7z_size" 
  #                       96m
  if [ ${pg_7z_size} -gt 100663296 ] 
  then
    rm -f    ${GITHUB_WORKSPACE}/pg-${os}-pg${pgversion}-${Platform}-${Configuration}-${compiler}-${builder}.7z
    loginfo "${GITHUB_WORKSPACE}/pg-${os}-pg${pgversion}-${Platform}-${Configuration}-${compiler}-${builder}.7z is TOO BIG so removed."
  fi
  #
  cd ${GITHUB_WORKSPACE} 
  loginfo "END   pg 7z CREATION"
fi

set +v +x +e
# set +e

logok "END   after_build.sh"
