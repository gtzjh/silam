submodule (grib_api_io) test_grib_api_io_impl
  implicit none

contains

  module SUBROUTINE grib_tests(io_switch)

    ! Language: ANSI Fortran 90
    !
    IMPLICIT NONE
    
    ! Imported parameter
    integer, intent(in) :: io_switch
    
    !
    ! Local declarations:
    INTEGER :: unit
    CHARACTER (LEN=clen) :: fname1, fname2
    TYPE(silja_time) :: time
!    TYPE(silja_stack), TARGET :: stack
!    TYPE(silja_shopping_list) :: list
    TYPE(silja_grid) :: grid_in
    TYPE(silja_field), TARGET :: field
    TYPE(silja_field), POINTER :: fieldpointer
    TYPE(silja_field_id) :: id
    INTEGER :: grib_unit, iTmp, io_status
    LOGICAL :: eof
    CHARACTER (LEN=fnlen) :: fname
    INTEGER :: i, j, indGribOut, iTimeRangeIndicator, nMsg
    REAL, DIMENSION(:), pointer :: grid_data
    !    INTEGER :: GetGribMsgByFn
    CHARACTER (LEN=worksize) :: gribstring
    real :: scale_factor
    logical :: ifZeroNegatives
    type(silja_field_id),dimension(:), pointer :: idList  !Returns a pointer
    

    if(io_switch == 1)then

    fname = 'ecglob100_VEG_2020042200+00.sfc' !Broken
    CALL open_grib_file_i(fname,grib_unit, interval_missing)
    fname = 'ecglob100_VEG_2020042100+00.sfc' !Works
    CALL open_grib_file_i(fname,grib_unit, interval_missing)


    stop



    IF (error) RETURN
    call id_list_from_grib_file(grib_unit, idList, nMsg)

    DO i = 1,nMsg

      call report(idList(i))


    END DO

    CALL close_grib_file_i(grib_unit) 

    else
      !
      ! Test for writing
      !

id = fu_set_field_id(met_src_missing,&
                                     & temperature_flag, &
                                     & fu_wallclock(),&
                                     & one_hour, &
                                     & geo_global_grid,&
                                     & surface_level)

grid_data => fu_work_array(fu_number_of_gridpoints(geo_global_grid))
iTmp = 1
do io_status = 1, fu_number_of_gridpoints(geo_global_grid)
  grid_data(io_status) = iTMp
  iTmp = iTmp + 1
end do

    CALL grib_open_file(grib_unit, 'try_grib', 'wb', io_status)
    if(io_status /= GRIB_SUCCESS)then
      call test_bind_process_grib_status(io_status,'Open_file','field_id_to_gribheadings')
    endif
    !
    ! Create the message from a ready-made sample
    !
    call grib_new_from_samples(indGribOut,'GRIB1', io_status)
    if(io_status /= GRIB_SUCCESS)then
      call test_bind_process_grib_status(io_status,'GRIB1','field_id_to_gribheadings')
    endif
    !
    ! Product identification.
    !
    call grib_set(indGribOut,'editionNumber', 1, io_status)
    if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'editionNumber','field_id_to_gribheadings')
    !
    ! Set the basic parts of identification.
    ! 
!    call grib_set(indGribOut,'identificationOfOriginatingGeneratingCentre',centre_fmi, io_status)
!    if(io_status /= GRIB_SUCCESS) call process_grib_status(io_status,'identificationOfOriginatingGeneratingCentre','field_id_to_gribheadings')
    call grib_set(indGribOut,'centre',centre_fmi, io_status)
    if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'centre','field_id_to_gribheadings')

    call grib_set(indGribOut,'subCentre',int_missing, io_status)
    if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'subCentre','make_grib_1_header')

    call grib_set(indGribOut,'generatingProcessIdentifier',model_silam, io_status)
    if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'generatingProcessIdentifier','field_id_to_gribheadings')

