submodule (observations_in_situ) test_observations_in_situ_impl
  implicit none
contains

  module subroutine test_in_situ(grid, vert, species, species_transp, time_start, shift, timestep, obs_len, obs)
    implicit none
    type(inSituObservation), intent(out) :: obs
    type(silja_time), intent(in) :: time_start!, time_end
    type(silja_interval), intent(in) :: timestep, shift
    type(silja_grid), intent(in) :: grid
    type(silam_vertical), intent(in) :: vert
    type(silam_species), intent(in), target :: species ! observed
    type(silam_species), dimension(:), intent(in) :: species_transp
    integer, intent(in) :: obs_len

    !integer, parameter :: obs_len = 18

    integer :: ii, file_unit
    real, dimension(obs_len) :: obs_data, variance
    type(silja_time), dimension(obs_len) :: obs_times_start
    type(silja_interval), dimension(obs_len) :: obs_durations
    !type(silam_species) :: species
    type(observationStation) :: station
    type(silja_time) :: now, time_end
    type(tmass_map), pointer :: map_c, map_px, map_py, map_pz
    integer :: nx, ny
    real :: lon, lat
    integer, dimension(max_species) :: ind_obs2transp
    real, dimension(max_species) :: scale_transp2obs
    type(silam_material), pointer :: material
    type(TField_buffer), pointer :: disp_buf_ptr


    time_end = time_start + shift + one_hour*obs_len + shift

    ind_obs2transp(1) = fu_index(species,species_transp)
    material => fu_material(species)
    scale_transp2obs(1) = fu_conversion_factor(fu_basic_mass_unit(material), 'mole', material)

    !time_start = fu_set_time_utc(2011, 1, 1, 0, 0, 0.)
    !time_end = fu_set_time_utc(2011, 1, 2, 0, 0, 0.)
    !timestep = fu_set_interval_min(15)
    !shift = fu_set_interval_min(20)

    !grid = fu_set_grid('test_grid', lonlat, pole_geographical, 5.0, 35.0, 10, 10, 1.0, 1.0)
    !call set_vertical(level, vert)

    obs_times_start = (/(time_start + shift + one_hour*ii, ii=1, obs_len)/)
    obs_durations = one_hour
    obs_data = 1.0
    variance = 100.0

    !call set_species(species, fu_get_material_ptr('NO2'), in_gas_phase)

    call grid_dimensions(grid, nx, ny)
    lon = fu_lon_native_from_grid(real(nx/2), real(ny/2), grid)
    lat = fu_lat_native_from_grid(real(nx/2), real(ny/2), grid)
    station = fu_initObservationStation('S1', 'S1', lon, lat, 10.0)
    obs = fu_initInSituObservation1(obs_times_start, obs_durations, obs_data, variance, &
      & obs_len, constant_variance, .false., & !!ifmmr = .false.
                                 & ind_obs2transp,scale_transp2obs, 1, station, vert, 'test')
    if (error) return
    obs%obsData(1,:) = obs_data
    call set_mass_map(map_c,  concentration_flag, 3, 0, grid, vert, (/species/), val=2.0)
    call set_mass_map(map_px, advection_moment_x_flag, 3, 0, grid, vert, (/species/), val=0.0)
    call set_mass_map(map_py, advection_moment_y_flag, 3, 0, grid, vert, (/species/), val=0.0)
    call set_mass_map(map_pz, advection_moment_z_flag, 3, 0, grid, vert, (/species/), val=0.0)
    if (error) return
    now = time_start
    do while (now <= time_end)
      disp_buf_ptr => null()
      call observe_in_situ(obs, map_c, map_px, map_py, disp_buf_ptr, &
               & cloud_metric_geometry_flag, int_missing, now, timestep)
      if (error) return
      now = now + timestep
    end do

    file_unit = fu_next_free_unit()
    open(file_unit, file='test.observations.1')
    call obs_to_file_in_situ(obs, (/species/), file_unit)

    map_c%arm = 0.0
    do while (now >= time_start)
      print *, 'Sum of mass map:', sum(map_c%arm) / observation_scaling
      call inject_in_situ(obs, map_c, map_px, map_py, map_pz, now, fu_opposite(timestep), 0, 1)
      if (error) return
      now = now - timestep
    end do

  end subroutine test_in_situ

end submodule test_observations_in_situ_impl
