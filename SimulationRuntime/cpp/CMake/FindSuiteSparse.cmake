# This file tries to find umfpack, which is part of the suitesparse library-package. Normally the umfpack-library is build with the c-runtime, so we first try 
# to use these files. The following variables are set:
#
# SUITESPARSE_UMFPACK_FOUND                          - True if the umfpack-library of suite sparse was found
# SUITESPARSE_UMFPACK_USE_OMC                        - True if the umfpack-include and libraries of OpenModelica should be used
# SUITESPARSE_UMFPACK_INCLUDE_DIR                    - The include folders that contain umfpack.h and UFconfig.h
# SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC                - This variable contains either the absolute path to the include dir, if the system version is used or the relative path to $(OMHOME) of the OMC-Version is used
# SUITESPARSE_UMFPACK_LIBRARIES                      - The umfpack libraries including the amd library
# SUITESPARSE_UMFPACK_LIBRARIES_OMC                  - This variable contains either the absolute path to umfpack libraries, if the system version is used or the relative path to $(OMHOME) of the OMC-Version is used
# SUITESPARSE_UMFPACK_LIBS                           - The directory containing the umfpack libraries

SET(SUITESPARSE_UMFPACK_FOUND false)
SET(SUITESPARSE_UMFPACK_USE_OMC false)

SET(SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC "")

MESSAGE(STATUS "Searching for umfpack.h of OpenModelica")
FIND_FILE(UMFPACK_H_OMC umfpack.h HINTS "${CMAKE_SOURCE_DIR}/../../build/include/omc/c/suitesparse/Include" NO_DEFAULT_PATH)
FIND_FILE(UMFPACK_H umfpack.h)
FIND_FILE(UFCONFIG_H_OMC UFconfig.h HINTS "${CMAKE_SOURCE_DIR}/../../build/include/omc/c/suitesparse/Include" NO_DEFAULT_PATH)
FIND_FILE(UFCONFIG_H UFconfig.h)
FIND_LIBRARY(UMFPACK_LIB_OMC umfpack HINTS "${CMAKE_SOURCE_DIR}/../../build/lib/omc" NO_DEFAULT_PATH)
FIND_LIBRARY(UMFPACK_LIB umfpack)
FIND_LIBRARY(AMD_LIB_OMC amd HINTS "${CMAKE_SOURCE_DIR}/../../build/lib/omc" NO_DEFAULT_PATH)
FIND_LIBRARY(AMD_LIB amd)

IF(UMFPACK_H_OMC AND UFCONFIG_H_OMC AND UMFPACK_LIB_OMC AND AMD_LIB_OMC)
	GET_FILENAME_COMPONENT(SUITESPARSE_UMFPACK_INCLUDE_DIR "${UMFPACK_H_OMC}" PATH)
	SET(SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC "$(OMHOME)/include/omc/c/suitesparse/Include")
	GET_FILENAME_COMPONENT(SUITESPARSE_UFCONFIG_INCLUDE_DIR "${UFCONFIG_H_OMC}" PATH)
	SET(SUITESPARSE_UFCONFIG_INCLUDE_DIR_OMC "$(OMHOME)/include/omc/c/suitesparse/Include")

	FOREACH(lib ${UMFPACK_LIB_OMC})
		GET_FILENAME_COMPONENT(libTrimmed "${lib}" NAME)
		LIST(APPEND SUITESPARSE_UMFPACK_LIBRARIES_OMC "$(OMHOME)/lib/omc/${libTrimmed}")
	ENDFOREACH(lib ${UMFPACK_LIB_OMC})
	LIST(APPEND SUITESPARSE_UMFPACK_LIBRARIES ${UMFPACK_LIB_OMC})

	FOREACH(lib ${AMD_LIB_OMC})
		GET_FILENAME_COMPONENT(libTrimmed "${lib}" NAME)
		LIST(APPEND SUITESPARSE_UMFPACK_LIBRARIES_OMC "$(OMHOME)/lib/omc/${libTrimmed}")
	ENDFOREACH(lib ${AMD_LIB_OMC})
	LIST(APPEND SUITESPARSE_UMFPACK_LIBRARIES ${AMD_LIB_OMC})
	
	MESSAGE(STATUS "Using ${UMFPACK_H_OMC} of OpenModelica")
	SET(SUITESPARSE_UMFPACK_FOUND true)
	SET(SUITESPARSE_UMFPACK_USE_OMC true)
	SET(SUITESPARSE_UMFPACK_LIBS "$(OMHOME)/build/lib/omc")
