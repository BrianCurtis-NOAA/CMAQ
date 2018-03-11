#!/bin/csh -f

# ====================== CCTMv5.0.2 Build Script ======================= #
# Usage: bldit.cctm >&! bldit.cctm.log                                   #
# Requirements: I/O API & netCDF libs, Git, and a Fortran compiler,      #
#               MPI for multiprocessor computing                         #
# Note that this script is configured/tested for Red Hat Linux O/S       #
# The following environment variables must be set for this script to     #
# build an executable.                                                   #
#   setenv M3HOME  <source code Git repository base path>                #
#   setenv M3LIB   <code libraries>                                      #
# To report problems or request help with this script/program:           #
#             http://www.cmascenter.org/html/help.html                   #
# ====================================================================== #

#> Source the config.cmaq file to set the build environment
 source ../config.cmaq

#> Check for M3HOME and M3LIB settings:
 if ( ! -e $M3HOME || ! -e $M3LIB ) then
    echo "   $M3HOME or $M3LIB directory not found"
    exit 1
 endif
 echo "    Model repository base path: $M3HOME"
 echo "                  library path: $M3LIB"

#> If $M3MODEL not set, default to $M3HOME
 if ( $?M3MODEL ) then
    echo "         Model repository path: $M3MODEL"
 else
    setenv M3MODEL $M3HOME
    echo " default Model repository path: $M3MODEL"
 endif

 set BLD_OS = `uname -s`        ## Script set up for Linux only 
 if ($BLD_OS != 'Linux') then
    echo "   $BLD_OS -> wrong bldit script for host!"
    exit 1
 endif

 #set echo

#:#:#:#:#:#:#:#:#:#:#:# Begin User Input Section #:#:#:#:#:#:#:#:#:#:#:#

#> user choices: Git repository
 set GlobInc = $M3MODEL/CCTM_VBS/ICL
 set Mechs   = $M3MODEL/CCTM_VBS/MECHS

 setenv REPOROOT $M3MODEL/CCTM_VBS

#> user choices: base working directory, application string
 set Base = $cwd
 set APPL  = D502avbs
 set MODEL = CCTM_${APPL}_$EXEC_ID
 set CFG   = cfg.$MODEL

#set Local   # do NOT copy the source files into the BLD directory -
             # comment out to copy the source files (default if not set)

#> The "BLD" directory for checking out and compiling source code
 set Bld = $Base/BLD_${APPL}
 if ( ! -e "$Bld" ) then
    mkdir $Bld
 else
    if ( ! -d "$Bld" ) then
       echo "   *** target exists, but not a directory ***"
       exit 1
    endif
 endif

 cd $Bld

#> user choices: bldmake command
#set MakeFileOnly   # builds a Makefile to make the model, but does not compile -
                    # comment out to also compile the model (default if not set)

#> user choices:  single or multiple processors
 set ParOpt             # set for multiple PE's; comment out for single PE

#> user choices: various modules

#set Revision = release       # release = latest CVS revision
#set Revision = '"CMAQv5_0_1"'

 set ModDriver = driver/wrf
#set ModDriver = driver/yamo

 set ModGrid   = grid/cartesian

 if ( $?ParOpt ) then
#   set ModPar = par/par_nodistr
    set ModPar = par/mpi
 else
    set ModPar = par/par_noop
 endif 

 set ModInit   = init/yamo

#set ModAdjc   = ( // yamo option does not need denrate )

 set ModCpl    = couple/gencoor_wrf
#set ModCpl    = couple/gencoor

 set ModHadv   = hadv/yamo

 set ModVadv   = vadv/wrf
#set ModVadv   = vadv/yamo

 set ModHdiff  = hdiff/multiscale

 set ModVdiff  = vdiff/acm2
#set ModVdiff  = vdiff/acm2_mp

 set ModDepv   = depv/m3dry
#set ModDepv   = depv/m3dry_mp

#set ModEmis   = emis/emisv
 set ModEmis   = emis/emisvbs

 set ModBiog   = biog/beis3
 
 set ModPlmrs  = plrise/smoke

 set ModCgrds  = spcs/cgrid_spcs_nml
#set ModCgrds  = spcs/cgrid_spcs_icl

 set ModPhot   = phot/phot_inline
#set ModPhot   = phot/phot_table

#set ModGas    = gas/smvgear
#set ModGas    = gas/ros3
#set ModGas    = gas/ebi_cb05cl
#set ModGas    = gas/ebi_cb05tucl
 set ModGas    = gas/ebi_cb05tucl_ae6vbs
#set ModGas    = gas/ebi_cb05tump
#set ModGas    = gas/ebi_saprc99
#set ModGas    = gas/ebi_saprc07tb
#set ModGas    = gas/ebi_saprc07tc

#set ModAero   = aero/aero5
#set ModAero   = aero/aero6
 set ModAero   = aero/aero6vbs
