submodule (correlations) test_correlations_impl
  implicit none
contains

  module subroutine test_correlations(distance, nlptr, correlation, surface_only)
    implicit none
    real, intent(in) :: distance
    type(Tsilam_namelist), pointer :: nlptr
    type(t_spatial_correlation), intent(out) :: correlation
    logical, intent(in) :: surface_only

    type(silja_grid) :: grid
    integer :: ilev, nn, nc
    character(len=80) :: distance_str
    type(t_spatial_correlation), dimension(:), pointer :: corr_list_ptr
    type(t_correlation) :: total_correlation

    real, dimension(:), allocatable :: val1, val2, val3, val1p, val2c

    write(distance_str, '(F8.1, A)') distance, ' deg'

    nlptr => fu_create_namelist()
    call add_namelist_item(nlptr, 'correlation_method', 'decomposition')
    call add_namelist_item(nlptr, 'correlation_distance_x', distance_str)
    call add_namelist_item(nlptr, 'correlation_distance_y', distance_str)
    
    if (surface_only) then
      call add_namelist_item(nlptr, 'vertical_method', 'SURFACE_LEVEL')
      call add_namelist_item(nlptr, 'vert_correlation', '1 1.0')
    else
      call add_namelist_item(nlptr, 'number_of_levels', '3')
      call add_namelist_item(nlptr, 'vertical_method', 'CUSTOM_LAYERS')
      call add_namelist_item(nlptr, 'layer_thickness', '50. 100. 150.')
      call add_namelist_item(nlptr, 'level_type', 'HEIGHT_FROM_SURFACE')

      call add_namelist_item(nlptr, 'vert_correlation', '1 1.0 0.5 0.1')
      call add_namelist_item(nlptr, 'vert_correlation', '2 0.5 1.0 0.2')
      call add_namelist_item(nlptr, 'vert_correlation', '3 0.1 0.2 1.0')
    end if
    !call add_namelist_item(nlptr, 'vert_correlation', '1 1.0 0.0 0.0')
    !call add_namelist_item(nlptr, 'vert_correlation', '2 0.0 1.0 0.0')
    !call add_namelist_item(nlptr, 'vert_correlation', '3 0.0 0.0 1.0')


    grid = fu_set_lonlat_grid('testgrid', 20.0, 40.0, .true., 20, 20, pole_geographical, 0.5, 0.5)

    if (error) return
    
    call test_bind_set_corr_from_nl_decomp(nlptr, grid, grid, correlation)
    if (error) return
    
    allocate(corr_list_ptr(1))
    corr_list_ptr(1) = correlation
    call set_total_correlation(corr_list_ptr, grid, correlation%vertical, 1, total_correlation)

    nn = fu_dimension_physical(total_correlation)
    nc = fu_dimension_control(total_correlation)
    allocate(val1(nn), val2(nn), val3(nn), val1p(nn), val2c(nn))
    call random_number(val1)
    call random_number(val2)
    val3 = val1
    call transf_fwd(total_correlation, val1, val1p)
    call msg('left:', sum(val1p*val2))
    call transf_adj(total_correlation, val2, val2c)
    call msg('right:', sum(val3(1:nc)*val2c(1:nc)))
    ! note values of val1, val2 are now invalid!
  end subroutine test_correlations


  module subroutine test_correlations_grid_vert_given(distance, nlptr, correlation, grid, vertical)
    implicit none
    real, intent(in) :: distance

    type(t_spatial_correlation), intent(out) :: correlation
    type(silja_grid), intent(in) :: grid
    type(silam_vertical), intent(in) :: vertical

    integer :: ilev, nn, nc, tempfile_unit, iostat, nlevs
    character(len=255) :: distance_str, corr_line
    
    real, dimension(:), allocatable :: val1, val2, val3, val1p, val2c
    real, dimension(:), pointer :: corr
    type(Tsilam_namelist), pointer :: nlptr, nl_vertical
    type(t_correlation) :: total_correlation
    type(t_spatial_correlation), dimension(:), pointer :: corr_list_ptr

    write(distance_str, '(F8.1, A)') distance, ' deg'

    !nlptr => fu_create_namelist()


    tempfile_unit = fu_next_free_unit()
    open(unit=tempfile_unit, status='SCRATCH', iostat=iostat)
    if (fu_fails(iostat == 0, 'Tempfile creation failed', 'test_correlations_grid_vert_given')) return
    call report_as_namelist(vertical, tempfile_unit)
    rewind(tempfile_unit)
    nl_vertical => fu_read_namelist(tempfile_unit, .false.)
    if (fu_fails(associated(nl_vertical), 'Failed to read vert namelist', 'test_correlations_etc')) return
    close(tempfile_unit)

    nlptr => nl_vertical
    call add_namelist_item(nlptr, 'correlation_method', 'decomposition')
    call add_namelist_item(nlptr, 'correlation_distance_x', distance_str)
    call add_namelist_item(nlptr, 'correlation_distance_y', distance_str)
    
    
    !call add_namelist_item(nlptr, 'number_of_levels', '3')
    !call add_namelist_item(nlptr, 'vertical_method', 'CUSTOM_LAYERS')
    !call add_namelist_item(nlptr, 'layer_thickness', '50. 100. 150.')
    !call add_namelist_item(nlptr, 'level_type', 'HEIGHT_FROM_SURFACE')
    nlevs = fu_NbrOfLevels(vertical)
    corr => fu_work_array(nlevs)
    do ilev = 1, nlevs
      corr(1:nlevs) = 0.0
      corr(ilev) = 1.0
      if (ilev > 1) corr(ilev-1) = 0.5
      if (ilev < nlevs) corr(ilev+1) = 0.5
      write(corr_line, fmt='(I4, 100F4.1)') ilev, corr(1:nlevs)
      call add_namelist_item(nlptr, 'vert_correlation', corr_line)
    end do
    call free_work_array(corr)
    !grid = fu_set_lonlat_grid('testgrid', 20.0, 40.0, .true., 20, 20, pole_geographical, 0.5, 0.5)

    if (error) return
    
    call test_bind_set_corr_from_nl_decomp(nlptr, grid, grid, correlation)
    if (error) return
    if (fu_fails(fu_cmp_verts_eq(correlation%vertical, vertical), 'Vertical changed', 'test_correlations')) return

    allocate(corr_list_ptr(1))
    corr_list_ptr(1) = correlation
    call set_total_correlation(corr_list_ptr, grid, vertical, 1, total_correlation)
    nn = fu_dimension_physical(total_correlation)
    nc = fu_dimension_control(total_correlation)
    allocate(val1(nn), val2(nn), val3(nn), val1p(nn), val2c(nn))
    call random_number(val1)
    call random_number(val2)
    val3 = val1
    call transf_fwd(total_correlation, val1, val1p)
    ! val1 is lost now
    call msg('left:', sum(val1p*val2))
    call transf_adj(total_correlation, val2, val2c)
    ! val2 now lost
    call msg('right:', sum(val3(1:nc)*val2c(1:nc)))
  end subroutine test_correlations_grid_vert_given

end submodule test_correlations_impl