ELSE(UMFPACK_H_OMC AND UMFPACK_LIB_OMC)
	MESSAGE(STATUS "Umfpack of OpenModelica was not found. Try to find system umfpack.")

	IF(UMFPACK_H)
		GET_FILENAME_COMPONENT(SUITESPARSE_UMFPACK_INCLUDE_DIR "${UMFPACK_H}" PATH)
		SET(SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC ${SUITESPARSE_UMFPACK_INCLUDE_DIR})
		MESSAGE(STATUS "Using ${UMFPACK_H} of System")
		SET(SUITESPARSE_UMFPACK_FOUND true)
	ELSE(UMFPACK_H)
		MESSAGE(STATUS "Could not find umfpack.h")
		SET(SUITESPARSE_UMFPACK_FOUND false)
	ENDIF(UMFPACK_H)

	IF(UFCONFIG_H)
		GET_FILENAME_COMPONENT(SUITESPARSE_UFCONFIG_INCLUDE_DIR "${UFCONFIG_H}" PATH)
		IF("${SUITESPARSE_UMFPACK_INCLUDE_DIR}" STREQUAL "${SUITESPARSE_UFCONFIG_INCLUDE_DIR}")
		ELSE()
			SET(SUITESPARSE_UFCONFIG_INCLUDE_DIR_OMC ${SUITESPARSE_UFCONFIG_INCLUDE_DIR})
		ENDIF()
		
		MESSAGE(STATUS "Using ${UFCONFIG_H} of System")
		SET(SUITESPARSE_UMFPACK_FOUND true)
	ELSE(UFCONFIG_H)
		MESSAGE(STATUS "Could not find UFconfig.h")
		SET(SUITESPARSE_UMFPACK_FOUND false)
	ENDIF(UFCONFIG_H)

	IF(UMFPACK_LIB AND UMFPACK_H)
		SET(SUITESPARSE_UMFPACK_FOUND true)
		LIST(APPEND SUITESPARSE_UMFPACK_LIBRARIES ${UMFPACK_LIB})
		LIST(APPEND SUITESPARSE_UMFPACK_LIBRARIES_OMC ${UMFPACK_LIB})
		MESSAGE(STATUS "Using ${UMFPACK_LIB} of System")
	ELSE(UMFPACK_LIB AND UMFPACK_H)
		SET(SUITESPARSE_UMFPACK_FOUND false)
		MESSAGE(STATUS "Could not find umfpack libraries")
	ENDIF(UMFPACK_LIB AND UMFPACK_H)

	IF(AMD_LIB AND UMFPACK_LIB AND UMFPACK_H)
		LIST(APPEND SUITESPARSE_LIBRARIES ${AMD_LIB})
		LIST(APPEND SUITESPARSE_LIBRARIES_OMC ${AMD_LIB})
	ELSE(AMD_LIB AND UMFPACK_LIB AND UMFPACK_H)
		SET(SUITESPARSE_UMFPACK_FOUND false)
		MESSAGE(STATUS "Could not find amd library")
	ENDIF(AMD_LIB AND UMFPACK_LIB AND UMFPACK_H)
	GET_FILENAME_COMPONENT(SUITESPARSE_UMFPACK_LIBS "${UMFPACK_LIB}" DIRECTORY)
ENDIF(UMFPACK_H_OMC AND UFCONFIG_H_OMC AND UMFPACK_LIB_OMC AND AMD_LIB_OMC)