#set ModAero   = aero/aero6_mp

#set ModCloud  = cloud/cloud_acm_ae5
#set ModCloud  = cloud/cloud_acm_ae6
 set ModCloud  = cloud/cloud_acm_ae6vbs
#set ModCloud  = cloud/cloud_acm_ae6_mp

 set ModPa     = procan/pa

 set ModUtil   = util/util

#> user choices: mechanism
#set Mechanism = cb05cl_ae5_aq
#set Mechanism = cb05tucl_ae5_aq
#set Mechanism = cb05tucl_ae6_aq
 set Mechanism = cb05tucl_ae6vbs_aq
#set Mechanism = cb05tump_ae6_aq
#set Mechanism = saprc99_ae5_aq
#set Mechanism = saprc99_ae6_aq
#set Mechanism = saprc07tb_ae6_aq
#set Mechanism = saprc07tc_ae6_aq
 set Tracer    = trac0               # default: no tracer species

#> user choices: set process analysis linkages
 set PABase    = $GlobInc
 set PAOpt     = pa_noop

#> user choices: computing system configuration:
#>    compiler name and location/link flags
#>    library paths

#> Set full path of Fortran 90 and C compilers
 set FC = ${myFC}
 set FP = $FC
 set CC = ${myCC}

#> Set location of M3Bld executable
#set Blder = $M3LIB/build/bldmake
 set Blder = "$M3LIB/bldmake"

#> Set location of libraries/include files
 set LIOAPI  = "${M3LIB}/ioapi_3.1/Linux2_${system}${compiler_ext} -lioapi"
 set IOAPIMOD = ${M3LIB}/ioapi_3.1/Linux2_${system}${compiler_ext}

 set NETCDF = "${M3LIB}/netcdf/lib -lnetcdf"

 if ( $?ParOpt ) then      # Multiprocessor system configuration
    set PARIO = ${M3LIB}/pario
    set STENEX = ${M3LIB}/se_snl
#   set MPI_INC = ${M3LIB}/mpich/include
    # MPI_INC is set in config.cmaq
 else
    set PARIO = "."
    set STENEX = "${M3LIB}/se_noop"
    set MPI_INC = "."
 endif

#> Set compiler flags
 set F_FLAGS    = "${myFFLAGS} -I ${IOAPIMOD} -I ${PARIO} -I ${STENEX} -I ${MPI_INC} -I."
 set F90_FLAGS  = "${myFRFLAGS} -I ${IOAPIMOD} -I ${PARIO} -I ${STENEX} -I ${MPI_INC} -I."
 set CPP_FLAGS  = ""
 set C_FLAGS    = "${myCFLAGS} -DFLDMN -I ${MPI_INC}"
 set LINK_FLAGS = "${myLINK_FLAG}"

#:#:#:#:#:#:#:#:#:#:#:# End of User Input Section :#:#:#:#:#:#:#:#:#:#:#:#:#

 if ( $?ParOpt ) then      # Multiprocessor system configuration
