submodule (da_interface) test_da_interface_impl
  implicit none
contains

  module subroutine adj_test_obs(model)
    implicit none
    type(model_container) :: model
    type(Tmass_map), pointer :: map_c
    integer :: nx, ny, nz, nsp
    real, dimension(:,:,:,:), allocatable :: arr1, arr2, m_arr

    integer :: n_obs_val
    integer, dimension(2) :: n_obsav
    real, dimension(:), pointer :: mdl_data, obs_data, obs_var
    type(silja_time) :: now, in_past, in_future
    type(silja_interval) :: timestep, long_interval
    type(Tmass_map), pointer :: MMptr

    now = model%rules%startTime
    timestep = model%rules%timestep
    model%rules%periodToCompute = timestep
    model%rules%darules%assim_window = timestep
    !model%rules%darules%da_end = model%rules%startTime + (timestep)
    model%obs_ptr%hasObservations = .false.

    call msg('Will run model for one timestep')
    call model_forward(model, model%rules)
    call msg('')
    call msg('done')
    call msg('')

    call msg('Now testing adjoint...')

    mdl_data => fu_work_array()
    obs_data => fu_work_array()
    obs_var => fu_work_array()

    map_c => fu_concMM_ptr(model%cloud)
    nx = map_c%nx
    ny = map_c%ny
    nz = map_c%n3d
    nsp = map_c%nspecies

    call reset_map_to_val(map_c, 0.0)
    MMptr => fu_advection_moment_X_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    MMptr => fu_advection_moment_Y_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    MMptr => fu_advection_moment_Z_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)

    allocate(arr1(nsp,nz,nx,ny), arr2(nsp,nz,nx,ny), m_arr(nsp,nz,nx,ny))
    in_past = fu_set_time_utc(2000, 1, 1, 0, 0, 0.0)
    in_future = fu_set_time_utc(2020, 1, 1, 0, 0, 0.0)
    long_interval = in_future - in_past

    call random_number(arr1)
    call random_number(arr2)
    arr1 = (arr1+10)!*1000
    arr2 = (arr2+10)!*1000
    call reset_all(model%obs_ptr, .true.)
    map_c%arm = 0.0
    map_c%arm(1:nsp,1,1:nz,1:nx,1:ny) = arr1
    !call by_volume(map_c, 'mult')
    
    ! include timing
    !call observeAll(model%obs_ptr, model%cloud, model%meteo_ptr, model%disp_buf_ptr, model%rules%chemicalRules, &
    !              & model%rules%timestep, model%rules%startTime)
    
    ! ignore timing
    call observeAll(model%obs_ptr, model%cloud, model%meteo_ptr, model%disp_buf_ptr, model%rules%chemicalRules, &
                  & model%rules%dynamicsRules, &
                  & long_interval, in_past)
    call collect_model_data(model%obs_ptr)
    call get_obs_pointers(model%obs_ptr, obs_data, mdl_data, obs_var,n_obsav)
    n_obs_val = sum(n_obsav)

