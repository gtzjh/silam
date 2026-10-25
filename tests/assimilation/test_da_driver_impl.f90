submodule (da_driver) test_da_driver_impl
  implicit none
contains

  module subroutine test_var_da(model)
    ! test the da subsystem, model must defined with some emission, etc.
    implicit none
    type(model_container), intent(inout) :: model
    ! test_init creates:
    type(DA_rules) :: rules_fake
    type(t_background_covariance) :: bgr_cov_fake 
    type(t_spatial_correlation) :: correlation

    call test_init_v2('test', fu_species_transport(model%cloud), fu_species_emission(model%cloud), &
                    & wholeMPIdispersion_grid, dispersion_vertical, correlation, bgr_cov_fake, rules_fake)

  end subroutine test_var_da


  module subroutine gradient_test(model)
    implicit none
    type(model_container), intent(inout) :: model
    
    type(da_control) :: control, gradient, background, random
    type(t_background_covariance) :: bgr_cov
    real, dimension(:), pointer ::mdl_obs_values, initial_values, grad_values, rand_values
    real :: cost_obs(2), cost_bgr(2), cost, norm

    integer :: ix, iy, iz, isp, nx, ny, nz, nsp, ind, n_control
    type(Temission_processor), pointer :: proc_ptr

!    real :: delta = 1e1 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5
    real :: delta = 0.3e-1
    real :: fdiff, cost2, cost1
    real :: background_val = 0.0, background_init = 5e-6

    ! Kill emissions
    !
    proc_ptr => fu_emission_processor_ptr(model%cloud)
    call set_emission_processor(fu_emisMM_ptr(model%cloud), fu_species_transport(model%cloud), &
                              & processor_scaling_flag, proc_ptr)
    call zero_processor_grad(proc_ptr)

    call init_control_from_cloud(background, model%cloud, model%rules%darules, physical_space, background_init)
    
    call set_cov_mdl(bgr_cov, background, &
                   & fu_species_emission(model%cloud), fu_species_transport(model%cloud), &
                   & model%rules%darules, dispersion_grid, wholeMPIdispersion_grid, dispersion_vertical, &
                   & model%rules%darules%da_begin, model%rules%darules%controlVariable)
    call init_control_from_cloud(control, model%cloud, model%rules%darules, control_space, 0.0, bgr_cov)
    call init_control_from_cloud(random, model%cloud, model%rules%darules, control_space, 0.0, bgr_cov)
    call init_control_from_cloud(gradient, model%cloud, model%rules%darules, control_space, 0.0, bgr_cov)

    !model%rules%if_collect_linearization = .true.
    rand_values => fu_initial_ptr(random)
    call random_number(rand_values)
    n_control = fu_size(control) !fu_dimension_control(bgr_cov%correlation_initial)
    norm = sum(rand_values(1:n_control)**2)
    rand_values = rand_values / norm


    ix = 28
    iy = 23
    iz = 1
    isp = 1
    
    nx = nx_dispersion
    ny = ny_dispersion
    nz = nz_dispersion
    nsp = fu_size(control) / (nx*ny*nz) !fu_nbr_of_species_transport(model%cloud)

    !call msg('delta*1e-6*volume', delta*1e-6*fu_cell_size(wholeMPIdispersion_grid, ix, iy)*50)
    !call msg('bgr*1e-6*volume', background_val*1e-6*fu_cell_size(wholeMPIdispersion_grid, ix, iy)*50)
    !call msg('bgr+delta...', (background_val+delta)*1e-6*fu_cell_size(dispersion_grid, ix, iy)*50)
    ind = (iy-1)*nx*nz*nsp + (ix-1)*nz*nsp + (iz-1)*nsp + isp
    initial_values => fu_initial_ptr(control)
    initial_values(1:fu_n_initial(control)) = background_val

    ! Evaluate at -delta
    !initial_values(ind) = background_val - delta
    initial_values = background_val - delta*rand_values
    call test_bind_evaluate(control, background, bgr_cov, model, cost_obs, cost_bgr, cost1)

    ! Evaluate at delta
    !initial_values(ind) = background_val + delta
    initial_values = background_val + delta*rand_values
    call test_bind_evaluate(control, background, bgr_cov, model, cost_obs, cost_bgr, cost2)

    ! Gradient at zero
    initial_values(ind) = background_val
    call test_bind_evaluate(control, background, bgr_cov, model, cost_obs, cost_bgr, cost)
    call finalise_output(model%cloud, model%out_def, model%wdr, model%source)
    call test_bind_get_gradient(control, gradient, background, bgr_cov, model)
    !call to_physical(gradient, background, bgr_cov)
    call control_to_file(gradient, background, model%rules%darules, 'gradient')


    call msg('Cost1', cost1)
    call msg('Cost2', cost2)

    grad_values => fu_initial_ptr(gradient)
    call msg('physical:', size(grad_values))
    call msg('control:', n_control)
    call msg('max(abs(grad))', maxval(abs(grad_values(1:fu_n_initial(gradient)))))
    !call msg('grad', grad_values(ind))
    call msg('grad_proj', sum(grad_values(1:n_control)*rand_values(1:n_control)))
    fdiff = (cost2 - cost1) / (2*delta)
    
    call msg('fdiff', fdiff)
    !call msg('err', abs(fdiff-grad_values(ind)))
    stop
  end subroutine gradient_test


  module subroutine gradient_test_emis(model)
    implicit none
    type(model_container), intent(inout) :: model
    
    type(da_control) :: control, gradient, background
    type(t_background_covariance) :: bgr_cov
    real, dimension(:), pointer :: grad_values, proc_values
    real :: cost_obs(2), cost_bgr(2), cost

    integer :: ix, iy, iz, isp, nx, ny, nz, nsp, ind, iPurpose
    type(Temission_processor), pointer :: proc_ptr

