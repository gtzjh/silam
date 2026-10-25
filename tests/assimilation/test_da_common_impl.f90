submodule (da_common) test_da_common_impl
  implicit none
contains

  module subroutine test_init_control_array(darules, cloud)
    implicit none
    type(silam_pollution_cloud) :: cloud
    type(da_rules) :: darules

    type(da_control) :: controls(3)
    real, dimension(:), pointer :: storage, rp
    character(len=*), parameter :: subname = 'test_init_control_array'
    
    call test_bind_init_control_array_from_par(controls, dispersion_grid, dispersion_vertical, &
                                   & fu_species_transport(cloud), fu_species_emission(cloud), &
                                   & darules, physical_space, 3, storage, initial_value=0.0, &
                                   & bgr_cov=background_covariance_missing)

    rp => fu_values_ptr(controls(1))
    rp = 1.0
    rp => fu_values_ptr(controls(2))
    rp = 2.0
    if (fu_fails(all(fu_values_ptr(controls(1)) .eps. 1.0), 'bad1', subname)) call unset_error(subname)
    if (fu_fails(all(fu_values_ptr(controls(2)) .eps. 2.0), 'bad2', subname)) call unset_error(subname)
    if (fu_fails(all(fu_values_ptr(controls(3)) .eps. 0.0), 'bad3', subname)) call unset_error(subname)
    call msg(subname // ' finished')
    
  end subroutine test_init_control_array

end submodule test_da_common_impl