!    call reset_map_to_val(fu_concMM_ptr(model%cloud), 0.0)
    MMptr => fu_concMM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    !call reset_all(model%obs_ptr)
    !call injectAll(model%obs_ptr, model%cloud, model%meteo_ptr, model%disp_buf_ptr, &
    !             & model%rules%chemicalRules, model%rules%dynamicsRules, &
    !             & fu_opposite(model%rules%timestep), model%rules%startTime)

    ! ignore timing
    call injectAll(model%obs_ptr, model%cloud, model%meteo_ptr, model%disp_buf_ptr, &
                 & model%rules%chemicalRules, model%rules%dynamicsrules, &
                 & fu_opposite(long_interval), in_future)

    call by_volume(map_c, 'div')
    m_arr = map_c%arm(1:nsp,1,1:nz,1:nx,1:ny) / observation_scaling
    

    call msg('Mean model', sum(mdl_data(1:n_obs_val)/n_obs_val))
    call msg('Mean obs', sum(obs_data(1:n_obs_val)/n_obs_val))
    
    call msg('LEFT', sum(arr1*m_arr))
    call msg('RIGHT', sum(mdl_data(1:n_obs_val) &
                        & * ((mdl_data(1:n_obs_val)-obs_data(1:n_obs_val)) / obs_var(1:n_obs_val))))
    stop

  contains

    subroutine by_volume(mass_map, what)
      implicit none
      type(Tmass_map), intent(inout) :: mass_map
      character(len=*), intent(in) :: what

      integer :: ilev, ix, iy, nlevs
      real :: volume
      real, dimension(:), pointer :: thickness
      
      
      nlevs = mass_map%n3d
      
      thickness => fu_work_array()
      thickness(1:nlevs) = (/(fu_layer_thickness_m(fu_level(mass_map%vertTemplate, ilev)), ilev=1, nlevs)/)
      
      if (what == 'div') then
        do iy = 1, mass_map%ny
          do ix = 1, mass_map%nx
            do ilev = 1, mass_map%n3d
              volume = thickness(ilev) * fu_cell_size(mass_map%gridTemplate, ix, iy)
              mass_map%arm(:,:,ilev,ix,iy) = mass_map%arm(:,:,ilev,ix,iy) / volume 
            end do
          end do
        end do
      else
        do iy = 1, mass_map%ny
          do ix = 1, mass_map%nx
            do ilev = 1, mass_map%n3d
              volume = thickness(ilev) * fu_cell_size(mass_map%gridTemplate, ix, iy)
              mass_map%arm(:,:,ilev,ix,iy) = mass_map%arm(:,:,ilev,ix,iy) * volume 
            end do
          end do
        end do
      end if
      call free_work_array(thickness)
      
    end subroutine by_volume
  end subroutine adj_test_obs


  module subroutine adj_test(model)
    implicit none
    type(model_container) :: model

    integer :: nx, ny, nz, nsp, istep
    type(tmass_map), pointer :: map_c
    real, dimension(:,:,:,:), allocatable :: arr1, arr2, m_arr

    type(silja_time) :: now
    type(silja_interval) :: timestep
    integer, parameter :: nsteps = 48
    type(Temission_processor), pointer :: proc_ptr
    integer :: ii
    type(Tmoment_mapping) :: cm_to_moment
    type(Tmass_map), pointer :: MMptr

    call create_moment_2_cm_mapping(fu_advection_moment_X_MM_ptr(model%cloud),&
                                  & fu_concMM_ptr(model%cloud), &
                                  & fu_low_mass_threshold(model%rules%chemicalRules), &
                                  & centre_mass_vs_moment_species, cm_to_moment)

    call random_seed(put=(/(12, ii=1,120)/))
    
    timestep = model%rules%timestep
    model%rules%periodToCompute = timestep
    model%rules%darules%assim_window = timestep
    !model%rules%darules%da_end = model%rules%startTime + (timestep)
    model%obs_ptr%hasObservations = .false.

    ! Kill emissions
    !
    proc_ptr => fu_emission_processor_ptr(model%cloud)
    call set_emission_processor(fu_emisMM_ptr(model%cloud), fu_species_transport(model%cloud), &
                              & processor_scaling_flag, proc_ptr)
    call zero_processor_grad(proc_ptr)

    call msg('Will run model for one timestep')
    call model_forward(model, model%rules)
    call msg('')
    call msg('done')
    call msg('')

    call msg('Now testing adjoint...')

    map_c => fu_concMM_ptr(model%cloud)
    nx = map_c%nx
    ny = map_c%ny
    nz = map_c%n3d
    nsp = map_c%nspecies

    MMptr => fu_concMM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    MMptr => fu_advection_moment_X_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    MMptr => fu_advection_moment_Y_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    MMptr => fu_advection_moment_Z_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)

    allocate(arr1(nsp,nz,nx,ny), arr2(nsp,nz,nx,ny), m_arr(nsp,nz,nx,ny))
    
    arr1 = 0.0
    arr2 = 0.0
    m_arr = 0.0
    
    !call random_number(arr1(:,:,5:nx-5,5:ny-5))
    !call random_number(arr1(:,:,:,:))
    !call random_number(arr2)
    !call random_number(arr2(:,:,5:nx-5,5:ny-5))
    !arr1 = arr1 + 1
    !arr2 = arr2 + 1

    !call random_number(arr1(:,:,20,20))
    !call random_number(arr2(:,:,20,20))

