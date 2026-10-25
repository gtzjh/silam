submodule (derived_field_quantities) test_derived_field_quantities_impl
  implicit none

contains

  module SUBROUTINE dq_tests(meteoMarketPtr, post_processed)

    IMPLICIT NONE
    LOGICAL, INTENT(in)  :: post_processed
    CHARACTER (LEN=200) :: fname
    type(meteo_data_source) :: met_src
    TYPE(silja_grid) :: grid
    type(mini_market_of_stacks), pointer :: meteoMarketPtr

!!!$    CALL set_supermarket_storage_grid(&
!!!$        & fu_set_latlon_grid(&
!!!$        & 'harva_testi',&
!!!$        &  0., 0.,&
!!!$        & .false.,&
!!!$        & 40, 40,&
!!!$        & pole_system,&
!!!$        & 0.4, 0.4))
!!!$

    met_src = fmi_hirlam_src
    fname = 'test.v5d'

    CALL supermarket_test_fill(meteoMarketPtr) !post_processed)
    IF (error) RETURN

    CALL make_derived_meteo_fields(meteoMarketPtr, &
                                 & fu_set_shopping_list (met_src,&
                                                       & (/temperature_flag,&
                                                         & u_flag, v_flag,&
                                                         & pressure_flag/), &
                                                       & time_missing, &
                                                       & time_missing, &
                                                       & level_missing,&
                                                       & level_missing), &
                                 & wdr_missing, &
                                 & .true., &
                                 & .true.)
    IF (error) RETURN

!!!$    CALL make_derived_meteo_fields(&
!!!$        & fu_set_shopping_list (&
!!!$        & met_src,&
!!!$        & post_processed,&
!!!$        & (/accept_all_quantities/),&
!!!$        & time_missing, &
!!!$        & time_missing, &
!!!$        & level_missing,&
!!!$        & level_missing))
!!!$    IF (error) RETURN


!    CALL report(meteoMarketPtr) 
!    IF (error) RETURN
    
    CALL arrange_supermarket(meteoMarketPtr,.true., .true.)

!    CALL  report(meteoMarketPtr)

!    CALL supermarket_to_v5d_file(met_src, (/accept_all_quantities/), fname)


  END SUBROUTINE dq_tests

end submodule test_derived_field_quantities_impl
