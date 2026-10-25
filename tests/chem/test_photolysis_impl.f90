submodule (photolysis) test_photolysis_impl
  implicit none

contains

  module subroutine test_lut_rates_full()
    implicit none
    

    integer, parameter :: nLev = 3, nMet = 5

    integer, dimension(9), target :: metindex
    real, dimension(9,3) :: met_dat
    real, dimension(num_reactions, 3) :: rates
    real, dimension(3), parameter :: aod_ext =  (/1. , 1., 1./), &
                                  & aod_scat = (/ .9,  .9, .9/), &
                                  & thickness = (/100., 100., 100./)
    real, dimension(3), parameter :: o3_col =  (/346. , 300., 2.8e-2/) ! in DU (values approximate for nm-sum) CHECK!

    type(silja_time) :: now 
    integer :: ind_lev, ind_react
    
    metindex(:) = (/1,2,3,4,5,6,7,8,9/)
    imet_albedo => metindex(1)
    imet_cwc3d  => metindex(2) 
    imet_press  => metindex(3) 
    imet_cwcol  => metindex(4) 
    imet_lat    => metindex(5) 
    imet_tcc    => metindex(6)
    imet_temp    => metindex(7)
    imet_lcwc3d  => metindex(8)
    imet_lcwcol  => metindex(9)

     met_dat(imet_albedo,:) = 0.3
     met_dat(imet_cwc3d,:) =  (/3e-3, 1e-3, 0.0/) ! kg/m3!!
     met_dat(imet_press,:) = (/1e5, 2500.0, 280.0/) ! Pa!!
     met_dat(imet_cwcol,:) =  3e-3
     met_dat(imet_lat,:) =    0. 
     met_dat(imet_tcc,:) =    0.3    
     met_dat(imet_temp,:) =    (/273, 263, 253/)
     met_dat(imet_lcwc3d,:) =  (/3e-3, 1e-3, 0.0/) ! kg/m3!!                                                 
     met_dat(imet_lcwcol,:) =  3e-3
    
    now = fu_set_time_utc(2001, 7, 1, 0, 0, 0.0)
    
    ! equator, time as above, pressure as in col_press, sun at zenith.
    !call get_photorates_column(met_dat, 1., real_missing, now, aod_ext, &
    !     & aod_scat, o3_col, rates, .true., .true., thickness, version)
    do ind_lev = 1, nLev
      call msg('Level, pressure:', ind_lev, met_dat(imet_press,ind_lev))
      do ind_react = 1, num_reactions
        call msg('Reaction, rate', ind_react, rates(ind_react, ind_lev))
      end do
    end do

    ! equator, time as above, pressure as in col_press, 30 degree zenith angle.
    !call get_photorates_column(met_dat, cos(30./180*pi), real_missing, now, aod_ext, &
    !     & aod_scat, o3_col, rates, .true., .true., thickness)
    do ind_lev = 1, nLev
      call msg('Level, pressure:', ind_lev, met_dat(imet_press,ind_lev))
      do ind_react = 1, num_reactions
        call msg('Reaction, rate', ind_react, rates(ind_react, ind_lev))
      end do
    end do

    ! equator, time as above, pressure as in col_press, 91 degree zenith angle.
    !call get_photorates_column(met_dat,  cos(91./180*pi), real_missing, now, aod_ext, &
    !     & aod_scat, o3_col, rates, .true., .true., thickness)
    call msg('Twilight:')
    do ind_lev = 1, nLev
      call msg('Level, pressure:', ind_lev, met_dat(imet_press,ind_lev))
      do ind_react = 1, num_reactions
        call msg('Reaction, rate', ind_react, rates(ind_react, ind_lev))
      end do
    end do


  end subroutine test_lut_rates_full

  module subroutine test_lut_init(lut_file_name)
    implicit none
    character(len=*), intent(in) :: lut_file_name
    type(Tsilam_namelist), pointer :: nl_fake
    integer :: num_items
    real, parameter :: molec_to_du = 1/2.69e16 ! du = 2.69e16 molecules/cm2
    
    call init_photolysis_lut(lut_file_name)
    if (error) return
    print *, 'lut_sza_rad:', lut_sza_rad
    print *, 'lut_o3', lut_o3
    print *, 'lut_alb', lut_alb
    !print *, 'atm_o3_cuml, nm, win', atm_o3_cuml(2, 2, :)*molec_to_du
    print *, 'atm_o3_cuml, sm, win', atm_o3_cuml(2, 2, :)*molec_to_du !RISTO: after re-reordering the indeces
    
  end subroutine test_lut_init

  module subroutine test_effective_albedo_v2()
      integer, parameter :: nlevs=10
      real, parameter :: ssa=0.999, g=0.78  !!!aerosol/drop parameters

      real, dimension(nlevs) :: tau_above_bott, photoatt
      real :: alb_eff, att0

      real, parameter :: tautot=30, alb_sfc=0.1, mu0=1.0

      
      integer :: i

      do i=1,nlevs
        tau_above_bott(i)=tautot*(nlevs-i+1)*1.0/nlevs
      enddo
      call test_bind_effective_albedo_v2(ssa, g, tau_above_bott, alb_sfc, mu0, nlevs, photoatt, alb_eff, att0, 0)

      print *, "tautot=", tautot, "alb_sfc=",alb_sfc, "mu0=", mu0, "albeff=", alb_eff
      print *, "tau_above_bott(i), photoatt(i)"
      do i=1,nlevs
        print *, tau_above_bott(i), photoatt(i)
      enddo

  endsubroutine test_effective_albedo_v2

    module subroutine test_interp_weights()
      implicit none
      real :: a
      integer :: k

      call test_bind_get_interp_weights(0.5, (/1.,2.,4./), k, a)
      print *, 'Should be 1.0, 1:', a, k
      call test_bind_get_interp_weights(3.4, (/1.,2.,4./), k, a)
      print *, 'Should be 0.3, 2:', a, k
      call test_bind_get_interp_weights(4.0, (/1.,2.,4./), k, a)
      print *, 'Should be 2, 0.0:', a, k

      call test_bind_get_interp_weights_rev(4.0, (/4.,2.,1./), k, a)
      print *, 'Should be 1, 1.0:', a, k
      call test_bind_get_interp_weights_rev(3.0, (/4.,2.,1./), k, a)
      print *, 'Should be 1, 0.5:', a, k
      call test_bind_get_interp_weights_rev(.05, (/4.,2.,1./), k, a)
      print *, 'Should be 2, 0.0:', a, k

      
    end subroutine test_interp_weights

