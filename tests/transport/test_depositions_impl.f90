submodule (depositions) test_depositions_impl
contains

  !************************************************************************************

  module subroutine test_TL_ADJ(mass_in_air, &  ! sensit mass in precipitation (sSpecies, nSrc, nz)
                       & arLowMassThreshold, &  ! for sensitivity
                       & species, &
                       & Nspecies, Nsources, n3d, &
                       & timestep_sec_abs, &
                       & rulesDeposition, &
                       & r1d)
    !
    ! Tests tangent linear and adjoint matrices by computing non-linear forward and then
    ! repeating it with the TL. The Adjoint matrix is checked by transposition
    !
    implicit none

    ! Imported parameters
    real, dimension(:,:), intent(in) :: mass_in_air ! (nSpecies, n3d)
    type (Train_in_cell), dimension(n3d), intent(in) :: r1d  ! rain info for the whole column
    type(Tdeposition_rules), intent(in) :: rulesDeposition
    real, dimension(:), intent(in) :: arLowMassThreshold
    type(silam_species), dimension(:), intent(in) :: species
    integer , intent (in) :: Nspecies, Nsources, n3d
    real, intent(in) :: timestep_sec_abs

    ! Local variables
    integer, parameter :: nTimes=10
    integer :: iLev, iTime, iAAS, iSp, iTmp, indSpecies
    real, dimension(Nspecies,1,n3d,nTimes) :: Full_mass_in_air, TL_mass_in_air, &
                          & Full_mass_in_water, TL_mass_in_water   ! (nSpecies, nSrc, n3d, nTimes)
    type(Tscav_coefs_1d) :: c1d  ! internal coefficients stored from forward model
    type(silja_rp_2d), dimension(:), pointer :: pTL_L0, pTL_dLdm, pAdj
    real, dimension(2,n3d), target :: tla_store
    real, dimension(:,:), pointer :: tla_column_ptr
    real, dimension(:), pointer :: tla_cell_ptr
    real :: fTmp
    real, dimension(Nspecies) :: mass_factor

    mass_factor(:) = 1
    tla_column_ptr => tla_store
    !
    ! Get the vectors of species and masses, then compute its forward non-linear scavenging
    ! over several time steps, then do the same with tangent linear matrix, which is made only
    ! once, of course. The first time step must show identical results, then they can deviate
    !
    !
!    ! Store mass in air - the initial conditions
!    mass_in_air_local(1:Nspecies,1,1:n3d,1) = mass_in_air(1:Nspecies,1:n3d)
!    mass_in_water(1:Nspecies,1,1:n3d, 1:nTimes) = 0.0
!    ! Store the coefficients, if someone needs them
!    call msg('getting coefficients')
!    c1d%c(iLev) = coefs_zero
!    do iLev = n3d, 1, -1
!      call scavenge_puff_2011(mass_in_air_local(1:Nspecies,:,iLev,iTime), &    ! stuff in the air, need (nSpecies,nSrc=1)
!                            & mass_in_water(1:Nspecies,:,iLev,iTime), & ! stuff in precipitation, need (nSpecies, nSrc=1)
!                           & arLowMassThreshold, &  ! what to do if forward model did not have mass ???
!                           & species, &
!                            & Nspecies, &
!                            & Nsources, &
!                            & timestep_sec_abs, &  ! positive
!                            & rulesDeposition, &
!                            & r1d(iLev), r1d(iLev)%cell_volume, r1d(iLev)%cell_zsize, &
!                            & c1d%c(iLev))     ! internal coefficients
!    end do
!    ! (re)store intial masses

    !
    ! Make the matrices - the only thing needed now from the adjoint sub
    !
    call msg('Getting TL matrix')
    call get_work_arrays_set(nSpecies, pTL_L0)
    call msg('done pTL_L0')
    call get_work_arrays_set(nSpecies, pTL_dLdm)
    call msg('done pTL_dLdm')
    call get_work_arrays_set(nSpecies, pAdj)
    call msg('done pAdj')
    if(error)then
      call set_error('Failed some of work array sets','test_TL_ADJ')
      return
    endif
    
    !!! Just to fill TLA storage
    Full_mass_in_air(1:Nspecies,1,1:n3d,1) = mass_in_air
    Full_mass_in_water(1:Nspecies,1,1:n3d,1) = 0
    do iLev = n3d, 1, -1
      if (r1d(iLev)%ifRainyCell)then  ! there is rain at this level
