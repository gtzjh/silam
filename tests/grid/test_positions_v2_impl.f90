submodule (positions_v2) test_positions_v2_impl
  implicit none

contains

  module SUBROUTINE pos_tests()
    !
    ! Description:
    ! Test stuff for the positions and poles.
    !
    ! Author: Mika Salonoja, FMI
    ! 
    !
    IMPLICIT NONE
    !
    ! Local declarations:
    TYPE(silam_grid_position) :: pos1, pos2
    
    TYPE(silam_pole) :: odd_pole
    
    REAL :: oddlat, oddlon

    PRINT *, ' The meteo south pole : ',&
             & fu_southpole_lat(meteo_pole), &
             & fu_southpole_lon(meteo_pole)
!             & fu_southpole_lat(dispersion_pole), &
!             & fu_southpole_lon(dispersion_pole)
    
    pos1 = fu_set_position(59., 0., 92500., fu_wallclock(), geo_global_grid)
        
    call msg(fu_connect_strings('Position1 geographical:', &
                         & fu_geographical_latlon_string(pos1,geo_global_grid)))
    
    ! this is not legal fortran:
    !PRINT *, 'Position 1 internal: ', pos1
    
    odd_pole = fu_set_pole(north_flag, 29., 180.)
    
    IF (error) RETURN
    
    CALL modify_lonlat(0., 0. , meteo_pole, odd_pole, oddlat, oddlon)
    
    PRINT*, ' The odd pole: ', fu_southpole_lat(odd_pole),&
                          & fu_southpole_lon(odd_pole)

    PRINT *, 'Position1 in odd coordinates: ', oddlat, oddlon

    PRINT *, '****************************************'

    pos1 = fu_set_position(59., 0., 92500., fu_wallclock(), geo_global_grid)

    pos2 = fu_set_position(60., 0., 92500., fu_wallclock(), geo_global_grid)

    CALL print_position(pos1)
    CALL print_position(pos2)

    PRINT *, 'Distance: ', fu_horizontal_distance(pos1, pos2)

  END SUBROUTINE pos_tests

end submodule test_positions_v2_impl