!!$    arr1(:,:,20,20) = 1.0
!!$    arr2(:,:,20,20) = 1.0
!!$
!!$    arr1(:,:,10:20,10:20) = 1.0
!!$    arr2(:,:,10:20,10:20) = 1.0

    call random_number(arr1(:,:,10:20,10:20))
    call random_number(arr2(:,:,10:20,10:20))
    arr1 = (arr1+10)*1000
    arr2 = (arr2+10)*1000



    !call random_number(arr1(:,:,:,:))
    !call random_number(arr2(:,:,:,:))


    !arr1 = (arr1 + 10)*1000
    !arr2 = (arr2 + 10)*1000

    !arr1(:,3,:,:) = 1.0
    !arr2(:,3,:,:) = 1.0

    model%rules%periodToCompute = timestep
    model%rules%darules%assim_window = timestep*nsteps
    !model%rules%darules%da_end = model%rules%startTime + timestep*nsteps
    !model%rules%if_collect_linearization = .true.
    !allocate(linearizations(nsteps))
    !do istep = 1, nsteps
    !  call alloc_transp_t_lin(linearizations(istep), dispersion_grid, dispersion_vertical, &
    !                        & fu_nbr_of_species_transport(model%cloud), 1)
    !end do
    map_c%arm = 0.0
    map_c%arm(1:nsp,1,1:nz,1:nx,1:ny) = arr1
    timestep = timestep
    ! Now run the model process on arr1, forward

!!$    do istep = 1, nsteps
!!$      call msg('')
!!$      call msg('', istep)
!!$      call msg('')

!!$      CALL advect_pollution_cloud_v4(model%cloud, &
!!$                                   & now, &
!!$                                   & timestep,&
!!$                                   & model%rules%diffusionMethod, &
!!$                                   & model%rules%ifThermodiffusion, &
!!$                                   & 1.0, & ! weight_past
!!$                                   & model%meteo_ptr, & 
!!$                                   & model%disp_buf_ptr, &
!!$                                   & model%wdr, &
!!$                                   & model%rules%chemicalRules, &
!!$                                   & linearizations(istep))

!!$      call transform_pollution_cloud_v5(model%cloud, now, timestep, &
!!$                                      & model%meteo_ptr, model%disp_buf_ptr, &
!!$                                      & model%Meteo_input, & 
!!$                                      & model%wdr, model%rules%chemicalRules)

!!$      call msg('sum',sum(abs(linearizations(istep)%cm_x_before_adv)) / (nx*ny*nz*nsp))
!!$    
!!$      call flip_moment_and_basic_var(cm_to_moment, fu_advection_moment_X_MM_ptr(model%cloud), &
!!$                                   & fu_concMM_ptr(model%cloud), to_moment)
!!$      call flip_moment_and_basic_var(cm_to_moment, fu_advection_moment_Y_MM_ptr(model%cloud), &
!!$                                   & fu_concMM_ptr(model%cloud), to_moment)
!!$      call flip_moment_and_basic_var(cm_to_moment, fu_advection_moment_Z_MM_ptr(model%cloud), &
!!$                                   & fu_concMM_ptr(model%cloud), to_moment)
!!$      call collect_total_masses(model%cloud)
!!$      call report_total_masses(model%cloud, 99, .true.)
!!$      
!!$    end do

    call model_forward(model, model%rules)

    m_arr = map_c%arm(1:nsp,1,1:nz,1:nx,1:ny)
    call msg('RIGHT', fu_inner(m_arr, arr2))
    
    ! Adjoint
    
    MMptr => fu_advection_moment_X_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    MMptr => fu_advection_moment_Y_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)
    MMptr => fu_advection_moment_Z_MM_ptr(model%cloud)
    call reset_map_to_val(MMptr, 0.0)

    map_c%arm(1:nsp,1,1:nz,1:nx,1:ny) = arr2

!!$    do istep = 1, nsteps
!!$      CALL advect_pollution_cloud_v4(model%cloud, &
!!$                                   & now, &
!!$                                   & fu_opposite(timestep),&
!!$                                   & model%rules%diffusionMethod, &
!!$                                   & model%rules%ifThermodiffusion, &
!!$                                   & 1.0, & ! weight_past
!!$                                   & model%meteo_ptr, & 
!!$                                   & model%disp_buf_ptr, &
!!$                                   & model%wdr, &
!!$                                   & model%rules%chemicalRules, &
!!$                                   & linearizations(nsteps-istep+1))

