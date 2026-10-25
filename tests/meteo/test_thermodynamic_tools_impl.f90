submodule (thermodynamic_tools) test_thermodynamic_tools_impl
  implicit none

contains

  module SUBROUTINE thermo_tests()
    
    ! Description:
    ! Test stuff for diy-weather toolbox.
    !
    ! Author: Ilkka Valkama, FMI
    ! 
    !
    IMPLICIT NONE
    !
    ! Local declarations:
!!!$    TYPE(silja_position) :: position, point
!!!$    TYPE(silja_weather_data_rules) :: weather_data_rules
!!!$    TYPE(silja_time) :: time
    INTEGER :: i,j, ik, ii
    REAL :: ddd,ff, uu, vv, rankoe
    !   SET test place and time
!!!$    time = fu_round_closest_hour(fu_wallclock(),backwards)
!!!$    position = fu_helsinki()

!!!$    point = fu_set_position(60., north, 25., east, 100000.,&
!!!$	& fu_round_closest_hour(fu_wallclock(),backwards))
!!!$    CALL update_height(point, 100.)
!!!$    position = fu_set_position(60., north, 25., east, 100000., time)
!!!$    CALL update_height(position, 100.)
!!!$      IF (error) RETURN
!!!$
!!!$
!!!$
!!!$      position = fu_set_position(60.167, north, 24.967, east, 100000., time)
!!!$    CALL update_height(position, 100.)
!!!$      IF (error) RETURN
!!!$     
!!!$      PRINT*, fu_time_string_original(time)
!!!$      PRINT *, '  Solar Elevation at this time : ',&
!!!$	  & fu_solar_elevation_angle(position)
!!!$      PRINT*,' rel. hum 850 hpa ',&
!!!$	  & fu_relative_humidity_on_level(position&
!!!$	& ,pr_level_850hpa)
!!!$      PRINT*,' rel. hum 925 hpa ',&
!!!$	  & fu_relative_humidity_on_level(position&
!!!$	& ,pr_level_925hpa)

!!!$    DO i=1,10
!!!$      PRINT*, ' Anna paine  '
!!!$      READ(*,*)ddd
!!!$      IF(ddd.Lt.0.0) STOP
!!!$      ddd=100.0*ddd
!!!$      ik=20
!!!$      DO j=0,35,5       
!!!$        ff=float(j)+273.15
!!!$    
!!!$    uu=  fu_watervap_diffusivity(ff)
!!!$    PRINT*, ' diffusivity for (',(ff-273.15),',',(ddd/100.),') is ',uu
!!!$    
!!!$        PRINT*, '   '
!!!$        ik=ik+1
!!!$        WRITE(ik,*)(ff-273.15),(ddd/100.),uu
!!!$        rankoe = fu_random_number_center(0.2,0.2)
!!!$        PRINT*, ' PS. Current random = ', rankoe
!!!$        WRITE(ik,*)rankoe
!!!$      end DO
!!!$    END DO
!!!$    
!!!$    DO i=0,36,5
!!!$      ff = FLOAT(i)
     ff = 5.
!!!$      DO ii=0,361,45
!!!$        
!!!$        ddd = FLOAT(ii)/57.29578
!!!$        CALL component_wind(ddd,ff,uu,vv)
!!!$        PRINT*, ' '
!!!$        PRINT*, ' Wind vector : ',uu,vv,' (from ',(ddd*57.29578),ff,' )'
!!!$        PRINT*, ' '
!!!$        CALL normal_wind(uu,vv,ddd,ff)
!!!$        PRINT*, ' (and the other way round = ',(ddd*57.29578),ff,' )'
!!!$      END DO
!!!$    END DO
     ! ddd,ff, uu, vv, rankoe
     DO ii=1,10
       PRINT*, ' Anna lampotila : '
       READ(*,*)uu
       PRINT*, ' '
       uu=uu+273.15
       PRINT*, ' Temperature  is ',(uu-273.15)
       PRINT*, ' and satur.vapor pressure is ',fu_saturat_watervapourpressure(uu)

!!!$       ff = fu_dew_point_from_temp(uu)
!!!$       PRINT*, ' dew point for ',(uu-273.15),' is ',ff
!!!$       vv =  fu_relhum_from_dew_point(uu,ff)
!!!$       PRINT*, ' rel hum should be  ',vv
!!!$       vv =  fu_relhum_from_dew_point(uu,ff)
!!!$       PRINT*, ' (check: ',(fu_dew_point_from_rh(uu,vv)-273.15),') '
!!!$       
!!!$       vv =  fu_saturat_watervapourpressure(uu)
!!!$       ddd =  vapor_pressure_dewp(ff)  
!!!$       PRINT*, ' and satur.vapor pressure is ',vv
!!!$       PRINT*, ' ( flexpart gives : ',ddd,') '
!!!$        fu_saturat_watervapourpressure(uu)
       PRINT*, ' '
     END DO
     
    END SUBROUTINE thermo_tests

  module SUBROUTINE temp_test()

    !Description:
    !Teststuff for temperature toolbox>
    !
    !Author:
    !
    !
    IMPLICIT NONE
    !
    ! 



    PRINT*,'263.15K:', fu_watervapour_satur_p(263.15)
    PRINT*,'293.15K:', fu_watervapour_satur_p(293.15)
!!!$    PRINT*,'300K:', fu_watervapour_satur_p(300.)
!!!$    PRINT*,'310K:', fu_watervapour_satur_p(310.)
!!!$    PRINT*,'320K:', fu_watervapour_satur_p(320.)



  END SUBROUTINE temp_test

end submodule test_thermodynamic_tools_impl