!    call grib_set(indGribOut,'gridType',255, io_status)
!    if(io_status /= GRIB_SUCCESS) call process_grib_status(io_status,'gridType','field_id_to_gribheadings')  ! Unknown grid, see grid definition section
    
        call grib_set(indGribOut,'section1Flags',192, io_status)
        if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'section1Flags','field_id_to_gribheadings')   !- both sections 2 and 3(bitmap) present
        call grib_set(indGribOut,'bitmapPresent',0, io_status)
        if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'bitmapPresent','field_id_to_gribheadings')   ! Bitmap follows
        call grib_set(indGribOut,'missingValue', int_missing, io_status)
        if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'missingValue','field_id_to_gribheadings')  ! Missing integer in the binary data array
        call grib_set(indGribOut,'missingValue',real_missing, io_status)
        if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'missingValue','field_id_to_gribheadings') ! Missing real 

    !
    ! We are not going to rearrange the arrays, so have to overwrite the scanning mode
    !
    call grib_set(indGribOut,'iScansNegatively',1,io_status) ! 0 if rows enumerated DEscendingly
    if(io_status /= GRIB_SUCCESS) then
      call test_bind_process_grib_status(io_status,'iScansNegatively','field_id_to_gribheadings')
    endif
    
    call grib_set(indGribOut,'jScansPositively',0,io_status)  ! 0 if columns enumerated Ascendingly
    if(io_status /= GRIB_SUCCESS) then
      call test_bind_process_grib_status(io_status,'jScansPositively','field_id_to_gribheadings')
    endif
    call grib_set(indGribOut,'jPointsAreConsecutive',0,io_status) ! 0 if consequtive values along row
    if(io_status /= GRIB_SUCCESS) then
      call test_bind_process_grib_status(io_status,'jPointsAreConsecutive','field_id_to_gribheadings')
    endif

        call grib_set(indGribOut,'level', 10.0, io_status)
        if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'level','set_field_level_to_grib')

        call grib_set(indGribOut,'numberOfVerticalCoordinateValues',0, io_status)
        if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'numberOfVerticalCoordinateValues','set_field_level_to_grib')

    CALL test_bind_set_field_time_to_grib(id, indGribOut, iTimeRangeIndicator)   ! Time indicators

!    CALL set_field_grid_to_grib(geo_global_grid, indGribOut) 
!    call grib_set(indGribOut,'decimalScaleFactor',1,io_status)
!    if(io_status /= GRIB_SUCCESS) then
!      call process_grib_status(io_status,'decimalScaleFactor','field_id_to_gribheadings')
!    endif
!    call grib_set(indGribOut,'decimalPrecision',16,io_status)
!    if(io_status /= GRIB_SUCCESS) then
!      call process_grib_status(io_status,'decimalPrecision','field_id_to_gribheadings')
!    endif

    call grib_set(indGribOut,'complexPacking',0,io_status)
    if(io_status /= GRIB_SUCCESS) then
      call test_bind_process_grib_status(io_status,'complexPacking','field_id_to_gribheadings')
    endif

      call grib_set(indGribOut, 'table2Version', 130, io_status)
      if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'table2Version','make_grib_1_header')
      call grib_set(indGribOut,'indicatorOfParameter', 123, io_status)
      if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'indicatorOfParameter','make_grib_1_header')
      call grib_set(indGribOut,'indicatorOfTypeOfLevel', 1, io_status)
      if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'indicatorOfTypeOfLevel','make_grib_1_header')
      call grib_set(indGribOut,'level', 10.0, io_status)
      if(io_status /= GRIB_SUCCESS) call test_bind_process_grib_status(io_status,'level','make_grib_1_header')

!    io_status = grib_f_set_real4_array(indGribOut, 'values', grid_data, fu_number_of_gridpoints(fu_grid(id)))
    call grib_set(indGribOut, 'values', grid_data(1:fu_number_of_gridpoints(fu_grid(id))), io_status)
    if(io_status /= GRIB_SUCCESS)then
      call test_bind_process_grib_status(io_status,'values','write_next_field_to_gribfile')
    endif
    
    
    call grib_get(indGribOut, 'getNumberOfValues', iTmp, io_status)
    call msg('getNumberOfValues', iTmp)
    
    ! 
    ! Write to file and release the structure
    !
    CALL grib_write(indGribOut, &             ! message index in grib_api
                  & grib_unit, & ! file binary unit
                  & io_status)
    IF (io_status /= GRIB_SUCCESS) THEN
      call set_error('Writing to GRIB failed','write_next_field_to_gribfile')
      CALL unset_error('write_next_field_to_gribfile')
    END IF

    call grib_release(indGribOut, io_status)
    IF (io_status /= GRIB_SUCCESS) THEN
      call set_error('Cannot release the grib field','write_next_field_to_gribfile')
      CALL unset_error('write_next_field_to_gribfile')
    END IF

    CALL grib_close_file(grib_unit,io_status)



    endif


  END SUBROUTINE grib_tests

end submodule test_grib_api_io_impl
