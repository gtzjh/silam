submodule (source_terms_dms) test_source_terms_dms_impl
contains
  
  module subroutine test_dmssrc_no_init()
    implicit none
    
    type(silam_dms_source) :: dmssrc
    type(silja_grid) :: grid
    
    grid = fu_set_lonlat_grid('grid', -10.0, 12.0, .true., 200, 300, pole_geographical, 0.2, 0.2)
    if (error) return
    
    dmssrc%map_dms_filename = 'dms_lana_2011.nc'
    dmssrc%map_dms_fileformat = fu_input_file_format('NETCDF:dms_clim')
    dmssrc%water_mask_filename = 'sslt_emission_global_50km.fld.nc'
    dmssrc%water_mask_fileformat = fu_input_file_format('NETCDF:dms_clim')
    dmssrc%emis_subst_name = 'DMS'
    call msg('Testing DMS source')

    call init_emission_dms(dmssrc, grid)

    call test_dmssrc(dmssrc)

  end subroutine test_dmssrc_no_init
  
  module subroutine test_dmssrc(dmssrc)
    implicit none
    type(silam_dms_source), intent(inout) :: dmssrc
    
    integer :: month
    type(silam_vertical) :: vert

    call set_vertical(fu_set_layer_between_two(layer_btw_2_height, 0.0, 12.5), vert)
    call add_level(vert, fu_set_layer_between_two(layer_btw_2_height, 12.5, 25.0))
    call add_level(vert, fu_set_layer_between_two(layer_btw_2_height, 25.0, 50.0))
    
    call project_dmssrc_second_grd(dmssrc, dmssrc%grid, vert, vert, 5)
    if (error) return
    call msg('Level fractions:', dmssrc%levFractDispVert)
    call msg('fzdisp:', dmssrc%fzDisp)

    call report(dmssrc)

    do month = 1, 12
      call msg('month:', month)
      call open_binary(99, file=trim(fu_str(month)) // '.dat', access='stream', recl=0)
      write(99) dmssrc%map_dms(month, :, :)
      call msg('maxval:', maxval(dmssrc%map_dms(month,:,:)))
      call msg('minval:', minval(dmssrc%map_dms(month,:,:)))
    end do
    
    call msg('u sst dms:', (/5.0, 285.0, 5.0e-9/))
    call msg('flux:', test_bind_get_flux_dms(5.0, 285.0, 5e-9) * 1e6 * 24*3600)
    call msg('flux mgS/year/m2:', test_bind_get_flux_dms(5.0, 285.0, 5e-9) * 1000 * 32 * 3600*24*365)
    call msg('kw cm/h', test_bind_get_flux_dms(15.0, 285.0, 1.0) * 3600 * 100 / 1000)
    
  end subroutine test_dmssrc

  module subroutine test_init_dmssrc(filename)
    implicit none
    character(len=*), intent(in) :: filename
    
    type(Tsilam_namelist), pointer :: nlptr
    type(silam_dms_source) :: dmssrc
    type(silja_grid) :: grid
    integer :: file_unit, iostat
    character(len=500) :: line
    logical :: eof

    file_unit = fu_next_free_unit()
    open(file_unit, file=filename, action='read', status='old', iostat=iostat)
    if (fu_fails(iostat == 0, 'bad iostat', '')) return
    call next_line_from_input_file(file_unit, line, eof)
    print *, line
    nlptr => fu_read_namelist(file_unit, chStopLine='END_DMS_SOURCE_V5', ifenv=.true.)
    call report(nlptr)
    close(file_unit)
    
    call fill_dms_src_from_namelist(nlptr, dmssrc, fu_dirname(filename))
    if (error) return
    grid = fu_set_lonlat_grid('grid', -10.0, 12.0, .true., 200, 300, pole_geographical, 0.2, 0.2)
    call init_emission_dms(dmssrc, grid)
    
    call test_dmssrc(dmssrc)
    
  end subroutine test_init_dmssrc

end submodule test_source_terms_dms_impl
