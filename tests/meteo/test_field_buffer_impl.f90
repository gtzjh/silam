submodule (field_buffer) test_field_buffer_impl
  implicit none

contains

  module subroutine test_project_level()
    implicit none
    
    integer, parameter :: nn = 41
    real, dimension(nn), parameter :: &
         & a = (/0.0, 2006.06, 3996.76, &
              & 5923.68, 7748.44, 9441.12, 10978.87, 12344.79, 13526.95, 14517.65, &
              & 15312.73, 15911.13, 16314.44, 16526.66, 16553.91, 16404.29, &
              & 16087.75, 15615.96, 15002.23, 14261.41, 13409.81, 12465.03, &
              & 11445.84, 10372.0, 9263.99, 8142.78, 7029.45, 5944.81, 4909.01, &
              & 3940.95, 3057.76, 2274.19, 1601.89, 1048.75, 618.02, 307.62, &
              & 109.2, 7.27, 0.0, 0.0, 0.0/), &
         
         & b = (/0.0, 0.0, 0.0, 0.0, 0.0, 0.01, 0.01, 0.02, 0.04, &
              0.05, 0.07, 0.09, 0.12, 0.15, 0.18, 0.22, 0.25, 0.29, 0.33, &
              0.38, 0.42, 0.46, 0.51, 0.55, 0.6, 0.64, 0.68, 0.72, 0.76, &
              0.79, 0.83, 0.86, 0.88, 0.91, 0.93, 0.95, 0.96, 0.97, 0.98, &
              0.99, 1.0/), &
              
         & sigma = (/0.0, 0.0197982940075, 0.0394449964396, &
                  & 0.0584622385405, 0.0764712387565, 0.103176709331, &
                  & 0.118353138057, 0.141833734724, 0.173500759262, &
                  & 0.193278218497, 0.221125056378, 0.247030811507, &
                  & 0.281011175981, 0.313105626772, 0.343374563649, &
                  & 0.381897927482, 0.408773917241, 0.444117706993, &
                  & 0.478060656366, 0.52074932362, 0.552344676114, &
                  & 0.583020412526, 0.622961778553, 0.652363790438, &
                  & 0.691428570284, 0.720363076119, 0.74937535159, &
                  & 0.778670775649, 0.808448213546, 0.828894193977, &
                  & 0.860177777078, 0.882444534186, 0.895809441985, &
                  & 0.920350368803, 0.936099389681, 0.953035976592, &
                  & 0.961077721357, 0.970071749398, 0.98, 0.99, 1.0/), &

         & height = (/0.0, 84.6887171594, 170.072974027, 255.545404244, &
                   & 333.588790243, 403.871373849, 553.477455535, 694.573138588, &
                   & 918.38286538, 1042.36468223, 1252.34487713, 1554.91984704, &
                   & 1757.70821799, 2060.60802189, 2367.90049014, 2681.96431296, &
                   & 3005.55876162, 3460.31113724, 3817.35648327, 4324.91930179, &
                   & 4734.21990025, 5175.50764187, 5807.54162922, 6343.58410412, &
                   & 6938.24363648, 7418.97056005, 8158.22902535, 8787.79381827, &
                   & 9511.66176116, 10355.0912502, 11063.805252, 11917.3727792, &
                   & 12601.9425516, 13879.9469436, 15027.6700619, 15897.9287197, &
                   & 17797.4242392, 19500.3626345, 22004.8436445, 26461.4559563, 100000.0/), &

         & p = (/101324.891894, 100311.642975, 99298.3940561, 98292.4151372, &
              & 97381.0962182, 96566.2672993, 94850.1694614, 93254.4016235, &
              & 90767.7948667, 89413.5970288, 87157.420272, 83987.6145963, &
              & 81915.9278394, 78898.7321637, 75930.3764879, 72990.7108122, &
              & 70058.9251364, 66100.6905417, 63121.5348659, 59074.4802712, &
              & 55966.2645955, 52764.8689197, 48439.444325, 45000.1786493, &
              & 41418.9729735, 38695.7662167, 34792.3905409, 31725.3937841, &
              & 28473.4270273, 25030.3702705, 22405.4724326, 19583.8945947, &
              & 17579.9456758, 14371.2878379, 11992.1189189, 10454.3689189, 7748.44, &
              & 5923.68, 3996.76, 2006.06, 0.0/)

    real, dimension(12) :: hgts = (/0.0, 50.0, 150.0, 300.0, 600.0, 1200.0, &
                                 & 2000.0, 3000.0, 4000.0, 5000.0, 6500.0, 8000.0/)

    real, dimension(12) :: p_small = (/101324.891894, 100725.675485, &
                                    & 99535.850101, 97772.4728, 94321.5833835, 87715.4879072, &
                                    & 79495.1305577, 70108.4696855, 61640.1693196, 54019.8542264, &
                                    & 44034.7988733, 35599.7731748/)

    real, dimension(nn) :: dummy_array
    real :: dummy
    real, parameter :: p_surf = 101324.891894
    integer :: iz, q2d, q3d
    real, dimension(:), pointer :: metdata

    type(silam_vertical) :: vert_hybrid, vert_sigma, vert_press, vert_hgt_small, vert_hgt, vert_press_small
    type(silja_level), dimension(nn) :: levels
    type(silja_level) :: lev
    real :: float
    do iz = 1, nn
      levels(iz) = fu_set_level(hybrid, fval1=a(iz), fval2=b(iz))
    end do
    call set_vertical(levels, vert_hybrid)
    call arrange_levels_in_vertical(vert_hybrid)

    do iz = 1, nn
      levels(iz) = fu_set_level(sigma_level, fval1=sigma(iz))
    end do
    call set_vertical(levels, vert_sigma)
    call arrange_levels_in_vertical(vert_sigma)
    
    do iz = 1, nn
      levels(iz) = fu_set_level(constant_pressure, fval1=p(iz))
    end do
    call set_vertical(levels, vert_press)
    call arrange_levels_in_vertical(vert_press)
    
    do iz = 1, size(hgts) 
      levels(iz) = fu_set_level(constant_height, fval1=hgts(iz))
    end do
    call set_vertical(levels(1:12), vert_hgt_small)
    call arrange_levels_in_vertical(vert_hgt_small)

    do iz = 1, nn
      levels(iz) = fu_set_level(constant_height, fval1=height(iz))
    end do
    call set_vertical(levels, vert_hgt)
    call arrange_levels_in_vertical(vert_hgt)

    do iz = 1, 12
      levels(iz) = fu_set_level(constant_pressure, fval1=p_small(iz))
    end do
    call set_vertical(levels(1:12), vert_press_small)
    print *, 'to arr'
    call arrange_levels_in_vertical(vert_press_small)
    print *, 'from arr'
    !print *, 'Project hybrid(1) to hybrid', &
    !     & fu_project_level(fu_level(vert_hybrid, 1), vert_hybrid, dummy_array, p_surf)
    float = fu_project_level(fu_level(vert_hybrid, 1), vert_hybrid, dummy_array, p_surf)
    print *, 'foo', fu_project_level(fu_level(vert_hybrid, 1), vert_hybrid, dummy_array, p_surf)
    print *, 'Project hybrid(3) to hybrid', &
         & fu_project_level(fu_level(vert_hybrid, 3), vert_hybrid, dummy_array, p_surf)

    
    print *, 'Project height(2) to hybrid', &
         & fu_project_level(fu_level(vert_hgt_small, 2), vert_hybrid, height, dummy)
    ! 1.59 seems to be correct
    
    print *, 'Project height(8) to hybrid', &
         & fu_project_level(fu_level(vert_hgt_small, 8), vert_hybrid, height, dummy)
    ! ~17 is ok
    
    print *, 'Project height(8) to sigma', &
         & fu_project_level(fu_level(vert_hgt_small, 8), vert_sigma, height, dummy)
    
    print *, 'Project 850 hPa to hybrid', &
         & fu_project_level(fu_set_level(constant_pressure, fval1=85000.0), &
                          & vert_hybrid, dummy_array, p_surf)
    ! should be about 11.68
    
    print *, 'Project 850 hPa to big height', &
         & fu_project_level(fu_set_level(constant_pressure, fval1=85000.0), &
                          & vert_hgt, p, dummy)
    ! should be the same

    print *, 'Project hybrid(2) to small height', &
         & fu_project_level(fu_level(vert_hybrid, 2), vert_hgt_small, p_small, p_surf)
    ! hybrid(2) == 84.688717 m => ~2.347
    
    print *, 'Project sigma(2) to small height', &
         & fu_project_level(fu_level(vert_sigma, 2), vert_hgt_small, p_small, p_surf)
    ! should be the same
    
    print *, 'Testing input needs'
    call projection_input_needs(vert_hgt, vert_hybrid, q3d, q2d)
    print *, 'height to hybrid:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)
    
    call projection_input_needs(vert_hybrid, vert_hybrid, q3d, q2d)
    print *, 'hybrid to hybrid:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hybrid, vert_hgt, q3d, q2d)
    print *, 'hybrid to height:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hybrid, vert_sigma, q3d, q2d)
    print *, 'hybrid to sigma:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hgt, vert_sigma, q3d, q2d)
    print *, 'height to sigma:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hgt, vert_press, q3d, q2d)
    print *, 'height to pressure:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hybrid, vert_press, q3d, q2d)
    print *, 'hybrid to pressure:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    !.....

    print *, 'Testing crude interpolation'
    metdata => fu_work_array()
    call vert_interp_data_crude(vert_hybrid, vert_press, metdata, dummy)
    print *, 'Surface pressure:', dummy
    call vert_interp_data_crude(vert_hgt, vert_hybrid, metdata, dummy)
    print *, 'Heights:', metdata(1:nn)
    call vert_interp_data_crude(vert_hybrid, vert_hgt, metdata, dummy)
    print *, 'Pressures:', metdata(1:nn)
    call free_work_array(metdata)

  end subroutine test_project_level

  module subroutine test_project_level_thick()
    implicit none
    
    integer, parameter :: nn = 41
    real, dimension(nn), parameter :: &
         & a = (/0.0, 2006.06, 3996.76, &
              & 5923.68, 7748.44, 9441.12, 10978.87, 12344.79, 13526.95, 14517.65, &
              & 15312.73, 15911.13, 16314.44, 16526.66, 16553.91, 16404.29, &
              & 16087.75, 15615.96, 15002.23, 14261.41, 13409.81, 12465.03, &
              & 11445.84, 10372.0, 9263.99, 8142.78, 7029.45, 5944.81, 4909.01, &
              & 3940.95, 3057.76, 2274.19, 1601.89, 1048.75, 618.02, 307.62, &
              & 109.2, 7.27, 0.0, 0.0, 0.0/), &
         
         & b = (/0.0, 0.0, 0.0, 0.0, 0.0, 0.01, 0.01, 0.02, 0.04, &
              0.05, 0.07, 0.09, 0.12, 0.15, 0.18, 0.22, 0.25, 0.29, 0.33, &
              0.38, 0.42, 0.46, 0.51, 0.55, 0.6, 0.64, 0.68, 0.72, 0.76, &
              0.79, 0.83, 0.86, 0.88, 0.91, 0.93, 0.95, 0.96, 0.97, 0.98, &
              0.99, 1.0/), &
              
         & sigma = (/0.0, 0.0197982940075, 0.0394449964396, &
                  & 0.0584622385405, 0.0764712387565, 0.103176709331, &
                  & 0.118353138057, 0.141833734724, 0.173500759262, &
                  & 0.193278218497, 0.221125056378, 0.247030811507, &
                  & 0.281011175981, 0.313105626772, 0.343374563649, &
                  & 0.381897927482, 0.408773917241, 0.444117706993, &
                  & 0.478060656366, 0.52074932362, 0.552344676114, &
                  & 0.583020412526, 0.622961778553, 0.652363790438, &
                  & 0.691428570284, 0.720363076119, 0.74937535159, &
                  & 0.778670775649, 0.808448213546, 0.828894193977, &
                  & 0.860177777078, 0.882444534186, 0.895809441985, &
                  & 0.920350368803, 0.936099389681, 0.953035976592, &
                  & 0.961077721357, 0.970071749398, 0.98, 0.99, 1.0/), &

         & height = (/0.0, 84.6887171594, 170.072974027, 255.545404244, &
                   & 333.588790243, 403.871373849, 553.477455535, 694.573138588, &
                   & 918.38286538, 1042.36468223, 1252.34487713, 1554.91984704, &
                   & 1757.70821799, 2060.60802189, 2367.90049014, 2681.96431296, &
                   & 3005.55876162, 3460.31113724, 3817.35648327, 4324.91930179, &
                   & 4734.21990025, 5175.50764187, 5807.54162922, 6343.58410412, &
                   & 6938.24363648, 7418.97056005, 8158.22902535, 8787.79381827, &
                   & 9511.66176116, 10355.0912502, 11063.805252, 11917.3727792, &
                   & 12601.9425516, 13879.9469436, 15027.6700619, 15897.9287197, &
                   & 17797.4242392, 19500.3626345, 22004.8436445, 26461.4559563, 100000.0/), &

         & p = (/101324.891894, 100311.642975, 99298.3940561, 98292.4151372, &
              & 97381.0962182, 96566.2672993, 94850.1694614, 93254.4016235, &
              & 90767.7948667, 89413.5970288, 87157.420272, 83987.6145963, &
              & 81915.9278394, 78898.7321637, 75930.3764879, 72990.7108122, &
              & 70058.9251364, 66100.6905417, 63121.5348659, 59074.4802712, &
              & 55966.2645955, 52764.8689197, 48439.444325, 45000.1786493, &
              & 41418.9729735, 38695.7662167, 34792.3905409, 31725.3937841, &
              & 28473.4270273, 25030.3702705, 22405.4724326, 19583.8945947, &
              & 17579.9456758, 14371.2878379, 11992.1189189, 10454.3689189, 7748.44, &
              & 5923.68, 3996.76, 2006.06, 0.0/)

    real, dimension(12) :: hgts = (/0.0, 50.0, 150.0, 300.0, 600.0, 1200.0, &
                                 & 2000.0, 3000.0, 4000.0, 5000.0, 6500.0, 8000.0/)

    real, dimension(12) :: p_small = (/101324.891894, 100725.675485, &
                                    & 99535.850101, 97772.4728, 94321.5833835, 87715.4879072, &
                                    & 79495.1305577, 70108.4696855, 61640.1693196, 54019.8542264, &
                                    & 44034.7988733, 35599.7731748/)

    real, dimension(nn) :: dummy_array
    real :: dummy
    real, parameter :: p_surf = 101324.891894
    integer :: iz, q2d, q3d
    real, dimension(:), pointer :: metdata

    type(silam_vertical) :: vert_hybrid, vert_sigma, vert_press, vert_hgt_small, vert_hgt, vert_press_small
    type(silja_level), dimension(nn) :: levels
    type(silja_level) :: lev, top, bottom
    real :: float

    do iz = 1, nn-1
      top = fu_set_level(hybrid, fval1=a(iz), fval2=b(iz))      
      bottom = fu_set_level(hybrid, fval1=a(iz+1), fval2=b(iz+1))
      levels(iz) = fu_set_layer_between_two(top, bottom)
    end do
    call set_vertical(levels, vert_hybrid)
    call arrange_levels_in_vertical(vert_hybrid)

    do iz = 1, nn-1
      bottom = fu_set_level(sigma_level, fval1=sigma(iz+1))
      top = fu_set_level(sigma_level, fval1=sigma(iz))
      levels(iz) = fu_set_layer_between_two(top, bottom)
    end do
    call set_vertical(levels, vert_sigma)
    call arrange_levels_in_vertical(vert_sigma)
    
    do iz = 1, nn-1
      top = fu_set_level(constant_pressure, fval1=p(iz+1))
      bottom = fu_set_level(constant_pressure, fval1=p(iz))
      levels(iz) = fu_set_layer_between_two(top, bottom)
    end do
    call set_vertical(levels, vert_press)
    call arrange_levels_in_vertical(vert_press)

    ! some arrays go up->down, some go down->up, sorry.
    do iz = 1, size(hgts) - 1
      top = fu_set_level(constant_height, fval1=hgts(iz+1))
      bottom = fu_set_level(constant_height, fval1=hgts(iz))
      levels(iz) = fu_set_layer_between_two(top, bottom)
    end do
    call set_vertical(levels(1:11), vert_hgt_small)
    call arrange_levels_in_vertical(vert_hgt_small)

    do iz = 1, nn-1
      top = fu_set_level(constant_height, fval1=height(iz+1))
      bottom = fu_set_level(constant_height, fval1=height(iz))
      levels(iz) = fu_set_layer_between_two(top, bottom)
    end do
    call set_vertical(levels, vert_hgt)
    call arrange_levels_in_vertical(vert_hgt)

    do iz = 1, 12-1
      top = fu_set_level(constant_pressure, fval1=p_small(iz+1))
      bottom = fu_set_level(constant_pressure, fval1=p_small(iz))
      levels(iz) = fu_set_layer_between_two(top, bottom)
    end do
    call set_vertical(levels(1:11), vert_press_small)
    print *, 'to arr'
    call arrange_levels_in_vertical(vert_press_small)
    print *, 'from arr, thick'
    !print *, 'Project hybrid(1) to hybrid', &
    !     & fu_project_level(fu_level(vert_hybrid, 1), vert_hybrid, dummy_array, p_surf)
    float = fu_project_level(fu_level(vert_hybrid, 1), vert_hybrid, dummy_array, p_surf)
    print *, 'out'
    print *, 'foo', fu_project_level(fu_level(vert_hybrid, 1), vert_hybrid, dummy_array, p_surf)
    print *, 'Project hybrid(3) to hybrid', &
         & fu_project_level(fu_level(vert_hybrid, 3), vert_hybrid, dummy_array, p_surf)

    
    print *, 'Project height(2) to hybrid', &
         & fu_project_level(fu_level(vert_hgt_small, 2), vert_hybrid, height, dummy)
    ! 1.59 seems to be correct
    
    print *, 'Project height(8) to hybrid', &
         & fu_project_level(fu_level(vert_hgt_small, 8), vert_hybrid, height, dummy)
    ! ~17 is ok
    
    print *, 'Project height(8) to sigma', &
         & fu_project_level(fu_level(vert_hgt_small, 8), vert_sigma, height, dummy)
    
    print *, 'Project 850 hPa to hybrid', &
         & fu_project_level(fu_set_level(constant_pressure, fval1=85000.0), &
                          & vert_hybrid, dummy_array, p_surf)
    ! should be about 11.68
    
    print *, 'Project 850 hPa to big height', &
         & fu_project_level(fu_set_level(constant_pressure, fval1=85000.0), &
                          & vert_hgt, p, dummy)
    ! should be the same

    print *, 'Project hybrid(2) to small height', &
         & fu_project_level(fu_level(vert_hybrid, 2), vert_hgt_small, p_small, p_surf)
    ! hybrid(2) == 84.688717 m => ~2.347
    
    print *, 'Project sigma(2) to small height', &
         & fu_project_level(fu_level(vert_sigma, 2), vert_hgt_small, p_small, p_surf)
    ! should be the same
    
    print *, 'Testing input needs'
    call projection_input_needs(vert_hgt, vert_hybrid, q3d, q2d)
    print *, 'height to hybrid:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)
    
    call projection_input_needs(vert_hybrid, vert_hybrid, q3d, q2d)
    print *, 'hybrid to hybrid:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hybrid, vert_hgt, q3d, q2d)
    print *, 'hybrid to height:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hybrid, vert_sigma, q3d, q2d)
    print *, 'hybrid to sigma:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hgt, vert_sigma, q3d, q2d)
    print *, 'height to sigma:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hgt, vert_press, q3d, q2d)
    print *, 'height to pressure:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    call projection_input_needs(vert_hybrid, vert_press, q3d, q2d)
    print *, 'hybrid to pressure:', fu_quantity_short_string(q3d), ' ', fu_quantity_short_string(q2d)

    !.....

    print *, 'Testing crude interpolation'
    metdata => fu_work_array()
    call vert_interp_data_crude(vert_hybrid, vert_press, metdata, dummy)
    print *, 'Surface pressure:', dummy
    call vert_interp_data_crude(vert_hgt, vert_hybrid, metdata, dummy)
    print *, 'Heights:', metdata(1:nn)
    call vert_interp_data_crude(vert_hybrid, vert_hgt, metdata, dummy)
    print *, 'Pressures:', metdata(1:nn)
    call free_work_array(metdata)

  end subroutine test_project_level_thick

end submodule test_field_buffer_impl
