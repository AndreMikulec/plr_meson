project('plr', 'c',
  version : '8_4_5',
  license : 'GNU Public License Version 2',
)

R_home = get_option('R_HOME')
if R_home == ''
  error('One must supply: -DR_HOME=newvalue')
endif

pg_home = get_option('PG_HOME')
if pg_home == ''
  error('One must supply: -DPG_HOME=newvalue')
endif

plr_sources = files(
  'plr.c',
  'pg_conversion.c',
  'pg_backend_support.c',
  'pg_userfuncs.c',
  'pg_rsupport.c',
)

plr_deps = []
dep_libR = dependency('libR', required : true)
plr_deps += dep_libR
dep_libpq = dependency('libpq', required : true)
plr_deps += dep_libpq
dep_libpostgres = dependency('libpostgres', required : true)
plr_deps += dep_libpostgres

plr_incdir = []
pg_incdir1= include_directories(R_home / 'include')
plr_incdir += pg_incdir1
pg_incdir2 = include_directories(pg_home / 'include' / 'postgresql' / 'server' )
plr_incdir += pg_incdir2
#  mingw
pg_incdir3 = include_directories(pg_home / 'include' / 'postgresql' / 'server' / 'port' / 'win32' )
plr_incdir += pg_incdir3

plr = shared_module('plr',
  plr_sources,
  name_prefix : '',
  include_directories: plr_incdir,
  dependencies: plr_deps,
)

if meson.version().version_compare('>=0.57')

  summary(
    {
      'libR'               : dep_libR,
      'libpq'              : dep_libpq,
      'libpostgres (fake)' : dep_libpostgres,
    },
    section: 'Required Dependencies',
  )

endif
