submodule (supermarket_of_fields) test_supermarket_of_fields_impl
  implicit none

contains

  module SUBROUTINE supermarket_test_fill(miniMarketPtr) !post_processed)

    ! Description:
    ! Fills supermarket with hirlam data
    ! for few hours around wallclock time.
    ! Used for test purposes.
    ! 
    IMPLICIT NONE

    ! Imported parameters with intent IN:
!    LOGICAL, INTENT(in) :: post_processed
    type(mini_market_of_stacks), intent(inout) :: miniMarketPtr
    ! Local declarations:
    TYPE(silja_shopping_list) :: list
    TYPE(silja_time), DIMENSION(max_times) :: times
    INTEGER :: n, i, j, nt
    type(meteo_data_source) :: met_src
    type(grads_template), dimension(1) :: template
    integer, dimension(1) :: iFFormat
    type(wdr_ptr), dimension(:), pointer :: wdrar
    allocate(wdrar(1))
    met_src = met_src_missing
    wdrar(1)%ptr = wdr_missing
    CALL initialize_mini_market(miniMarketPtr, &
                               & 'test', &
                               & 1, & ! one source
                               & 50,& ! we assume: max 1 timenode per file
                               & 800,& ! for each timenode
                               & 100,& ! for each timenode
                               & .true.,&
                               & wdrar, & 
                               &.true.)
    IF (error) RETURN

    list = fu_set_shopping_list (met_src_missing, &
                               & (/temperature_flag,&
                                 & temperature_2m_flag,&
                                 & dew_point_temp_2m_flag,&
                                 & geopotential_flag, &
                                 & u_flag, &
                                 & v_flag, &
                                 & omega_flag, &
                                 & large_scale_accum_rain_flag,&
                                 & convective_accum_rain_flag,&
                                 & large_scale_rain_int_flag,&
                                 & convective_rain_int_flag,&
                                 & relative_humidity_flag,&
                                 & specific_humidity_flag,&
                                 & ground_pressure_flag,&
                                 & msl_pressure_flag,&
                                 & cloud_water_flag,&
                                 & total_precipitation_int_flag /),&
                                 & time_missing,&
                                 & time_missing,&
                                 & level_missing,&
                                 & level_missing)
    IF (error) RETURN

    CALL arrange_supermarket(miniMarketPtr, .true., .true.)

    call msg('data now for following times:')
    CALL supermarket_times(miniMarketPtr, met_src, times, nt, .true.)
    DO i = 1, nt
      call msg(fu_str(times(i)))
    END DO
    deallocate(wdrar)
  END SUBROUTINE supermarket_test_fill

end submodule test_supermarket_of_fields_impl