!    real :: delta = 1e1 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5
    real :: delta = 0.1e2
    real :: fdiff, cost2, cost1
    real :: background_val = 0.05 ! standard deviations
    


    proc_ptr => fu_emission_processor_ptr(model%cloud)
    call set_emission_processor(fu_emisMM_ptr(model%cloud), fu_species_transport(model%cloud), &
                              & processor_scaling_flag, proc_ptr)
    proc_values => fu_data(proc_ptr, forwards)
    proc_values = 1.0

    call init_control_from_cloud(control, model%cloud, model%rules%darules, control_space, 0.0)
    call init_control_from_cloud(gradient, model%cloud, model%rules%darules, physical_space)
    call init_control_from_cloud(background, model%cloud, model%rules%darules, physical_space, 1.0)
    
    call set_cov_mdl(bgr_cov, background, &
                   & fu_species_emission(model%cloud), fu_species_transport(model%cloud), &
                   & model%rules%darules, dispersion_grid, wholeMPIdispersion_grid, dispersion_vertical, &
                   & model%rules%darules%da_begin, model%rules%darules%controlVariable)
    !model%rules%if_collect_linearization = .false.

    ix = 23
    iy = 29
    isp = 1
    
    nx = nx_dispersion
    ny = ny_dispersion
    nz = nz_dispersion
    nsp = fu_nbr_of_species_transport(model%cloud)

    call msg('delta*1e-6*volume', delta*1e-6*fu_cell_size(dispersion_grid, ix, iy)*50)
    call msg('bgr*1e-6*volume', background_val*1e-6*fu_cell_size(dispersion_grid, ix, iy)*50)
    call msg('bgr+delta...', (background_val+delta)*1e-6*fu_cell_size(dispersion_grid, ix, iy)*50)
    ind = (iy-1)*nx*nsp + (ix-1)*nsp + isp

    proc_values => fu_emission_ptr(control)
    proc_values(1:fu_n_emission(control)) = background_val

    ! Evaluate at -delta
    proc_values(ind) = background_val - delta
    call test_bind_evaluate(control, background, bgr_cov, model, cost_obs, cost_bgr, cost1 )
    do iPurpose = 1, 2
      call dump_observations(model%obs_ptr, fu_species_transport(model%cloud), &
                           & 'obs-delta' + chObsPurpose(iPurpose), iPurpose)
    end do
    ! Evaluate at delta
    proc_values(ind) = background_val + delta
    call test_bind_evaluate(control, background, bgr_cov, model, cost_obs, cost_bgr, cost2)
    do iPurpose = 1, 2
     call dump_observations(model%obs_ptr, fu_species_transport(model%cloud), &
                          & 'obs+delta' + chObsPurpose(iPurpose), iPurpose)
    end do
    ! Gradient at zero
    proc_values(ind) = background_val
    call test_bind_evaluate(control, background, bgr_cov, model, cost_obs, cost_bgr, cost)
    call finalise_output(model%cloud, model%out_def, model%wdr, model%source)
    call test_bind_get_gradient(control, gradient, background, bgr_cov, model)
    !call to_physical(gradient, background, bgr_cov)
    call control_to_file(gradient, background, model%rules%darules, 'gradient')


    call msg('Cost1', cost1)
    call msg('Cost2', cost2)

    grad_values => fu_emission_ptr(gradient)
    call msg('max(abs(grad))', maxval(abs(grad_values(1:fu_n_emission(gradient)))))
    call msg('grad', grad_values(ind))
    
    fdiff = (cost2 - cost1) / (2*delta)
    
    call msg('fdiff', fdiff)
    call msg('err', abs(fdiff-grad_values(ind)))
    stop
  end subroutine gradient_test_emis


  module subroutine gradient_test_emis_2(model)
    ! 
    ! Yet another test routine.
    ! Here we'll check the following identity:
    !
    ! < H^T R^-1 (Hx - y), x > = < R^-1 (Hx - y), Hx >.
    !
    ! Here H is taken to mean the compound action of model and observation operator. The
    ! terms can be evaluated when Hx, y and the cost function gradient are available. The
    ! requirement is that model and observations are strictly linear (otherwise the
    ! tangent-linear model would be needed). 
    !
    ! This also assumes that there is no additional forcing besides the control variable:
    ! for emission_correction, initial condition must be void, for initial_state, there
    ! must be no emission (this is handled below). Also when the control variable does not
    ! include all species, the others must be zero. 
    ! 
    ! For the joint initial-emission mode, emission should exist, but initial condition of
    ! the non-control-species must be zero.
    ! 

    implicit none
    type(model_container), intent(inout) :: model
    
    type(da_control) :: control, gradient, background, control_phys
    type(t_background_covariance) :: bgr_cov
    real, dimension(:), pointer :: grad_values, proc_values, bgr_values
    real :: cost_obs(2), cost_bgr(2), cost

    integer :: ix, iy, iz, isp, nx, ny, nz, nsp, ind, ii
    integer, dimension(2) :: n_obs_val
    type(Temission_processor), pointer :: proc_ptr
    real, dimension(:), pointer :: mdl_data, obs_data, obs_var, phys_values

