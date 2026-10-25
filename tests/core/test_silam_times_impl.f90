submodule (silam_times) test_silam_times_impl
  implicit none

contains

  module SUBROUTINE time_tests()
    !
    ! Description:
    ! Test stuff for times.
    !
    ! Author: Mika Salonoja, FMI
    !
    ! Modules used:
    ! 
    IMPLICIT NONE
    !
    ! Imported parameters:
    !
    ! Local declarations:

    TYPE(silja_time) :: time1, time2, time
    TYPE(silja_interval) :: diff, interval, interval1, interval2

    TYPE(silja_time) :: summertime_change
    integer :: it, itmp
    real(kind=8) :: fTmp8

    !----------------------------------------
    !
    ! 1. 
    !
    ! This  is the demonstartion of a bug
    print *, "Conversion to seconds and back"
    time = fu_set_time_utc(1969, 1, 1, 0, 0, 0.0)
    fTmp8  = silja_time_to_real8(time)
    time1 = real8_to_silja_time(fTmp8)
    ! call ooops("")
    print *, "Time   "//fu_str(time), silja_time_to_real8(time)
    print *, "Time1  "//fu_str(time1), silja_time_to_real8(time1)


!!!$
!!!$
!!!$    PRINT*, ' Time tests:'
!!!$    diff = fu_set_interval_min(20)    
!!!$
!!!$    time1 = fu_set_time(1995, 6, 30, 23, 0, 0., fu_set_interval_h(3))
!!!$    time2 = fu_set_time(1995, 8, 1, 0, 0, 0., fu_set_interval_h(3))  
!!!$    
!!!$    PRINT*, 'time1 :        ', fu_time_string_original(time1)
!!!$    PRINT*, 'time1 in utc:  ', fu_str(time1)
!!!$    
!!!$    PRINT*, 'time1 + diff : ', fu_time_string_original(time1 +&
!!!$  & diff)
!!!$    PRINT*, 'time2 :        ', fu_time_string_original(time2)
!!!$    PRINT*, 'time-diff:     ', time1 - time2
!!!$    
!!!$    PRINT*, 'time now :     ',&
!!!$  & fu_time_string_original(fu_wallclock())
!!!$    PRINT*, 'utc-time now : ',&
!!!$  & fu_str(fu_wallclock())
!!!$    
!!!$
!!!$    PRINT*, ' End of time tests:'
!!!$    PRINT *, '****************************************************'
!!!$
!!!$    interval = fu_set_interval_sec(120.)
!!!$
!!!$    time = fu_set_time_utc(1995, 12, 1, 0, 0, 0.)
!!!$    PRINT*, 'time in utc:  ', fu_str(time)
!!!$    !PRINT*, 'time in utc:  ', time
!!!$    PRINT*,  interval
!!!$    time = time + interval
!!!$    PRINT*, 'time in utc:  ', fu_str(time)
!!!$    !PRINT*, 'time in utc:  ', time
!!!$    
!!!$    PRINT *, '****************************************************'
!!!$    
!!!$    time1 = fu_set_time_utc(1995, 12, 1, 0, 0, 0.)
!!!$    time2 = fu_set_time_utc(1995, 12, 1, 0, 1, 0.)
!!!$    
!!!$    interval = time2 - time1
!!!$!    PRINT*,  interval
!!!$
!!!$    PRINT *, fu_time_string_original(fu_wallclock())
!!!$    PRINT *, fu_str(fu_wallclock())
!!!$    PRINT *, fu_str(fu_wallclock() + one_hour)

    PRINT *, fu_str(fu_wallclock())
    PRINT *, fu_computer_time_string()
    PRINT*, fu_real_hours_utc(fu_wallclock())

    PRINT *, fu_julian_date(fu_wallclock())

    time1 = fu_set_time_utc(1997, 2, 28, 0, 0, 0.) 
    time2 = fu_set_time_utc(1997, 3, 1, 0, 0, 0.) 

    PRINT *, fu_str(time1)
    PRINT *, fu_str(time2)

    PRINT *, fu_interval_string(time1 - time2)
    PRINT *, fu_sec(time1 - time2)

    print *, 'Testing Julian dates'
    call test_julian_dates()



    ! This  is the demonstartion of a bug
    print *, "Trying one second accuracy for time + interval"
    time = fu_set_time_utc(2009, 5, 31, 12, 51, 0.0)


    iTmp = 1

    do while (.not. error)
       time1 = time + (one_week*iTmp)
       time2 = time1 + one_second
       interval1 = time1 - time
       interval2 = time2 - time
       if ( abs(fu_sec(((time + interval1) - (time + interval2)) + one_second)) > 0.001 ) then
            print *, "1s accuracy broke at interval:",  fu_str(interval1)
            exit
       endif
       if (fu_sec(interval1)< 0.) then
          print *, "Broke interval counter at: ", fu_str(one_week * (iTmp/2) )
          print *, "Test passed"
          exit
       endif
       print *, interval1%ii,  interval2%ii, iTmp
       iTmp = iTmp * 2
       if (iTmp <0) then
          print *, "loop counter overflow, accuracy not broken"
          print *, "Test passed"
          exit
       endif

    enddo

    

    print *, "Time   "//fu_str(time), silja_time_to_real8(time)
    print *, "Time1  "//fu_str(time1), silja_time_to_real8(time1)
    print *, "Time2  "//fu_str(time2), silja_time_to_real8(time2)
    
    print *, "Time2 - Time1 = ", fu_sec8(time2 - time1)
    print *, "Time1 - Time  = ", fu_sec8(interval1)
    print *, "Time2 - Time  = ",fu_sec8(interval2)


!    print *, fu_str(time)
!    time = real8_to_silja_time(silja_time_to_real8(time))
!    print *, fu_str(time)
!    print *, ""
!    print *, fu_str(time1)
!    time = real8_to_silja_time(silja_time_to_real8(time1))
!    print *, fu_str(time)
!    print *, ""
!    print *, fu_str(time2)
!    time = real8_to_silja_time(silja_time_to_real8(time2))
!    print *, fu_str(time)



  contains
    
    subroutine test_julian_dates()
      implicit none
      integer :: jul_day_int
      real(r8k) :: jul_day_real
      type(silja_time) :: time, time2
      character(len=*), parameter :: sub_name = 'test_julian_dates'
      
      time = fu_set_time_utc(2009, 5, 31, 12, 51, 0.0)
      if (fu_fails(fu_julian_date(time) == 151, 'T1', sub_name)) continue
      if (fu_fails(ceiling(fu_julian_date_real(time)) == 151, 'T2', sub_name)) then 
        print *, fu_julian_date(time), fu_julian_date_real(time)
      end if
      
      time2 = fu_julian_date_to_time(fu_julian_date_real(time), fu_year(time))
      print *, fu_str(time2)
      if (fu_fails(fu_julian_date_to_time(fu_julian_date_real(time), fu_year(time)) == time, 'T3', sub_name)) &
           & continue

    end subroutine test_julian_dates
    

  END SUBROUTINE time_tests

end submodule test_silam_times_impl
