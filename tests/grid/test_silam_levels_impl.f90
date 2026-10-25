submodule (silam_levels) test_silam_levels_impl
  implicit none

contains

  module SUBROUTINE level_tests()

    IMPLICIT NONE
    TYPE(silja_level) :: level1, level2

    level1 = pr_level_700hpa
    CALL report(level1)

    level2 = fu_set_pressure_level(85000.)
    CALL report(level2)

    IF (level1 < level2) THEN
      call msg('2 korkeammalla')
    ELSE
      call msg('1 korkeammalla')
    END IF

  END SUBROUTINE level_tests

  module subroutine test_overlap_fraction()
    implicit none
    real, dimension(5), parameter :: height_thin = (/0.0, 25.0, 50.0, 75., 100./)
    real, dimension(2), parameter :: height_thick = (/0.0, 1000./)
    real, dimension(2), parameter :: pressure = (/101324.89, 99298.39/)

    type(silja_level) :: top, bottom
    type(silja_level), dimension(5) :: levels
    type(silam_vertical) :: vert_hgt_thin, vert_hgt_thick, vert_press
    real :: fraction
    integer :: iz

    do iz = 1, 4
      bottom = fu_set_level(constant_height, fval1=height_thin(iz))
      top = fu_set_level(constant_height, fval1=height_thin(iz+1))
      levels(iz) = fu_set_layer_between_two(top, bottom)
    end do
    call set_vertical(levels, vert_hgt_thin)
    call arrange_levels_in_vertical(vert_hgt_thin)
    
    bottom = fu_set_level(constant_height, fval1=height_thick(1))
    top = fu_set_level(constant_height, fval1=height_thick(2))
    call set_vertical((/fu_set_layer_between_two(top, bottom)/), vert_hgt_thick)
    call arrange_levels_in_vertical(vert_hgt_thick)

    bottom = fu_set_level(constant_pressure, fval1=pressure(1))
    top = fu_set_level(constant_pressure, fval1=pressure(2))
    call set_vertical((/fu_set_layer_between_two(top, bottom)/), vert_press)
    call arrange_levels_in_vertical(vert_press)

    fraction = fu_vert_overlap_fraction(fu_level(vert_hgt_thin, 1), &
                                         & fu_level(vert_hgt_thick, 1))
    print *, 'fraction of hgt_thin(1) and hgt_thick(1)', fraction

    fraction = fu_vert_overlap_fraction(fu_level(vert_hgt_thick, 1), &
                                         & fu_level(vert_hgt_thin, 1))
    print *, 'fraction of hgt_thick(1) and hgt_thin(1)', fraction

    fraction = fu_vert_overlap_fraction(fu_level(vert_press, 1), &
                                         & fu_level(vert_hgt_thin, 1))
    print *, 'fraction of pressure(1) and hgt_thin(1)', fraction

    fraction = fu_vert_overlap_fraction(fu_level(vert_hgt_thick, 1), &
                                         & fu_level(vert_press, 1))
    print *, 'fraction of hgt_thick(1) and pressure(1)', fraction ! should ~170

  end subroutine test_overlap_fraction

  module subroutine test_vert_to_metric()
    implicit none
    real, dimension(4) :: hyb_a = (/0.0, 0.0, 0.0, 783.0/), &
         & hyb_b = (/1.0, 0.992, 0.973, 0.929/), hyb_lev_press, lev_hgt
    type(silja_level), dimension(4) :: levels
    type(silja_level), dimension(3) :: layers
 
    character(len=*), parameter :: sub_name = 'test_vert_to_metric'
    type(silja_level) :: top, bottom
    type(silam_vertical) :: vert_hyb_thick, vert_m, vert_press
    real :: height_from_vert
    integer :: iz

    hyb_lev_press = hyb_a + std_pressure_sl*hyb_b
    lev_hgt = (/(fu_height_for_press(hyb_lev_press(iz)), iz=1, 4)/)

    ! hybrid to height, layers
    do iz = 1, 3
      bottom = fu_set_level(hybrid, hyb_a(iz), hyb_b(iz))
      top = fu_set_level(hybrid, hyb_a(iz+1), hyb_b(iz+1))
      layers(iz) = fu_set_layer_between_two(bottom, top)
    end do
    call set_vertical(layers, vert_hyb_thick)
    call arrange_levels_in_vertical(vert_hyb_thick)
    
    call msg('*** hybrid thick layers to metric ***')
    call vert_to_metric(vert_hyb_thick, vert_m)
    do iz = 1, 3
      bottom = fu_lower_boundary_of_layer(fu_level(vert_m, iz))
      height_from_vert = fu_level_height(bottom)
      if (fu_fails(height_from_vert .eps. lev_hgt(iz), 'Heights differ', sub_name)) continue
      call msg('heights (lower):', height_from_vert, lev_hgt(iz))
      height_from_vert = fu_level_height(fu_level(vert_m,iz,.true.))
      if (fu_fails(height_from_vert .eps. 0.5*(lev_hgt(iz) + lev_hgt(iz+1)), 'Heights differ', sub_name)) continue
      call msg('heights (mid):', height_from_vert, 0.5*(lev_hgt(iz) + lev_hgt(iz+1)))
    end do
    
    ! pressure to height, levels
    
    do iz = 1, 4
      levels(iz) = fu_set_level(constant_pressure, hyb_lev_press(iz))
    end do
    call set_vertical(levels, vert_press)
    call arrange_levels_in_vertical(vert_press)
    call msg('*** pressure levels to metric ***')
    call vert_to_metric(vert_press, vert_m)
    do iz = 1, 4
      height_from_vert = fu_level_height(fu_level(vert_m, iz))
      if (fu_fails(height_from_vert .eps. lev_hgt(iz), 'Heights differ', sub_name)) continue
      call msg('heights:', height_from_vert, lev_hgt(iz))
    end do
    
  end subroutine test_vert_to_metric

  module subroutine test_vert_to_pressure()
    implicit none
    real, dimension(4) :: hyb_a = (/0.0, 0.0, 0.0, 783.0/), &
         & hyb_b = (/1.0, 0.992, 0.973, 0.929/), hyb_lev_press, lev_hgt
    type(silja_level), dimension(4) :: levels
    type(silja_level), dimension(3) :: layers
    type(silam_vertical) :: vert_hyb_thick, vert_m, vert_press
    type(silja_level) :: top, bottom
    character(len=*), parameter :: sub_name = 'test_vert_to_pressure'
    integer :: iz

    lev_hgt = (/0.0, 1500.0, 25000.0, 50000.0/)
    
    ! height to pressure, levels
    do iz = 1, 4
      levels(iz) = fu_set_level(constant_height, lev_hgt(iz))
    end do
    call set_vertical(levels, vert_m)
    call arrange_levels_in_vertical(vert_m)
    call msg('*** metric to pressure ***')
    call vert_to_pressure(vert_m, vert_press)
    call report(vert_press, .true.)
    
    ! hybrid to pressure, layers
    do iz = 1, 3
      bottom = fu_set_level(hybrid, hyb_a(iz), hyb_b(iz))
      top = fu_set_level(hybrid, hyb_a(iz+1), hyb_b(iz+1))
      call msg('Bottom', iz, fu_hybrid_level_pressure(bottom, std_pressure_sl))
      call msg('Top', iz, fu_hybrid_level_pressure(top, std_pressure_sl))
      layers(iz) = fu_set_layer_between_two(bottom, top)
    end do
    call set_vertical(layers, vert_hyb_thick)
    call arrange_levels_in_vertical(vert_hyb_thick)
    call msg('*** hybrid to pressure ***')
    call vert_to_pressure(vert_hyb_thick, vert_press)
    call report(vert_press, .true.)

  end subroutine test_vert_to_pressure

end submodule test_silam_levels_impl