#   set Mpich = $MPICH 
    set seL = se_snl
    set LIB2 = "-L${M3LIB}/pario -lpario"
    set LIB3 = 
    set LIB4 = "-L${M3LIB}/mpich/lib ${mpi} ${extra_lib}"
    set Str1 = (// Parallel / Include message passing definitions)
    set Str2 = (include SUBST_MPI ${MPI_INC}/mpif.h;)
 else
    set seL = sef90_noop
    set LIB2 =
    set LIB3 =
    set LIB4 =
    set Str1 =
    set Str2 =
 endif

 set LIB1 = "-L${STENEX} -l${seL}"
 set LIB5 = "-L${LIOAPI}"
 set LIB6 = "-L${NETCDF}"
 set LIBS = "$LIB1 $LIB2 $LIB3 $LIB4 $LIB5 $LIB6"
 
source $Base/relinc.cctm
#if ( $status ) exit 1

set ICL_PAR   = $Bld
set ICL_CONST = $Bld
set ICL_FILES = $Bld
set ICL_EMCTL = $Bld
set ICL_MECH  = $Bld
set ICL_PA    = $Bld

#set ICL_PAR   = $GlobInc/fixed/mpi
#set ICL_CONST = $GlobInc/fixed/const
#set ICL_FILES = $GlobInc/fixed/filenames
#set ICL_EMCTL = $GlobInc/fixed/emctrl
#set ICL_PA    = $GlobInc/procan/$PAOpt
#set ICL_MECH  = $Mechs/$Mechanism

 if ( $?ParOpt ) then   # split to avoid line > 256 char
    set PAR = ( -Dparallel )

    set Popt = SE
 else
    echo "   Not Parallel; set Serial (no-op) flags"
    set PAR = ""
    set Popt = NOOP
 endif
 
 set STX1 = ( -DSUBST_MODULES=${Popt}_MODULES\
              -DSUBST_BARRIER=${Popt}_BARRIER )
 set STX2 = ( -DSUBST_GLOBAL_MAX=${Popt}_GLOBAL_MAX\
              -DSUBST_GLOBAL_MIN=${Popt}_GLOBAL_MIN\
              -DSUBST_GLOBAL_MIN_DATA=${Popt}_GLOBAL_MIN_DATA\
              -DSUBST_GLOBAL_TO_LOCAL_COORD=${Popt}_GLOBAL_TO_LOCAL_COORD\
              -DSUBST_GLOBAL_SUM=${Popt}_GLOBAL_SUM\
              -DSUBST_GLOBAL_LOGICAL=${Popt}_GLOBAL_LOGICAL\
              -DSUBST_LOOP_INDEX=${Popt}_LOOP_INDEX\
              -DSUBST_SUBGRID_INDEX=${Popt}_SUBGRID_INDEX )
 set STX3 = ( -DSUBST_HI_LO_BND_PE=${Popt}_HI_LO_BND_PE\
              -DSUBST_SUM_CHK=${Popt}_SUM_CHK\
              -DSUBST_INIT_ARRAY=${Popt}_INIT_ARRAY\
              -DSUBST_COMM=${Popt}_COMM\
              -DSUBST_MY_REGION=${Popt}_MY_REGION\
              -DSUBST_SLICE=${Popt}_SLICE\
              -DSUBST_GATHER=${Popt}_GATHER\
              -DSUBST_DATA_COPY=${Popt}_DATA_COPY\
              -DSUBST_IN_SYN=${Popt}_IN_SYN )

#> make the config file

 set Cfile = ${CFG}.bld
 set quote = '"'

 echo                                                               > $Cfile
 echo "model       $MODEL;"                                        >> $Cfile
 echo                                                              >> $Cfile
 echo "FPP         $FP;"                                           >> $Cfile
 echo                                                              >> $Cfile
 set text = "$quote$CPP_FLAGS $PAR $STX1 $STX2 $STX3$quote;"
 echo "cpp_flags   $text"                                          >> $Cfile
 echo                                                              >> $Cfile
 echo "f_compiler  $FC;"                                           >> $Cfile
 echo                                                              >> $Cfile
 echo "f_flags     $quote$F_FLAGS$quote;"                          >> $Cfile
 echo                                                              >> $Cfile
 echo "f90_flags   $quote$F90_FLAGS$quote;"                        >> $Cfile
 echo                                                              >> $Cfile
 echo "c_compiler  $CC;"                                           >> $Cfile
 echo                                                              >> $Cfile
 echo "c_flags     $quote$C_FLAGS$quote;"                          >> $Cfile
 echo                                                              >> $Cfile
 echo "link_flags  $quote$LINK_FLAGS$quote;"                       >> $Cfile
 echo                                                              >> $Cfile
 echo "libraries   $quote$LIBS$quote;"                             >> $Cfile
 echo                                                              >> $Cfile

 set text="// mechanism:"
 echo "$text ${Mechanism}"                                         >> $Cfile
 echo "// model repository: ${M3MODEL}"                            >> $Cfile
 echo                                                              >> $Cfile
#if ( $compiler == gfort ) then
#  set ICL_PAR = '.'
#  set ICL_CONST = '.'
#  set ICL_FILES = '.'
#  set ICL_EMCTL = '.'
#  set ICL_MECH = '.'
#  set ICL_PA = '.'
#endif
 echo "include SUBST_PE_COMM    $ICL_PAR/PE_COMM.EXT;"             >> $Cfile
 echo "include SUBST_CONST      $ICL_CONST/CONST.EXT;"             >> $Cfile
 echo "include SUBST_FILES_ID   $ICL_FILES/FILES_CTM.EXT;"         >> $Cfile
 echo "include SUBST_EMISPRM    $ICL_EMCTL/EMISPRM.EXT;"           >> $Cfile
 echo "include SUBST_RXCMMN     $ICL_MECH/RXCM.EXT;"               >> $Cfile
 echo "include SUBST_RXDATA     $ICL_MECH/RXDT.EXT;"               >> $Cfile
 echo                                                              >> $Cfile

 set text = "// Process Analysis / Integrated Reaction Rates processing"
 echo $text                                                        >> $Cfile
 echo "include SUBST_PACTL_ID    $ICL_PA/PA_CTL.EXT;"              >> $Cfile
 echo "include SUBST_PACMN_ID    $ICL_PA/PA_CMN.EXT;"              >> $Cfile
 echo "include SUBST_PADAT_ID    $ICL_PA/PA_DAT.EXT;"              >> $Cfile
 echo                                                              >> $Cfile

 echo "$Str1"                                                      >> $Cfile
 if ( $compiler == gfort ) then
  echo "include SUBST_MPI ${MPI_INC}/mpif.h;"                      >> $Cfile
 else
  echo "$Str2"                                                     >> $Cfile
 endif
 echo                                                              >> $Cfile

 set text = "ctm_wrf and ctm_yamo"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModDriver};"                                       >> $Cfile
 echo                                                              >> $Cfile

 set text = "cartesian"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModGrid};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "par, par_nodistr and par_noop"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModPar};"                                          >> $Cfile
 echo                                                              >> $Cfile

 set text = "init_yamo"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModInit};"                                         >> $Cfile
 echo                                                              >> $Cfile