!!!!  subroutine test_lut_rates()
!!!!    implicit none
!!!!    
!!!!    real, dimension(1) :: col_press = (/1e5/) ! Pa!!
!!!!    real, dimension(1) :: col_cwc = (/1e-3/) ! kg/m3!!
!!!!    real, dimension(1) :: col_aod = (/1e-3/) ! m2/m2
!!!!    real, dimension(2, 1) :: rates
!!!!    real :: cwc_totcol = 1e-3, alb_sfc = 0.3, cld_cover = 0.5
!!!!    type(silja_time) :: now
!!!!
!!!!            
!!!!    now = fu_set_time_utc(2001, 7, 1, 0, 0, 0.0)
!!!!    call report_lut(1, 1)
!!!!    call get_photorates_column(0.0, 0.0, now, 1.0, col_press, col_cwc, cwc_totcol, col_aod,  alb_sfc, cld_cover, rates)
!!!!    print *, 'rates 1000 hPa'
!!!!    print *, rates
!!!!
!!!!    ! the second sza bin in the test lut, cos(theta) = 0.76
!!!!    call get_photorates_column(0.0, 0.0, now, 0.76, col_press, col_cwc, cwc_totcol, col_aod,  alb_sfc, cld_cover, rates)
!!!!    print *, 'rates 1000 hPa, 0.76'
!!!!    print *, rates
!!!!
!!!!    call get_photorates_column(0.0, 0.0, now, 0.9397, col_press, col_cwc, cwc_totcol, col_aod,  alb_sfc, cld_cover, rates)
!!!!    print *, 'rates 1000 hPa, 0.94'
!!!!    print *, rates
!!!!
!!!!
!!!!    col_press(1) = 0.75e5
!!!!    call get_photorates_column(0.0, 0.0, now, 1.0, col_press, col_cwc, cwc_totcol, col_aod,  alb_sfc, cld_cover, rates)
!!!!    print *, 'rates 750 hPa'
!!!!    print *, rates
!!!!
!!!!    col_press(1) = 0.75e5
!!!!    call get_photorates_column(0.0, 0.0, now, 0.76, col_press, col_cwc, cwc_totcol, col_aod,  alb_sfc, cld_cover, rates)
!!!!    print *, 'rates 750 hPa, 0.76'
!!!!    print *, rates ! 316.22775      3.16227768E+10
!!!!
!!!!    col_press(1) = 0.75e5
!!!!    call get_photorates_column(0.0, 0.0, now, 0.9397, col_press, col_cwc, cwc_totcol, col_aod,  alb_sfc, cld_cover, rates)
!!!!    print *, 'rates 750 hPa, 0.94' 
!!!!    print *, rates ! 31.606142      3.16061158E+09
!!!!
!!!!  contains
!!!!    subroutine report_lut(ind_lat, ind_season)
!!!!      implicit none
!!!!      integer, intent(in) :: ind_lat, ind_season
!!!!      integer :: ii, jj,kk
!!!!
!!!!      print *, 'Reporting lut data:'
!!!!           
!!!!      do ii = 1, size(lut_data, 1)
!!!!        print *, 'Reaction:', ii
!!!!        do jj = 1, size(lut_data, 5)
!!!!          print *, 'O3:', jj
!!!!          do kk = 1, size(lut_data, 6)
!!!!            print *, 'sza:', kk
!!!!            print *, lut_data(ii, ind_lat, ind_season, 1, jj, kk, :)
!!!!          end do
!!!!        end do
!!!!      end do
!!!!
!!!!      print *, ''
!!!!      
!!!!    end subroutine report_lut
!!!!
!!!!  end subroutine test_lut_rates

end submodule test_photolysis_impl