!    real :: delta = 1e1 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5 * 0.5
    real :: delta = 0.1e5
    real :: fdiff, cost2, cost1
    real :: background_val = 0.05 ! standard deviations

    call random_seed(put=(/(12, ii=1,120)/))

    nx = nx_dispersion
    ny = ny_dispersion
    nz = nz_dispersion
    nsp = fu_nbr_of_species_transport(model%cloud)
    

    ix = 55
    iy = 3
    ind = (iy-1)*nx + ix

    mdl_data => fu_work_array()
    obs_data => fu_work_array()
    obs_var => fu_work_array()

    call init_control_from_cloud(background, model%cloud, model%rules%darules, physical_space, 0.0)
    call init_control_from_cloud(control_phys, model%cloud, model%rules%darules, physical_space) 
    
    call set_cov_mdl(bgr_cov, background, &
                   & fu_species_emission(model%cloud), fu_species_transport(model%cloud), &
                   & model%rules%darules, dispersion_grid, wholeMPIdispersion_grid, dispersion_vertical, &
                   & model%rules%darules%da_begin, model%rules%darules%controlVariable)
    call init_control_from_cloud(control, model%cloud, model%rules%darules, control_space, 0.0, bgr_cov)
    call init_control_from_cloud(gradient, model%cloud, model%rules%darules, control_space, 0.0, bgr_cov)

    proc_values => fu_values_ptr(control)
    call random_number(proc_values)

    if (fu_mode(control) == DA_INITIAL_STATE) then
      ! Kill emissions
      !
      proc_ptr => fu_emission_processor_ptr(model%cloud)
      call set_emission_processor(fu_emisMM_ptr(model%cloud), fu_species_transport(model%cloud), &
                                & processor_scaling_flag, proc_ptr)
      call zero_processor_grad(proc_ptr)
    end if

    call test_bind_evaluate(control, background, bgr_cov, model, cost_obs, cost_bgr, cost1)
    call collect_model_data(model%obs_ptr) 
    call get_obs_pointers(model%obs_ptr,  obs_data, mdl_data, obs_var,  n_obs_val)
    ! can now compute R^{-1}(Hx-y)

    call test_bind_get_gradient(control, gradient, background, bgr_cov, model)
    grad_values => fu_values_ptr(gradient)
    !call copy_control(control, control_phys, .false.)
    !call to_physical(control_phys, background)
    call to_physical(control, background, control_phys)
    phys_values => fu_values_ptr(control_phys)

    !call msg('from proc:', proc_values(ind))
    !call msg('in grad:', grad_values(ind)-proc_values(ind))
    call msg('LEFT', sum((proc_values) * (grad_values-proc_values)))
    call msg('RIGHT', sum(mdl_data(1:sum(n_obs_val)) &
                        & * ((mdl_data(1:sum(n_obs_val))-obs_data(1:sum(n_obs_val))) / obs_var(1:sum(n_obs_val)))))

    print *, 'MDLDATA', mdl_data(1:sum(n_obs_val))
    print *, 'OBSDAT', obs_data(1:sum(n_obs_val))
    print *, 'OBSVAR', obs_var(1:sum(n_obs_val))
    print *, 'COUNT', count(abs(grad_values-proc_values) > 0)
    !call msg('LEFT', sum(grad_values))
    !call msg('RIGHT', sum(mdl_data(1:n_obs_val) &
                        !& * ((mdl_data(1:n_obs_val)-obs_data(1:n_obs_val)) / obs_var(1:n_obs_val))))

    stop
  end subroutine gradient_test_emis_2


  module subroutine test_init_v2(test_file_name, species_transport, species_emission, grid, vertical, &
                        & correlation, bgr_cov, darules)
    use correlations
    implicit  none
    character(len=*), intent(in) :: test_file_name
    type(Tsilam_namelist), pointer :: nlptr_corr
    type(Tsilam_namelist_group), pointer :: p_nlgrp
    type(silam_species), dimension(:), intent(in), target :: species_transport, species_emission
    type(silja_grid), intent(in) :: grid
    type(silam_vertical), intent(in) :: vertical

    real, dimension(:), pointer :: wrk
    integer :: nx, ny, fs, nlevs, igf, ilev
    real :: stdev
    type(t_spatial_correlation) :: correlation
    type(silja_field_id) :: fid
    type(silam_species) :: species_so2, species_no2
    type(silja_time) :: sometime = ref_time_01012000
    character(len=fnlen) :: test_cov_ini_file
    type(silam_species), dimension(:), pointer :: p_species_transport, p_species_emission
    
    type(DA_rules) :: darules
    type(t_background_covariance) :: bgr_cov
    type(da_control) :: ctrl_background
    logical :: is_open
    integer :: file_unit

    p_species_transport => species_transport
    p_species_emission => species_emission

    !call set_species(species_so2, fu_get_material_ptr('SO2'), in_gas_phase)
    !if (error) return
    !call set_species(species_no2, fu_get_material_ptr('NO2'), in_gas_phase)
    !if (error) return

    !species_transport = (/species_so2, species_no2/)
    !species_emission = species_transport

    test_cov_ini_file = trim(test_file_name) + '.nl'
    file_unit = fu_next_free_unit()
    open(file_unit, file=test_cov_ini_file, action='write')
    call make_correlation(file_unit, ln_emission_scaling_flag)
    call make_correlation(file_unit, concentration_flag)
    close(file_unit)
   
    call grid_dimensions(correlation%grid, nx, ny)
    fs = nx*ny
    nlevs = fu_nbrOfLevels(correlation%vertical)

    ! let's manufacture some variance data
    !
    call msg('Generating stdev data: emission')
    igf = open_gradsfile_o('', test_file_name, correlation%grid, &
        & time_label_position = instant_fields) !! Not exactly true, but shoudl hit timestamp match
    if (error) return
    wrk => fu_work_array()
    stdev = 0.5
    wrk(1:fs) = stdev
    call msg('SO2, stdev', stdev)

    fid = fu_set_field_id(met_src_missing, ln_emission_scaling_flag, sometime, zero_interval, &
                        & correlation%grid, surface_level, species=species_transport(1))
    call write_next_field_to_gradsfile(igf, fid, wrk(1:fs))
    if (error) return
    stdev = 1.5
    wrk(1:fs) = stdev
    fid = fu_set_field_id(met_src_missing, ln_emission_scaling_flag, sometime, zero_interval, &
                        & correlation%grid, surface_level, species=species_transport(2))
    call write_next_field_to_gradsfile(igf, fid, wrk(1:fs))
    if (error) return
    call msg('NO2, stdev', stdev)
    
    call msg('Generating stdev data: concentration')
    do ilev = 1, nlevs
      stdev = 1e-6 + ilev*1e-6
      wrk(1:fs) = stdev
      fid = fu_set_field_id(met_src_missing, concentration_flag, sometime, zero_interval, &
                          & correlation%grid, fu_level(correlation%vertical, ilev), &
                          & species=species_emission(1))
      call write_next_field_to_gradsfile(igf, fid, wrk(1:fs))
      if (error) return
      call msg('SO2, lev, stdev', ilev, stdev)
    end do
    do ilev = 1, nlevs
      stdev = 1e-5 + ilev*1e-5
      call msg('NO2, lev, stdev', ilev, stdev)
      fid = fu_set_field_id(met_src_missing, concentration_flag, sometime, zero_interval, &
                          & correlation%grid, fu_level(correlation%vertical, ilev), &
                          & species=species_emission(2))
      call write_next_field_to_gradsfile(igf, fid, wrk(1:fs))
      if (error) return
    end do
    
    call close_gradsfile_o(igf,"")

    darules%controlVariable = DA_EMISSION_AND_INITIAL
    !darules%background_var_mode_initial = constant_variance
    !darules%background_var_mode_emission = constant_variance
    !darules%subst_set_init = silja_false
    !darules%subst_set_emis = silja_false
    !call decode_template_string(test_file_name // '.grads.super_ctl', darules%template_var)
    call decode_template_string(test_cov_ini_file, darules%cov_setup_templ_emis)
    call decode_template_string(test_cov_ini_file, darules%cov_setup_templ_init)
    if (error) return
    
    call init_control_from_par(ctrl_background, correlation%grid, correlation%vertical, &
                    & p_species_emission, p_species_transport, darules, physical_space, 0.0)
    inquire(10, opened=is_open)
    print *, 'is_open', is_open

    call set_cov_mdl(bgr_cov, ctrl_background, species_emission, species_transport, &
                   & darules, correlation%grid, correlation%grid, correlation%vertical, sometime, darules%controlVariable)
    
  contains
    
    subroutine make_correlation(file_unit, quantity_flag)
      implicit none
      integer, intent(in) :: file_unit
      integer, intent(in) :: quantity_flag
      
      type(Tsilam_namelist), pointer :: nlptr_corr
      logical :: surface_only

      call msg('Making correlation tests...')
      surface_only = quantity_flag /= concentration_flag

      call test_correlations(0.9, nlptr_corr, correlation, surface_only)
      !file_unit = fu_next_free_unit()
      !open(file_unit, file=filename_nl, action='write', form='formatted')
      call add_namelist_item(nlptr_corr, 'stdev_method', 'from_file')
      call add_namelist_item(nlptr_corr, 'stdev_file', test_file_name // '.super_ctl')
      call add_namelist_item(nlptr_corr, 'substance', 'SO2')
      call add_namelist_item(nlptr_corr, 'quantity', fu_quantity_short_string(quantity_flag))
      write(file_unit, *)'LIST = cov_so2'
      call write_namelist(file_unit, nlptr_corr, ifName=.false., ifPublic=.false.)
      write(file_unit, *)'END_LIST = cov_so2'

      call test_correlations(1.5, nlptr_corr, correlation, surface_only)
      call add_namelist_item(nlptr_corr, 'stdev_method', 'constant')
      call add_namelist_item(nlptr_corr, 'stdev_const', '5.67e-6')
      call add_namelist_item(nlptr_corr, 'substance', '*')
      call add_namelist_item(nlptr_corr, 'quantity', fu_quantity_short_string(quantity_flag))
      write(file_unit, *)'LIST = cov_def'
      call write_namelist(file_unit, nlptr_corr, ifName=.false., ifPublic=.false.)
      write(file_unit, *)'END_LIST = cov_def'
      
      !close(file_unit)
      
    end subroutine make_correlation

!!$    subroutine make_correlation(filename_nl)
!!$      implicit none
!!$      character(len=*), intent(in) :: filename_nl
!!$
!!$      type(Tsilam_namelist), pointer :: nlptr_corr
!!$      integer :: file_unit
!!$      
!!$      call msg('Making correlation tests...')
!!$
!!$      call test_correlations_grid_vert_given(0.9, nlptr_corr, correlation, grid, vertical)
!!$      file_unit = fu_next_free_unit()
!!$      open(file_unit, file=filename_nl, action='write', form='formatted')
!!$      call add_namelist_item(nlptr_corr, 'standard_deviation', '1.23e-6')
!!$      write(file_unit, *)'LIST = default'
!!$      call write_namelist(file_unit, nlptr_corr, ifName=.false., ifPublic=.false.)
!!$      write(file_unit, *)'END_LIST = default'
!!$
!!$      call test_correlations_grid_vert_given(1.5, nlptr_corr, correlation, grid, vertical)
!!$      call add_namelist_item(nlptr_corr, 'standard_deviation', '5.67e-6')
!!$      write(file_unit, *)'LIST = SO2'
!!$      call write_namelist(file_unit, nlptr_corr, ifName=.false., ifPublic=.false.)
!!$      write(file_unit, *)'END_LIST = SO2'
!!$      
!!$      close(file_unit)
!!$      
!!$    end subroutine make_correlation

  end subroutine test_init_v2

end submodule test_da_driver_impl