#set text = ""
#echo "// options are" $text                                       >> $Cfile
#echo "Module ${ModAdjc};"                                         >> $Cfile
#echo                                                              >> $Cfile

 set text = "gencoor_wrf and gencoor"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModCpl};"                                          >> $Cfile
 echo                                                              >> $Cfile

 set text = "hyamo"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModHadv};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "vwrf and vyamo"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModVadv};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "multiscale"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModHdiff};"                                        >> $Cfile
 echo                                                              >> $Cfile

 set text = "acm2 and acm2_mp"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModVdiff};"                                        >> $Cfile
 echo                                                              >> $Cfile

 set text = "m3dry and m3dry_mp"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModDepv};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "emis"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModEmis};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "beis3"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModBiog};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "smoke"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModPlmrs};"                                        >> $Cfile
 echo                                                              >> $Cfile

 set text = "cgrid_spcs_nml and cgrid_spcs_icl"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModCgrds};"                                        >> $Cfile
 echo                                                              >> $Cfile

 set text = "phot_inline and phot_table"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModPhot};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "smvgear, ros3, ebi_cb05cl, ebi_cb05tucl, ebi_cb05tump, ebi_saprc99, ebi_saprc07tb, and ebi_saprc07tc"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModGas};"                                          >> $Cfile
 echo                                                              >> $Cfile

 set text = "aero5, aero6, and aero6_mp"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModAero};"                                         >> $Cfile
 echo                                                              >> $Cfile

 set text = "cloud_acm_ae5, cloud_acm_ae6, and cloud_acm_ae6_mp"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModCloud};"                                        >> $Cfile
 echo                                                              >> $Cfile

 set text = "pa, which requires the"
 echo "// options are" $text "replacement of the three"            >> $Cfile
 set text = "// global include files with their pa_noop counterparts"
 echo $text                                                        >> $Cfile
 echo "Module ${ModPa};"                                           >> $Cfile
 echo                                                              >> $Cfile

 set text = "util"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModUtil};"                                         >> $Cfile
 echo                                                              >> $Cfile

 if ( $?ModMisc ) then
    echo "Module ${ModMisc};"                                      >> $Cfile
    echo                                                           >> $Cfile
 endif

#> make the Makefile or the model executable

 unalias mv rm
 if ( $?MakeFileOnly ) then
    if ( $?Local ) then
       $Blder -makefo -git_local $Cfile   # $Cfile = ${CFG}.bld
    else
       $Blder -makefo $Cfile
     # totalview -a $Blder -makefo $Cfile
    endif
 else   # also compile the model
    if ( $?Local ) then
       $Blder -git_local $Cfile
    else
       $Blder $Cfile
    endif
 endif
 mv Makefile $Bld/Makefile.$COMPILER
 if ( -e $Bld/Makefile.$COMPILER && -e $Bld/Makefile ) rm $Bld/Makefile
 ln -s $Bld/Makefile.$COMPILER $Bld/Makefile

 if ( $status != 0 ) then
    echo "   *** failure in $Blder ***"
    exit 1
 endif
 if ( -e "$Base/${CFG}" ) then
    echo "   >>> previous ${CFG} exists, re-naming to ${CFG}.old <<<"
    mv $Base/${CFG} $Base/${CFG}.old
 endif
 mv ${CFG}.bld $Bld/${CFG}

set is_using_git = `ls -alog $M3MODEL | grep git | wc -l`

if ( $is_using_git[1] ) then
#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#:#
 cd $M3MODEL
#set brnch = `git --work-tree=$M3MODEL branch`
 set brnch = `git branch`
 @ i = 0
 while ( $i < $#brnch )
    @ i++
    if ( "$brnch[$i]" == "*" ) @ l = $i + 1
 end
#set rep = `echo $M3MODEL | tr "/" "#"`
 set rep = `echo $cwd | tr "/" "#"`
 set rln = "repo:${rep},branch:${brnch[$l]},compiler:${COMPILER}"
 set ref = $Bld/$rln
 /bin/touch $ref
 if ( -d $M3MODEL/branch ) /bin/cp $M3MODEL/branch/branch.* $Bld
endif

 exit