!!$      call transform_pollution_cloud_v5(model%cloud, now, fu_opposite(timestep), &
!!$                                      & model%meteo_ptr, model%disp_buf_ptr, &
!!$                                      & model%Meteo_input, & 
!!$                                      & model%wdr, model%rules%chemicalRules)
!!$
!!$      
!!$    end do
    
    call model_adjoint(model, model%obs_ptr, model%rules)
    m_arr = map_c%arm(1:nsp,1,1:nz,1:nx,1:ny)    
    call msg('LEFT', fu_inner(m_arr, arr1))
    
    stop
    
  contains
    
    real function fu_inner(xx, y) result(inner)
      implicit none
      real, dimension(:,:,:,:), intent(in) :: xx, y
      
      integer :: ind_1, ind_2, ind_3, ind_sp
      real :: dz, dxdy
      real(r8k) :: inner_8

      inner = 0.0
      inner_8 = 0

      do ind_1 = 1, size(xx, 3)
        do ind_2 = 1, size(xx, 4)
          do ind_3 = 1, size(xx, 2)
            do ind_sp = 1, size(xx,1)
              dz = 1.0!dispersion_layer_z_size(ind_3)
              !dz = dispersion_layer_z_size(ind_3)
              dxdy = 1.0!fu_cell_size(dispersion_grid, ind_1, ind_2)
              inner_8 = inner_8 + xx(ind_sp,ind_3,ind_1,ind_2)*y(ind_sp,ind_3,ind_1,ind_2)/(dz*dxdy)
            end do
          end do
        end do
      end do
      inner = inner_8
    end function fu_inner
  end subroutine adj_test


  module subroutine run_forecast_dummy(control, model)
    ! Doesn't run the model but perturbs the fields with gaussian noise and processes the
    ! observations.
    implicit none
    type(model_container), intent(inout) :: model
    type(da_control), intent(in) :: control
    
    type(silja_time) :: now
    type(Tmass_map), pointer ::cnc_ptr
    real, parameter :: autocorr = 0.9
    real, dimension(1) :: value, noise
    real, dimension(:), pointer :: thickness
    integer :: ilev
    logical, save :: first = .true.

    if (.not. fu_in_physical_space(control)) then
      call set_error('Control variable not in physical space', 'get_obs_cost')
      return
    end if
    
    model%rules%darules%allow_negative = .true.
    if (model%obs_ptr%hasObservations) call reset_all(model%obs_ptr, .true.)
    cnc_ptr => fu_concMM_ptr(model%cloud)
    call msg('sum cloud before:', sum(cnc_ptr%arm(8,:,:,:,:)))
    call msg('sum control:', sum(fu_values_ptr(control)))
    call test_bind_control2cloud(control, model, handle_negatives=fu_mode(control) == da_initial_state)
    call msg('sum cloud after:', sum(cnc_ptr%arm(8,:,:,:,:)))

    now = model%rules%startTime

    thickness => fu_work_array()
    thickness(1:nz_dispersion) = (/(fu_layer_thickness_m(fu_level(dispersion_vertical, ilev)), &
                                  & ilev = 1, nz_dispersion)/)
    !call msg('thick:', thickness(1:nz_dispersion))
    if (first) then
      call random_normal(noise)
      call putcnc(noise(1), 0.0, value(1))
      first = .false.
      return
    end if
    do while(fu_between_times(now, &
                            & model%rules%startTime, &
                            & model%rules%startTime + model%rules%periodToCompute, &
                            & .true.))
      call random_normal(noise)
      !call msg('New sample:', sample_new(1))
            
      call putcnc(noise(1), autocorr, value(1))
      call msg('Concentration:', value(1))
      call msg('sum cloud:', sum(cnc_ptr%arm(8,:,:,:,:)))
      call msg('Run forecast dummy: ' // fu_str(now))
      call observeAll(model%obs_ptr, model%cloud,&
                    & model%meteo_ptr, model%disp_buf_ptr, model%rules%chemicalRules, &
                    & model%rules%dynamicsRules, &
                    & model%rules%timestep, now)
      now = now + model%rules%timestep

    end do

    call free_work_array(thickness)

  contains

    subroutine putcnc(noise, weight_past, new_value)
      implicit none
      real :: noise, new_value, weight_past

      integer :: ix, iy, iz
      real :: volume

      do iy = 1, ny_dispersion
        do ix = 1, nx_dispersion
          do iz = 1, nz_dispersion
            volume = thickness(iz) * fu_cell_size(dispersion_grid, ix, iy)  !!!FIXME  VOLUME
            cnc_ptr%arm(:,:,iz,ix,iy) = &
                 & (weight_past*cnc_ptr%arm(:,:,iz,ix,iy)/volume + (1-weight_past)*noise)*volume
          end do
        end do
      end do

      volume = thickness(1) * fu_cell_size(dispersion_grid, 1, 1)
      new_value = cnc_ptr%arm(1,1,1,1,1)/volume

    end subroutine putcnc

  end subroutine run_forecast_dummy

end submodule test_da_interface_impl
