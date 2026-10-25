submodule (observations_vertical) test_observations_vertical_impl
  implicit none
contains

  module subroutine test_vert_kern()
    implicit none
    integer, parameter :: nzdisp=5, nzkern=4, nzobs=2
    real, dimension(nzdisp+1) :: disp_vert_bnds_pa = (/1000.0, 950.0, 850.0, 700.0, 500.0, 350.0/), &
         & disp_vert_bnds_m = (/0.0, 100.0, 200.0, 400.0, 700.0, 1000.0/)
    real, dimension(nzkern+1) :: kern_vert_bnds_pa = (/1013.0, 800.0, 550.0, 300.0, 150.0/), &
         & kern_vert_bnds_m = (/20.0, 400.0, 800.0, 1400.0, 2000.0/)
    real, dimension(nzobs, nzkern) :: kern_values
    real, dimension(nzdisp, nzobs) :: kernel

    integer :: ilev_kern, ilev_disp, ilev_obs


    print *, 'Testing av kernel: Pa'
    kern_values = 0.0
    kern_values(1,1:2) = 1.0
    kern_values(2,3:4) = 1.0
    call get_vert_kern(disp_vert_bnds_pa, kern_vert_bnds_pa, kern_values, 'Pa', kernel)
    
    do ilev_disp = 1, nzdisp
      do ilev_obs = 1, nzobs
        print *, 'ilev_disp, ilev_obs, value', ilev_disp, ilev_obs, kernel(ilev_disp, ilev_obs)
      end do
    end do

    print *, 'Testing av kernel: m'
    kern_values = 0.0
    kern_values(1,1:2) = 1.0
    kern_values(2,3:4) = 1.0
    call get_vert_kern(disp_vert_bnds_m, kern_vert_bnds_m, kern_values, 'm', kernel)
    
    do ilev_disp = 1, nzdisp
      do ilev_obs = 1, nzobs
        print *, 'ilev_disp, ilev_obs, value', ilev_disp, ilev_obs, kernel(ilev_disp, ilev_obs)
      end do
    end do

    print *, 'Testing av kernel for column: m'

    kern_values(1,:) = (/0.2, 0.3, 0.4, 0.5/)
    call get_vert_kern(disp_vert_bnds_m, kern_vert_bnds_m, kern_values(1:1,:), 'm', kernel(:,1:1))
    
    print *, 'Kernel in original vert'
    do ilev_kern = 1, nzkern
      print *, 'meters, value:', 0.5 * (kern_vert_bnds_m(ilev_kern)+kern_vert_bnds_m(ilev_kern+1)), &
           & kern_values(1,ilev_kern)
    end do

    print *, 'Kernel in disp vert'
    do ilev_disp = 1, nzdisp
      print *, 'meters, value:', 0.5 * (disp_vert_bnds_m(ilev_disp)+disp_vert_bnds_m(ilev_disp+1)), &
           & kernel(ilev_disp, 1)
    end do

  end subroutine test_vert_kern


  module subroutine make_test_obs(which, valid_time, transport_species, optical_species, obs)
    implicit none
    character(len=*), intent(in) :: which
    type(silam_species), dimension(:), intent(in) :: transport_species
    type(silam_species), dimension(:), pointer :: optical_species
    type(silja_time), intent(in) :: valid_time
    type(t_vertical_observation), intent(out) :: obs
    
    real, dimension(:,:,:), allocatable :: val_3d, std_3d
    real, dimension(:), allocatable:: lon_2d, lat_2d
    real, dimension(:,:,:,:), pointer :: vert_kern
    real, dimension(:), pointer :: chem_kern, disp_vert_bnds_m, kern_vert_bnds_m, kern1d
    real, dimension(:,:), pointer :: kern_values, kern, work2d
    real, dimension(:,:,:,:), allocatable :: kern2d
    real, dimension(0,0,0) :: kern_lev_bnds ! won't use
    type(silam_species), dimension(:), pointer :: observed_species, dummy_species_ptr
    integer nx, ny, num_obs, ilev, nzdisp
    type(t_vertical_observation), dimension(:), pointer :: obs_list
    
    select case(which)
    case ('column_so2')
      nx = 2
      ny = 2
      call get_vert_kern_trivial(dispersion_vertical, nx, ny, vert_kern)
      allocate(observed_species(1))
      call set_species(observed_species(1), fu_get_material_ptr('SO2'), in_gas_phase) 
      call get_chem_kern(observed_species, transport_species, 'mole/m2', chem_kern, if_profile=.false.)
      !allocate(val_3d(1,nx,ny), std_3d(1,nx,ny), lon_2d(nx*ny), lat_2d(nx*ny))
      allocate(val_3d(nx,ny,1), std_3d(nx,ny,1), lon_2d(nx*ny), lat_2d(nx*ny))

      val_3d(1,1,1) = 1.0
      val_3d(2,1,1) = 2.0
      val_3d(1,2,1) = 0.0
      val_3d(2,2,1) = real_missing
      
      val_3d = 0.0

      std_3d = 1.0
      
      lon_2d(1) = 10.0 ! 1, 1
      lon_2d(2) = 10.5 ! 2, 1
      lon_2d(3) = 10.0
      lon_2d(4) = 10.5
      lat_2d = (/40.0, 40.0, 40.5, 40.5/)
      
      call create_vert_obs(val_3d, std_3d, lon_2d, lat_2d, nx, ny, chem_kern, vert_kern, .false., &
                         & .false., kern_lev_bnds, &
                         & valid_time, which, '', .false., .false., dispersion_grid, linear, obs)

    case ('column_so2_kern')
      nx = 2
      ny = 2
      
      kern => fu_work_array_2d()
      kern1d => fu_work_array()

      disp_vert_bnds_m => fu_work_array()
      nzdisp = fu_NbrOfLevels(dispersion_vertical)
      do ilev = 1, nzdisp
        disp_vert_bnds_m(ilev+1) = &
             & fu_level_height(fu_upper_boundary_of_layer(fu_level(dispersion_vertical, ilev)))
        disp_vert_bnds_m(ilev) = &
             & fu_level_height(fu_lower_boundary_of_layer(fu_level(dispersion_vertical, ilev)))
      end do
      kern_vert_bnds_m => fu_work_array()
      kern_vert_bnds_m(1:5) = (/0.0, 500.0, 1000.0, 5000.0, 100000.0/)
      kern_values => fu_work_array_2d()
      !kern_values(1,1:4) = (/0.1, 0.2, 0.3, 0.4/)
      kern_values(1,1:4) = (/1.0, 1.0, 1.0, 1.0/)
      work2d => fu_work_array_2d()
      kern => work2d(1:1, 1:nzdisp)
      call get_vert_kern(disp_vert_bnds_m(1:nzdisp+1), kern_vert_bnds_m(1:5), kern_values(1:1,1:4), 'm', kern)
      call free_work_array(kern_vert_bnds_m)
      call free_work_array(kern_values)
      call free_work_array(disp_vert_bnds_m)

      allocate(observed_species(1))
      call set_species(observed_species(1), fu_get_material_ptr('SO2'), in_gas_phase)
      call get_chem_kern(observed_species, transport_species, 'mg/m2', chem_kern, .false.)
      !allocate(val_3d(1,nx,ny), std_3d(1,nx,ny), lon_2d(nx*ny), lat_2d(nx*ny))
      allocate(val_3d(nx,ny,1), std_3d(nx,ny,1), lon_2d(nx*ny), lat_2d(nx*ny))

      val_3d(1,1,1) = 1.0
      val_3d(2,1,1) = 2.0
      val_3d(1,2,1) = 0.0
      val_3d(2,2,1) = real_missing
      
      std_3d = 0.5
      
      lon_2d(1) = 10.0 ! 1, 1
      lon_2d(2) = 10.5 ! 2, 1
      lon_2d(3) = 10.0
      lon_2d(4) = 10.5
      lat_2d = (/40.0, 40.0, 40.5, 40.5/)
      
      allocate(kern2d(nzdisp, 1, nx,ny))
      kern2d(:,:,1,1) = transpose(kern)
      kern2d(:,:,2,1) = transpose(kern)
      kern2d(:,:,1,2) = transpose(kern)
      kern2d(:,:,2,2) = transpose(kern)

      call create_vert_obs(val_3d, std_3d, lon_2d, lat_2d, nx, ny, chem_kern, kern2d, .false., .false., &
                         & kern_lev_bnds, valid_time, which, '', .false., .false., dispersion_grid, linear, obs)
      

    case ('file')
      allocate(observed_species(1), obs_list(100))
      call set_species(observed_species(1), fu_get_material_ptr('SO2'), in_gas_phase)
      nullify(dummy_species_ptr)
      call set_vert_obs_from_nc('test.nc', 'col_dens', observed_species, &
                              & transport_species, dummy_species_ptr, &
                              & really_far_in_past, really_far_in_future, obs_list, num_obs)
      if (error) return
      if (fu_fails(num_obs > 0, 'Failed to read observations', 'make_test_obs')) return
      obs = obs_list(1)

    case ('file_kern')
      allocate(observed_species(1), obs_list(100))
      call set_species(observed_species(1), fu_get_material_ptr('SO2'), in_gas_phase)
      nullify(dummy_species_ptr)
      call set_vert_obs_from_nc('testdata_kern.nc', 'SO2', &
                              & observed_species, transport_species, dummy_species_ptr, &
                              & really_far_in_past, really_far_in_future, obs_list, num_obs)
      if (error) return
      if (fu_fails(num_obs > 0, 'Failed to read observations', 'make_test_obs')) return
      obs = obs_list(1)

    case ('file_omi_kern')
      allocate(observed_species(1), obs_list(100))
      call set_species(observed_species(1), fu_get_material_ptr('NO2'), in_gas_phase)
      nullify(dummy_species_ptr)
      call set_vert_obs_from_nc('testdata_omi_kern.nc', 'NO2', &
                              & observed_species, transport_species, dummy_species_ptr, &
                              & really_far_in_past, really_far_in_future, obs_list, num_obs)
      if (error) return
      if (fu_fails(num_obs > 0, 'Failed to read observations', 'make_test_obs')) return
      obs = obs_list(1)

    case ('file_aod')
      allocate(observed_species(1))
      call set_species(observed_species(1), fu_get_material_ptr('SO2'), in_gas_phase) 
      call set_vert_obs_from_nc('test_aod.nc', 'aot', observed_species, &
                              & transport_species, optical_species, &
                              & really_far_in_past, really_far_in_future, obs_list, num_obs)
      if (error) return
      if (fu_fails(num_obs > 0, 'Failed to read observations', 'make_test_obs')) return
      obs = obs_list(1)

      
    case default 
      call set_error('No such option: ' // trim(which), 'make_test_obs')
    end select

  end subroutine make_test_obs


  module subroutine test_vert_obs(map_c, map_px, map_py, map_pz, now, timestep, &
                         & p_rel_hum, p_tempr, p_press, p_hgt, p_surf_press, &
                          & met_disp_interp_horiz, if_met_disp_interp_horiz, &
                          & met_disp_interp_vert, if_met_disp_interp_vert, &
                          & weight_past, rules_opt_dens, optical_species)
    implicit none
    !type(t_vertical_observation), intent(inout) :: obs
    type(Tmass_map) :: map_c, map_px, map_py, map_pz
    type(silja_time), intent(in) :: now
    type(silja_interval), intent(in) :: timestep
    type(field_4d_data_ptr), pointer :: p_rel_hum, p_tempr, p_press, p_hgt
    type(field_2d_data_ptr), pointer :: p_surf_press
    type(THorizInterpStruct), pointer :: met_disp_interp_horiz
    logical, intent(in) :: if_met_disp_interp_horiz
    type(TVertInterpStruct), pointer :: met_disp_interp_vert
    logical, intent(in) :: if_met_disp_interp_vert
    real, intent(in) :: weight_past
    type(Toptical_density_rules), intent(in) :: rules_opt_dens
    type(silam_species), dimension(:), pointer :: optical_species
    type(t_vertical_observation) :: obs
    real, dimension(:), allocatable :: val_obs, val_mdl, var
    integer :: n_obs, ilev
    real :: right, left, area, dz
    real, dimension(:,:,:,:,:), allocatable :: x_rhs
    real, dimension(:,:,:,:,:), pointer :: map_c_in 
    integer :: ix, iy, n_opt_species
    
    if (associated(optical_species)) then
      n_opt_species = size(optical_species) 
    else
      n_opt_species = 0
    end if
    
    !call make_test_obs('column_so2', now+timestep/2.0, map_c%species, obs)
    !call make_test_obs('column_so2_kern', now+timestep/2.0, map_c%species, optical_species, obs)
    !call make_test_obs('file_kern', now+timestep/2.0, map_c%species, optical_species, obs)
    call make_test_obs('file_omi_kern', now+timestep/2.0, map_c%species, optical_species, obs)
    !call make_test_obs('file', now+timestep/2.0, map_c%species, optical_species, obs)
    !call make_test_obs('file_aod', now+timestep/2.0, map_c%species, optical_species, obs)
    if (error) return
    
    map_c%arm = 0.0
    
    n_obs = fu_size(obs)
    allocate(val_obs(n_obs), val_mdl(n_obs), var(n_obs), &
           & x_rhs(map_c%nspecies, map_c%nsrc, map_c%n3d, map_c%nx, map_c%ny))
    
    call random_number(x_rhs)
    map_c%arm(1:map_c%nspecies, 1:map_c%nsrc, 1:map_c%n3d, 1:map_c%nx, 1:map_c%ny) = x_rhs    
    call random_number(val_obs)

    ! check the identity < Rinv.(y - Hx), Hx > = < H*.Rinv.(y - Hx), x > 
    
    ! note: the control variable x in concentration, but when given to observe_vertical,
    ! map_c is assumed to have cell mass. In the final computation, the values in x are
    ! hence divided by volume to evaluate the expression on RHS.
    
    !obs%disp_area = 1.0
    call observe_vertical(obs, map_c, &
                        & now, timestep, p_rel_hum, p_tempr, p_press, p_hgt, p_surf_press, &
                        & met_disp_interp_horiz, if_met_disp_interp_horiz, &
                        & met_disp_interp_vert, if_met_disp_interp_vert, &
                        & weight_past, rules_opt_dens, n_opt_species)
    if (error) return
    call obs_to_file(obs, optical_species, 6)
    call get_data_vertical(obs, values_obs = val_obs)
    call get_data_vertical(obs, values_mdl = val_mdl)
    call get_data_vertical(obs, variance = var)

    ! now: 
    ! map_c%arm = x
    ! val_mdl = Hx
    ! val_obs = y
    ! 1/var = Rinv
    
    left = sum( (val_mdl - val_obs)/var * val_mdl  ) ! < Rinv . (y - Hx), Hx >

    map_c%arm = 0.0
    call inject_vertical(obs, map_c, map_px, map_py, map_pz, &
                       & now, timestep, p_rel_hum, p_tempr, &
                       & met_disp_interp_horiz, if_met_disp_interp_horiz, &
                       & met_disp_interp_vert, if_met_disp_interp_vert, &
                       & weight_past, rules_opt_dens, n_opt_species)
    ! now map_c%arm = H* Rinv.(y - Hx)

    ! after injection we need to involve volume:
    right = 0.0
    do ilev = 1, map_c%n3d
      dz = fu_layer_thickness_m(fu_level(map_c%vertTemplate, ilev))
      do iy = 1, map_c%ny
        do ix = 1, map_c%nx
          area = fu_cell_size(dispersion_grid, ix, iy)
          right = right + sum(map_c%arm(:,1,ilev,ix,iy) * x_rhs(:,1,ilev,ix,iy) / (area*dz))
        end do
      end do
    end do
    !right = sum( map_c%arm(1:map_c%nspecies, 1:map_c%nsrc, 1:map_c%n3d, 1:map_c%nx, 1:map_c%ny) *  x_rhs )
    call msg('LEFT', left)
    call msg('RIGHT', right)

    ! hack the cell area and chem kernel to 1 so we should get exactly the kernel values.
    obs%disp_area = 1.0
    where (obs%chem_kernel > 0) 
      obs%chem_kernel = 1.0
    end where
    do ilev = 1, map_c%n3d
      map_c%arm = 0.0
      map_c%arm(:,1,ilev,:,:) = 1.0
      call msg('level:', ilev)
      call msg('range', fu_level_height(fu_lower_boundary_of_layer(fu_level(dispersion_vertical, ilev))), &
             & fu_level_height(fu_upper_boundary_of_layer(fu_level(dispersion_vertical, ilev))))
      call observe_vertical(obs, map_c, &
                          & now, timestep, p_rel_hum, p_tempr, p_press, p_hgt, p_surf_press, &
                          & met_disp_interp_horiz, if_met_disp_interp_horiz, &
                          & met_disp_interp_vert, if_met_disp_interp_vert, &
                          & weight_past, rules_opt_dens, n_opt_species)
      call get_data_vertical(obs, values_mdl=val_mdl)
      print *, 'val_mdl:', val_mdl
    end do

  end subroutine test_vert_obs

end submodule test_observations_vertical_impl