!         call msg('Repository scavenging')
!        call scavenge_puff_2011_repo(mass_in_air_local(1:Nspecies,:,iLev,iTime), &    ! stuff in the air, need (nSpecies,nSrc=1)
        call msg('Adjusted scavenging')
        tla_cell_ptr => tla_column_ptr(:,iLev)
        call test_bind_scavenge_puff_2011(Full_mass_in_air(1:Nspecies,:,iLev,1), &    ! stuff in the air, need (nSpecies,nSrc=1)
                              & Full_mass_in_water(1:Nspecies,:,iLev,1), & ! stuff in precipitation, need (nSpecies, nSrc=1)
                              & arLowMassThreshold, &  ! what to do if forward model did not have mass ???
                              & tla_cell_ptr, &
                              & species, &
                              & Nspecies, &
                              & Nsources, &
                              & timestep_sec_abs, &  ! positive
                              & rulesDeposition, &
                              & r1d(iLev), r1d(iLev)%cell_volume, r1d(iLev)%cell_zsize)
      endif  ! if there is rain in the cell
      ! Cumulate the scavenged amount
      if(iLev> 1) Full_mass_in_water(1:Nspecies,:,iLev-1,iTime) = &
                                       & Full_mass_in_water(1:Nspecies,:,iLev,iTime)
    end do  ! iLev, inverse order


    !!!!! TLA filled 



    call test_bind_scavenge_column_2011_adjoint(TL_mass_in_air(1:Nspecies,:,1:n3d,1), &    ! mass in the air   (nSpecies, nSrc, n3d)
                                    & TL_mass_in_water(1:Nspecies,:,1:n3d,1), &  !  mass in precipitation (sSpecies, nSrc, nz)
                                    & tla_column_ptr, &
                                    & arLowMassThreshold, &  ! for sensitivity
                                    & species, &
                                    & Nspecies, Nsources, n3d, &
                                    & timestep_sec_abs, &
                                    & rulesDeposition, &
                                    & r1d, pTL_L0, pTL_dLdm, pAdj)
    ! set working masses
    !
!    mass_factor(indHNO3) = 100000
!    mass_factor(indSO2) = 100000
    do iSp = 1, nSpecies
      if(mass_factor(iSp) /= 1) &
         & call msg('===========>>>>>>>>> Species:' + fu_str(species(iSp)) + ', multiplied with', &
                  & mass_factor(iSp))
      Full_mass_in_air(iSp,1,1:n3d,1) = mass_in_air(iSp,1:n3d) * mass_factor(iSp)
      Full_mass_in_air(iSp,1,1:n3d,2) = mass_in_air(iSp,1:n3d) * mass_factor(iSp)
      TL_mass_in_air(iSp,1,1:n3d,1) = mass_in_air(iSp,1:n3d) * mass_factor(iSp)
      TL_mass_in_air(iSp,1,1:n3d,2) = mass_in_air(iSp,1:n3d) * mass_factor(iSp)
    end do
    Full_mass_in_water(1:Nspecies,1,1:n3d, 1:nTimes) = 0.0
    TL_mass_in_water(1:Nspecies,1,1:n3d, 1:nTimes) = 0.0

    !
    ! run full forward model
    !
    do iTime = 2, nTimes-1
      do iLev = n3d, 1, -1
        if (r1d(iLev)%ifRainyCell)then  ! there is rain at this level
!           call msg('Repository scavenging')
!          call scavenge_puff_2011_repo(mass_in_air_local(1:Nspecies,:,iLev,iTime), &    ! stuff in the air, need (nSpecies,nSrc=1)
          call msg('Adjusted scavenging')
          call test_bind_scavenge_puff_2011(Full_mass_in_air(1:Nspecies,:,iLev,iTime), &    ! stuff in the air, need (nSpecies,nSrc=1)
                                & Full_mass_in_water(1:Nspecies,:,iLev,iTime), & ! stuff in precipitation, need (nSpecies, nSrc=1)
                                & arLowMassThreshold, &  ! what to do if forward model did not have mass ???
                                & null(), &
                                & species, &
                                & Nspecies, &
                                & Nsources, &
                                & timestep_sec_abs, &  ! positive
                                & rulesDeposition, &
                                & r1d(iLev), r1d(iLev)%cell_volume, r1d(iLev)%cell_zsize)
        endif  ! if there is rain in the cell
        ! Cumulate the scavenged amount
        if(iLev> 1) Full_mass_in_water(1:Nspecies,:,iLev-1,iTime) = &
                                         & Full_mass_in_water(1:Nspecies,:,iLev,iTime)
      end do  ! iLev, inverse order
      !
      ! Copy the current value to next time step
      !
      Full_mass_in_air(1:Nspecies,:,1:n3d,iTime+1) = Full_mass_in_air(1:Nspecies,:,1:n3d,iTime)
!      Full_mass_in_water(1:Nspecies,:,1:n3d,iTime+1) = Full_mass_in_water(1:Nspecies,:,1:n3d,iTime)
    end do ! iTime
    !
    ! Have nTimes-step evolution of the masses in air and in water as non-linear model computed
    ! Do nTimes steps with TL matrix
    !
    do iTime = 2, nTimes-1
      do iSp = 1, nSpecies
        do iLev = n3d, 1, -1
          fTmp = 0.0
          if(iSp == indSO2)then
            ! SO2 depends on several species
            do iAAS = 1, nAcidityAffectingSpecies
!              call msg('SO2 Diagonal only')
!              fTmp = fTmp + pTL(iSp)%pp(iLev, iLev+(iAAS-1)*n3d) * &
!                          & TL_mass_in_air(abs(indAcidityAffectingSp(iAAS)), 1, iLev, iTime)
              call msg('SO2 Triangle full')
              do iTmp = 1, n3d
                fTmp = fTmp + pTL_L0(iSp)%pp(iLev, iTmp+(iAAS-1)*n3d) * &
                            & TL_mass_in_air(abs(indAcidityAffectingSp(iAAS)), 1, iTmp, iTime)
              end do  ! iTmp 1:n3d
            end do
          else
            ! non-SO2, squared TL matrix
!            call msg('All Diagonal only')
!            fTmp = fTmp + pTL(iSp)%pp(iLev,iLev) * TL_mass_in_air(iSp,1,iLev,iTime)
            call msg('All Triangle full 2')
            do iTmp = 1, n3d
              fTmp = fTmp + pTL_L0(iSp)%pp(iLev,iTmp) * TL_mass_in_air(iSp,1,iTmp,iTime)
            end do  ! iTmp 1:n3d
          endif  ! iSp == indSO2
          ! Make the scavenging...
          TL_mass_in_air(iSp, 1, iLev, iTime) = TL_mass_in_air(iSp, 1, iLev, iTime) + fTmp
          TL_mass_in_water(iSp, 1, iLev, iTime) = TL_mass_in_water(iSp, 1, iLev, iTime) - fTmp
          ! Cumulate scavengned amount downwards
          if(iLev> 1)then
            TL_mass_in_water(iSp,1,iLev-1,iTime) = TL_mass_in_water(iSp,1,iLev,iTime)
          endif
        end do  ! iLev
      end do  ! iSp
      !
      ! Copy the current value to next time step
      !
      TL_mass_in_air(1:Nspecies,:,1:n3d,iTime+1) = TL_mass_in_air(1:Nspecies,:,1:n3d,iTime)
!      TL_mass_in_water(1:Nspecies,:,1:n3d,iTime+1) = TL_mass_in_water(1:Nspecies,:,1:n3d,iTime)
    end do  ! iTime
    !
    ! Now, just write the results down to the log file
    !
    call msg('')
    call msg('>>>>>>>>>>>>>>>>>>>>>>>>>> TEST TL SCAVENGING <<<<<<<<<<<<<<<<<<<<<<<<<<')
    call msg('')

    call msg('Rain parameters for iMeteo=', r1d(1)%iMeteo)
    call msg('iLev fCloudCover  fPressure  fTemperature  fRainRateSfc  cwcColumn    mu_air     rho_air     nu_air     lambda_air   rain_rate_in   deltarain   cwcColumnLayer   is_liquid    drop_size    drop_mass    drop_vel   drop_Re   cell_zsize  cell_volume')
    do iLev = 1, n3d
      call msg(fu_str(iLev),(/r1d(iLev)%fCloudCover, r1d(iLev)%fPressure, r1d(iLev)%fTemperature, &
                            & r1d(iLev)%fRainRateSfc, r1d(iLev)%cwcColumn, &
                            & r1d(iLev)%mu_air, r1d(iLev)%rho_air, r1d(iLev)%nu_air, r1d(iLev)%lambda_air, &
                            & r1d(iLev)%rain_rate_in, r1d(iLev)%deltarain, r1d(iLev)%cwcColumnLayer, &
                            & r1d(iLev)%is_liquid, r1d(iLev)%drop_size, r1d(iLev)%drop_mass, &
                            & r1d(iLev)%drop_vel, r1d(iLev)%drop_Re, &
                            & r1d(iLev)%cell_zsize, r1d(iLev)%cell_volume/))
    end do

    do iSp = 1, nSpecies
      if(sum(Full_mass_in_air(iSp,1,1:n3d,1)) < 1e-10)then
        call msg(fu_str(species(iSp)) + ', ZERO MASS')
        cycle
      else
        call msg(fu_str(species(iSp)))
      endif
      call msg('TL matrix:' + fu_str(species(iSp)) + ', L0')
      do iLev = 1, n3d
        if(iSp == indSO2)then
          call msg(fu_str(iLev) + ':', (/pTL_L0(iSp)%pp(iLev,1:n3d*nAcidityAffectingSpecies)/))
        else
          call msg(fu_str(iLev) + ':', (/pTL_L0(iSp)%pp(iLev,1:n3d)/))
        endif
      end do
      call msg('Full scheme, mass in air:' + fu_str(species(iSp)))
      call msg('time', (/(iTime,iTime=1,nTimes)/))
      do iLev = 1, n3d
        call msg(fu_str(iLev) + ',full', (/(Full_mass_in_air(iSp,1,iLev,iTime),iTime=1,nTimes)/))
      end do
      call msg('TL scheme, mass in air:' + fu_str(species(iSp)))
      call msg('time', (/(iTime,iTime=1,nTimes)/))
      do iLev = 1, n3d
        call msg(fu_str(iLev) + ',TL', (/(TL_mass_in_air(iSp,1,iLev,iTime),iTime=1,nTimes)/))
      end do
      call msg('(TL - full) / (TL + full), mass in air:' + fu_str(species(iSp)))
      call msg('time', (/(iTime,iTime=1,nTimes)/))
      do iLev = 1, n3d
        call msg(fu_str(iLev) + ',(-)/(+)', (/((TL_mass_in_air(iSp,1,iLev,iTime) - &
                                           & Full_mass_in_air(iSp,1,iLev,iTime)) / &
                                      & (TL_mass_in_air(iSp,1,iLev,iTime) + &
                                           & Full_mass_in_air(iSp,1,iLev,iTime) + 1e-20),iTime=1,nTimes)/))
      end do
      call msg('Full scheme, mass in water:' + fu_str(species(iSp)))
      call msg('time', (/(iTime,iTime=1,nTimes)/))
      do iLev = 1, n3d
        call msg(fu_str(iLev) + ',full', (/(Full_mass_in_water(iSp,1,iLev,iTime),iTime=1,nTimes)/))
      end do
      call msg('TL scheme, mass in water:' + fu_str(species(iSp)))
      call msg('time', (/(iTime,iTime=1,nTimes)/))
      do iLev = 1, n3d
        call msg(fu_str(iLev) + ',TL', (/(TL_mass_in_water(iSp,1,iLev,iTime),iTime=1,nTimes)/))
      end do
      call msg('(TL - full) / (TL + full), mass in water:' + fu_str(species(iSp)))
      call msg('time', (/(iTime,iTime=1,nTimes)/))
      do iLev = 1, n3d
        call msg(fu_str(iLev) + '(-)/(+)', (/((TL_mass_in_water(iSp,1,iLev,iTime) - &
                                           & Full_mass_in_water(iSp,1,iLev,iTime)) / &
                                      & (TL_mass_in_water(iSp,1,iLev,iTime) + &
                                           & Full_mass_in_water(iSp,1,iLev,iTime) + 1e-20),iTime=1,nTimes)/))
      end do
    end do
    call msg('')
    call msg('>>>>>>>>>>>>>>>>>>>>>>>>>> END TEST TL SCAVENGING <<<<<<<<<<<<<<<<<<<<<<<<<<')
    call msg('')

    call free_work_array(pTL_L0)
    call free_work_array(pTL_dLdm)
    call free_work_array(pAdj)


  end subroutine test_TL_ADJ

  !**********************************************************************************

  module subroutine vd_CAMAERA(u_star, fz0, lai, ascale, invL)
    !  CAMAERRA 2024 protocol
    !
    implicit none

    ! Imported parameters
    real, intent(in) :: u_star, fz0, lai, ascale, invL

    ! Local variables
    real :: fLambda, fCun, fWetDiam, fSc, fRoughfr, fStickRatio, fKin_visc, fDyn_visc, fDiffusivity, &
          & fSetlVelocity, fTau, fHumidity,  mol_diff,  fTemperature, &
          & fVTFplus, fSensHeatVelplus, vsplusCorrTF, Cp_ro, fTmp, R2m, V, fIvd,  t2, airden, ps,  rho_p, Vd, Rs, Zref
    real, parameter :: fPrm = 0.7  ! Molecular prandtl number
    real, parameter :: fkgkp = 0.02  ! Ratio of heat conductivities
                                         ! for gas and particle
    integer :: isize

    real :: tauplus, vsplus, rplus, Rsplus, invLplus, zplus,  Re,  St, dpa, fKn  !  dimensionless
    real :: vdsmooth, vdrough       ! vd for two landuse types. Should be more
    
    ! Parameters from fu_vdplus_rough
    real :: Re12, Vdif, Vint, Vimp, Impar, Ra
    real, parameter :: Stcr=0.15 ! critical stokes number
    real, parameter :: Utus=3.0 ! U_{top}/u_*


    vdsmooth = 0.
    vdrough = 0.
    ! Meteo

    t2 = 288.
    ps = 101325.
    rho_p = 2000.
    Rs = 0.
    Zref = 20.

    fStickRatio = 1.

    if (ascale > 0) then
      fRoughfr = 1.
    else
      fRoughfr = 0.
    endif

    airden = ps / (gas_constant_dryair * t2)
    fDyn_visc = fu_dynamic_viscosity(t2)
    fKin_visc = fDyn_visc / airden

    Cp_ro = specific_heat_dryair * airden
    fSensHeatVelplus = 0.

    if (fZ0 < 3. * fKin_visc/u_star) then !FIXME: May be some other coefficient needed here
      fRoughfr = 0.
    endif


    do isize = 0,999
      fWetDiam = 1e-8 * 10**(3.*isize/999.)

      fLambda = 2.37e-5 * t2 / ps
      fKn = 2*fLambda / fWetDiam
      fCun = 1. + fKn * (1.257 + 0.4 * exp(-1.1*fKn))

      fDiffusivity = boltzmann_const * t2 * fCun / &
                   & (3. * Pi * fDyn_visc * fWetDiam)
      fTau =  fWetDiam * fWetDiam * rho_p * &
                       & fCun / (18. * fDyn_visc)
      fVTFplus = - fSensHeatVelplus * fPrm  & !Thermophoretic velocity
          &        * 2*fCun *1.17 *(fkgkp+2.18*fKn) & ! (Friedlander 2000)
          &        / (1+3*1.14*fKn)/(1.+2.*fkgkp +2.*2.18*fKn)
      fSc = fKin_visc / fDiffusivity
      tauplus = fTau * u_star * u_star / fKin_visc
      vsplus = fTau * g / u_star
      rplus  = 0.5 * fWetDiam * u_star / fKin_visc
      Rsplus = 0. ! No surface resistance for particles

        vsplusCorrTF=0. ! correction of VsPlus for thermophoresis
        if (fRoughfr < 1.) then ! smooth fraction exist
          fTmp = fKin_visc/u_star ! z0smooth
          vdsmooth = (1. - fRoughfr) * u_star * fu_vdplus_smooth(tauplus, fSc, vsplus + vsplusCorrTF, &
                                                               & rplus, Rsplus, invL*fTmp , zref/fTmp)
          if (.not. (vdsmooth .ge. 0.)) then
            if (zref < fTmp) then
              ! Could be just too-low center of masses
              vdsmooth =  (1. - fRoughfr) * u_star ! whatever
            else
              call msg ("**DEPO** -fu_get_vd-------------------------")
              call msg ("**DEPO** Negative vdsmooth!, WetDp=",fWetDiam)
              call msg ("**DEPO** Negative vdsmooth!, tauplus=",tauplus)
              call msg ("**DEPO** Negative vdsmooth!, fsc=",fsc)
              call msg ("**DEPO** Negative vdsmooth!, vsplus=",vsplus+vsplusCorrTF)
              call msg ("**DEPO** Negative vdsmooth!, rplus=",rplus)
              call msg ("**DEPO** Negative vdsmooth!, Rsplus=",Rsplus)
              call msg ("**DEPO** Negative vdsmooth!, Rs=",Rs)
              call msg ("**DEPO** Negative vdsmooth!, vdsmooth=",vdsmooth)
              call msg ("**DEPO** Negative vdsmooth!, zref=",zref)
              call msg ("**DEPO** Negative vdsmooth!, z0smooth=",fTmp)
              call msg ("**DEPO** Negative vdsmooth!, invL=",invL)
              vdsmooth = 0. ! Should not happen, but happens.
                            ! sometimes returns NAN due to over-/under- flow
            endif
          endif
       endif
        vsplusCorrTF = 0.5*(vsplusCorrTF+abs(vsplusCorrTF)) ! Can not be negative for rough surfaces.
                                                            ! Could be treated in some better way
        if (fRoughfr > 0.) then ! rough fraction exist
           Re =  ascale * u_star / fKin_visc
           St = 2*tauplus/Re * fStickRatio ! No impaction for non-sticky
                                          ! surfaces
           dpa = 2.*rplus/Re
           vdrough = fRoughfr * u_star * &
                test_bind_fu_vdplus_rough(St, fSc, vsplus + vsplusCorrTF, dpa, Rsplus, Re, invL*fZ0 , max(zref/fZ0, 1.))
            if (.not. (vdrough .ge. 0.)) then
                  call msg("**DEPO** Bad vdrough in fu_get_vd! vdrough,fz0:", vdrough, fZ0)
                  call msg('fRoughfr, u_star:',fRoughfr, u_star)
                  call msg('St, fSc',St, fSc)
                  call msg('vsplus, vsplusCorrTF',vsplus, vsplusCorrTF)
                  call msg('dpa, Rsplus',dpa, Rsplus)
                  call msg('Re, invL',Re, invL)
                  call msg('fZ0 , zref',fZ0 , zref)
                  vdrough = 0. ! FIXME Should never happen
            endif
            
            Re12 = sqrt(Re)

            Vdif = 1. / (Rsplus + 0.5*Re12 * fSc**.6666667)
            Vint = 80. * dpa * dpa *Re12
            Vimp = 0;
            Impar = St - 1./(Utus * Re12) - Stcr ! Impaction parameter
            if (Impar .gt. 0) then
                    Vimp = 2./Utus * exp(-0.1/Impar- 1./sqrt(Impar))
            endif



            Ra  = 2.5 * (log(zref/fZ0) + test_bind_fu_psi(fZ0*invL)) ! no stability correction
                                                          ! for lower limit
            Ra = 0.5*(Ra+abs(Ra))                   ! Could become negative in
                                                !unstable
        else 
            Vdif = real_missing
            Vint = real_missing
            Vimp = real_missing
            St = real_missing
            Ra = real_missing


        endif
        Vd = vdsmooth + vdrough

        if (isize == 0) then
          print *,"# u* = ", u_star, "m/s, fz0 =",   fz0 , "m, LAI =", lai, ", coll scale   = ",  ascale, 'm'
          print *,"#KinVis = ", fKin_visc, " m2/s,  DynVis = ", fDyn_visc, " Pa/m, mfpa = ", fLambda," m, Ra =", Ra, "1/L =", invL, "1/m"
          
          print *, "Dp,DepVel,SedVel,Rs,BrownE,ImpE,IntE,BrownD,St,Sc,Kn"
        endif

        print *, fWetDiam,',',Vd,',', fTau * g,',',Rs,',', Vdif,',', Vimp,',', Vint,',', fDiffusivity ,',', St,',', fSc,',', fKn

      enddo !! isize

  end subroutine vd_CAMAERA


   !*******************************************************
  
  module subroutine PrintCamaera()
      implicit none
      character(len = *), parameter :: sub_name = 'PrintCamaera'
    ! code
      integer :: iStab, iLu

      real, dimension(4) ::  invMo

      invMo = (/0., 0.01, 0.03,  0.1/)

      do iLu = 1,4
        do iStab = 1,size(invMo)
          select case(iLu)
            case (1)
                print *, "#CAMAERA evergreen needleleaf forest "
                call vd_CAMAERA(0.4, 0.8, 5., 4e-3, invMo(iStab))
            case (2)
                print *, "#CAMAERA deciduous broadleaf forest "
                call vd_CAMAERA(0.4, 1.05, 5., 10e-3, invMo(iStab))
            case (3)
                print *, "#CAMAERA grass "
                call vd_CAMAERA(0.3, 0.1, 2., 4e-3, invMo(iStab))
            case (4)
                print *, "#CAMAERA water "
                call vd_CAMAERA(0.2, 0.001, 0., -1., invMo(iStab))
          end select
        enddo
      enddo
  end subroutine PrintCamaera

end submodule test_depositions_impl
