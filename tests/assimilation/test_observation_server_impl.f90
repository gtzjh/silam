submodule (observation_server) test_observation_server_impl
  implicit none
contains

  module subroutine test_read_timeseries()
    implicit none
    
    integer, parameter :: num_transp_sp = 2, num_stations = 2
    type(silam_species), dimension(2) :: transp_species

    type(observationStation), dimension(2) :: station_list
    type(inSituObservation), dimension(:), pointer :: in_situ_list, dose_rate_list
    type(t_dose_rate_obs_addition), dimension(:), pointer :: addition_list
    integer, dimension(2) :: num_in_situ, num_vert_obs, num_dose_rate, num_eruption_obs
    character(len=fnlen), dimension(:), pointer :: obs_items
    character(len=fnlen) :: obs_list_path
    character(len=*), parameter :: tmpfilename = 'tmp.dat'
    type(silja_grid) :: grid
    integer :: obs_size, ind_obs, num_val, nObsItems
    logical :: failure
    real, dimension(:), pointer :: dataptr
    real, parameter :: dummy_obs_val = 1.0
    real :: conv_to_mol
    type(t_vertical_observation), pointer, dimension(:) :: null_vert_obs_lst
    type(silam_species), dimension(:), pointer :: null_species_lst
    type(t_eruptionObservation), pointer, dimension(:) :: null_eruption_obs_lst
    type(silja_time) :: obs_start
    type(silja_interval) :: obs_period
    character(len=*), parameter :: sub_name = 'test_read_timeseries'

    grid = fu_set_lonlat_grid('testgrid', 20.0, 40.0, .true., &
                            & 100, 100, pole_geographical, 1.0, 1.0)
    if (error) return
    call set_species(transp_species(1), fu_get_material_ptr('SO2'), in_gas_phase)
    call set_species(transp_species(2), fu_get_material_ptr('NO2'), in_gas_phase)
    if (error) return
    
    call set_vertical(fu_set_level(layer_btw_2_height, 0.0, 20.0), dispersion_vertical)
    if (error) return

    nObsItems = 1
    allocate(obs_items(1))
    obs_items(1) = 'cnc g ' // tmpfilename
    conv_to_mol = 1/64.0

    call make_stations(station_list, 2)
    !station_list(1) = fu_initObservationStation('A1', 'station_a1', 30.0, 55.0, 5.0, wholeMPIdispersion_grid)
    !station_list(2) = fu_initObservationStation('A2', 'station_a2', 31.0, 56.0, 5.0, wholeMPIdispersion_grid)
    if(error) return
    
    obs_start = fu_set_time_utc(2012, 6, 1, 0, 0, 0.0)
    obs_period = fu_set_interval_h(36)

    nullify(null_vert_obs_lst, null_species_lst)

    ! what if obs not foud?


    call msg('Expect failure:')
    call test_bind_read_observations(obs_start, obs_period,  obs_items, nObsItems, 0, &
                         & station_list, size(station_list), in_situ_list, num_in_situ, &
                         & null_vert_obs_lst, num_vert_obs, &
                         & null_eruption_obs_lst, num_eruption_obs, &
                         & addition_list, num_dose_rate,  &
                         & transp_species, null_species_lst, num_transp_sp, 0)
    if (fu_fails(error, 'Shouldn''t work!', 'test_read_timeseries')) continue
    call unset_error('test_read_timeseries')


    call msg('Expect success:')

    call msg('Hourly obs')
    call make_observations(tmpfilename, station_list, obs_start, obs_start+obs_period, &
                         & 'SO2', one_hour, obs_size)
    call test_bind_read_observations(obs_start, obs_period, obs_items, nObsItems, 0, &
                         & station_list, size(station_list), in_situ_list, num_in_situ, &
                         & null_vert_obs_lst, num_vert_obs, &
                         & null_eruption_obs_lst, num_eruption_obs, &
                         & addition_list, num_dose_rate, &
                         & transp_species, null_species_lst, num_transp_sp, 0)

    call msg('series read:', num_in_situ)
    if (fu_fails(sum(num_in_situ) == 2, 'Failed to read 2 obs', sub_name)) return 

    call check_observations(in_situ_list, obs_size, station_list)

    call msg('Daily obs')
    call make_observations(tmpfilename, station_list, obs_start, obs_start+obs_period, &
                         & 'SO2', one_day, obs_size)
    call test_bind_read_observations(obs_start, obs_period, obs_items, nObsItems, 0, &
                         & station_list, size(station_list), in_situ_list, num_in_situ, &
                         & null_vert_obs_lst, num_vert_obs, & 
                         & null_eruption_obs_lst, num_eruption_obs, &
                         & addition_list, num_dose_rate, &
                         & transp_species, null_species_lst, num_transp_sp, 0)
    call msg('series read:', num_in_situ)
    if (fu_fails(sum(num_in_situ) == 2, 'Failed to read 2 obs', sub_name)) return 

    call check_observations(in_situ_list, obs_size, station_list)
    
    
    !call cleanup(tmpfilename)

  contains
    
    subroutine check_observations(obs_list, obs_size, station_list)
      implicit none
      type(insituObservation), dimension(:), intent(in) :: obs_list
      type(observationStation), dimension(:), intent(in) :: station_list
      integer, intent(in) :: obs_size

      real, dimension(:), pointer :: dataptr
      real, dimension(obs_size) :: expect_values
      integer :: ii

      dataptr => fu_work_array()
      do ind_obs = 1, size(obs_list)
        expect_values = (/(ind_obs + ii - 1, ii = 1, obs_size)/)
        num_val = fu_size(obs_list(ind_obs))
        call msg('num_val, obs_size', num_val, obs_size)
        failure = fu_fails(num_val == obs_size, 'Obs are wrong size', sub_name)
        failure = fu_fails(obs_list(ind_obs)%station(1)%id == station_list(ind_obs)%id, &
             & 'wrong id', sub_name)
        call get_data_in_situ(in_situ_list(ind_obs), values_obs=dataptr)
        if (fu_fails(all(dataptr(1:obs_size) .eps. expect_values), 'Wrong values', sub_name)) then
          call msg('ind_obs:', ind_obs)
          print *, 'Expected:', expect_values(1:obs_size)
          print *, 'Obtained:', dataptr(1:obs_size)
        end if
        
      end do
      
      call free_work_array(dataptr)
      
    end subroutine check_observations

    subroutine make_stations(station_list, how_many)
      implicit none
      type(observationStation), dimension(:), intent(out) :: station_list
      integer, intent(in) :: how_many
      
      integer :: ind_station
      type(observationStation), pointer :: stationptr
      character(clen) :: code, name
      
      do ind_station = 1, how_many
        write(code, fmt='("A",I0)') ind_station
        write(name, fmt='("station_", I0)') ind_station
        station_list(ind_station) = fu_initObservationStation(trim(code), trim(name), &
                                             & 30.0 + ind_station, 55.0 + ind_station, 2.0)
      end do
      
    end subroutine make_stations

    subroutine make_observations(filename, station_list, time_start, time_end, cockt_name, duration, &
                               & num_val)
      implicit none
      character(len=*), intent(in) :: filename, cockt_name
      type(observationStation), dimension(:), intent(in) :: station_list
      type(silja_time), intent(in) :: time_start, time_end
      !real, intent(in) :: value
      type(silja_interval), intent(in) :: duration
      integer, intent(out) :: num_val

      integer :: unit
      real :: hours
      integer :: ind_station
      type(silja_time) :: now, obs_end
      real :: value

      unit = fu_next_free_unit()
      
      open(unit, action='write', form='formatted', file=filename)

      hours = fu_sec(duration) / 3600.0

      do ind_station = 1, size(station_list)
        now = time_start
        num_val = 0
        do while (now < time_end)
          value = ind_station + num_val
          obs_end = now + duration
          write(unit, fmt='(A, A, I5, I3, I3, I3, 3G12.3)') station_list(ind_station)%id, cockt_name, &
               & fu_year(obs_end), fu_mon(obs_end), fu_day(obs_end), fu_hour(obs_end), &
               & hours, value, 1.0
          now = now + duration
          ! The values that end outside assimilation window are not read, hence don't count them in:
          if (obs_end <= time_end) num_val = num_val + 1 
        end do
      end do

      close(unit)
      
    end subroutine make_observations
    
    subroutine cleanup(tmpfilename)
      implicit none
      character(len=*), intent(in) :: tmpfilename
      
      integer :: unit

      unit = fu_next_free_unit()

      open(unit=unit, file=tmpfilename)
      close(unit, status='delete')
    end subroutine cleanup

  end subroutine test_read_timeseries

end submodule test_observation_server_impl
