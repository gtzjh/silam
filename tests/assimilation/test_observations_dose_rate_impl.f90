submodule (observations_dose_rate) test_observations_dose_rate_impl
  implicit none
contains

  module subroutine test_dose_rate(vert, timestep, obs_len, &
                              & obs, observed_data, injected_data, &
                              & spc, map_c, wetdep, drydep, map_px, map_py, map_pz)
    implicit none
    type(silam_vertical), intent(in) :: vert
    type(silja_interval), intent(in) :: timestep
    integer, intent(in) :: obs_len
    type(inSituObservation), intent(out) :: obs
    
    type(tmass_map), pointer :: map_c, wetdep, drydep, map_px, map_py, map_pz
    type(silam_species), dimension(:), intent(in) :: spc
    integer :: ii
    type(silja_interval) :: shift
    real, dimension(obs_len) :: obs_data, variance
    type(silja_time), dimension(obs_len) :: obs_times_start
    type(silja_interval), dimension(obs_len) :: obs_durations
    type(observationStation) :: station
    type(t_dose_rate_obs_addition) :: addition
    type(silja_time) :: now = time_missing, time_end=time_missing, time_start=time_missing
    real :: x, y, injected_data, observed_data
    integer :: ispecies_obs, ispecies_transp
    !To test dose rate as I did without having actual observations but by calling
    ! the observe and inject + necessary initializations do the following:
    ! -> Set call the injectAll at dispersion_supplementary module inside and in the 
    !    beginning of the loop over time:
    !       call injectAll(obs_ptrs, cloud, meteo_ptr, &
    !                    & simRules%chemicalRules, simRules%dynamicsRules, &
    !                    & simrules%periodToCompute, now)
    !    ps. the injectAll wont be reached otherwise without correct 4dvar ini-file
    ! -> Include calling this subroutine test_dose_rate inside the injectAll. 
    !    First set some values and point to maps and then call the routine:
    !       type(inSituObservation) :: obs
    !       real :: observed_data, injected_data
    !       type(Tmass_map), pointer :: map_px, map_py, map_pz
    !    Then:
    !       map_px => fu_advection_moment_X_MM_ptr(cloud)
    !       map_py => fu_advection_moment_Y_MM_ptr(cloud)
    !       map_pz => fu_advection_moment_Z_MM_ptr(cloud)
    !       call test_dose_rate(dispersion_vertical, &
    !                         & timestep, 1, &
    !                         & obs, &
    !                         & observed_data, injected_data, &
    !                         & fu_species_transport(cloud), mapConc, mapWetdep, mapDrydep, map_px, map_py, map_pz)
    !       print*,'the obs data:',observed_data
    !       print*,'the inj data:',injected_data
    !    Printing just to get the observed and injected dose rates 
    !    to compare what the injection did to the value.
    ! -> Also set ind_src to one in inject as it isnt set if the run isnt adjoint:
    !       ind_src = 1.0
    
    time_start = fu_set_time_utc(2015, 7, 22, 06, 00, 0.0)
    shift = fu_set_interval_min(20)
    
    time_end = time_start + shift + one_hour*obs_len + shift
    do ii = 1,obs_len
       obs_times_start(ii) = time_start + shift + (one_hour*ii)
    end do
    obs_durations = one_hour
    obs_data = 1.0   !are actually 
    variance = 100.0 !observed
    call project_point_to_grid(0.0, 0.0, wholeMPIdispersion_grid,x,y)
    station = fu_initObservationStation('S1', 'S1', 0.0, 0.0, 1000.0)
    obs = fu_init_dose_rate_obs(obs_times_start, obs_durations, obs_data, variance, &
                              & obs_len, constant_variance, spc, &
                              & 'mole', station, level_missing, vert, 'test')
    addition = fu_init_dose_rate_addition(.true., obs, vert, spc)
    
    now = time_start
    do while (now <= time_end) 
      call observe_dose_rate(addition, obs, map_c, wetdep, drydep, now, timestep)
      if (error) return
      now = now + timestep
    end do
    obs%obsData(:,1) = obs%modelData(1,1)*0.9
    observed_data = obs%modelData(1,1)

    do while (now >= time_start)
      call inject_dose_rate(addition, obs, map_c, map_px, map_py, map_pz, wetdep, drydep, now, fu_opposite(timestep))
      if (error) return
      now = now - timestep
    end do
    do while (now <= time_end) 
      call observe_dose_rate(addition, obs, map_c, wetdep, drydep, now, timestep)
      if (error) return
      now = now + timestep
    end do

    injected_data = obs%modelData(1,1)
  end subroutine test_dose_rate

end submodule test_observations_dose_rate_impl
