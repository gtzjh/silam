submodule (materials) test_materials_impl
  implicit none

contains

  module subroutine test_amount_units()
    implicit none
    character(len=2), parameter, dimension(5) :: mod_names = (/'mk', ' m', ' k', ' M', ' G'/)
    real, parameter, dimension(5) :: mod_values = (/1e-6, 1e-3, 1e3, 1e6, 1e9/)
    type(silam_material), pointer :: no2, i_131, pm
    real :: mole_to_bq
    character(len=*), parameter :: sub_name = 'test_amount_units'

    no2 => fu_get_material_ptr('NO2')
    if (error) return

    call msg('Testing unit conversions...')

    if (fu_fails(test_conversion('mole', 'g', no2, 46.0, .true.), 'Failed conversion', sub_name)) return
    if (fu_fails(test_conversion('mole', 'mole', no2, 1.0, .true.), 'Failed conversion', sub_name)) return
    if (fu_fails(test_conversion('g', 'g', no2, 1.0, .true.), 'Failed conversion', sub_name)) return
    
    if (fu_fails(test_conversion('ton', 'g', no2, 1e6, .false.), 'Failed conversion', sub_name)) return
    if (fu_fails(test_conversion('ton', 'kg', no2, 1e3, .false.), 'Failed conversion', sub_name)) return
    if (fu_fails(test_conversion('Mton', 'g', no2, 1e12, .false.), 'Failed conversion', sub_name)) return
    if (fu_fails(test_conversion('kton', 'g', no2, 1e9, .false.), 'Failed conversion', sub_name)) return

    pm => fu_get_material_ptr('PM')
    if (error) return
    call msg('Will test conversion for PM')
    if (fu_fails(test_conversion('g', 'g', pm, 1.0, .true.), 'Failed conversion', sub_name)) return
    
    ! Don't have molar mass or nuclide data, but mole->mole or Bq->Bq should still work!
    if (fu_fails(test_conversion('mole', 'mole', pm, 1.0, .true.), 'Failed conversion', sub_name)) return
    if (fu_fails(test_conversion('Bq', 'kBq', pm, 1e-3, .false.), 'Failed conversion', sub_name)) return
    
    call msg('** Expected failures:')
    if (fu_fails(.not.test_conversion('mole', 'g', pm, 46.0, .true.), 'Error not set', sub_name)) return
    if (fu_fails(.not.test_conversion('number', 'g', pm, 46.0, .true.), 'Error not set', sub_name)) return
    if (fu_fails(.not.test_conversion('hour', 'g', pm, 46.0, .true.), 'Error not set', sub_name)) return

    call unset_error(sub_name)

    i_131 => fu_get_material_ptr('I_131')
    if (error) return
    call msg('Will test conversion for I-131')
    if (fu_fails(test_conversion('mole', 'g', i_131, 131.0, .true.), 'Failed conversion', sub_name)) return
    mole_to_bq = fu_mole_to_bq(fu_nuclide(i_131), 1.0)
    ! some modifiers for Bq are not supported, test them separately:
    if (fu_fails(test_conversion('mole', 'Bq', i_131, mole_to_bq, .false.), 'Failed conversion', sub_name)) return
    if (fu_fails(test_conversion('mole', 'kBq', i_131, mole_to_bq*1e-3, .false.), &
               & 'Failed conversion', sub_name)) then
      return
    end if
    if (fu_fails(test_conversion('mmole', 'kBq', i_131, mole_to_bq*1e-6, .false.), &
               & 'Failed conversion', sub_name)) then
      return
    end if

  contains

    logical function test_conversion(unit1, unit2, material, expected, test_modifiers) result(ok)
      character(len=*), intent(in) :: unit1, unit2
      real, intent(in) :: expected
      type(silam_material), intent(in) :: material
      logical, intent(in) :: test_modifiers

      character(len=clen) :: unit1_mod, unit2_mod, mod1_name, mod2_name
      integer :: ind_mod1, ind_mod2, num_modifiers
      real :: mod_total_val, factor

      ok = .false.

      factor = fu_conversion_factor(unit1, unit2, material)
      if (.not. (factor .eps. expected)) then
        call msg('Expected:', expected)
        call msg('Obtained:', factor)
        call msg('Failed conversion: ' + unit1 + ' -> ' + unit2)
        return
      else
        call msg('OK: ' + unit1 + ' -> ' + unit2)
      end if
        
      factor  = fu_conversion_factor(unit2, unit1, material)
      if (.not. (factor .eps. 1/expected)) then
        call msg('Expected:', 1 / expected)
        call msg('Obtained:', factor)
        call msg('Failed conversion: ' + unit2 + ' -> ' + unit1)
        return
      else
        call msg('OK: ' + unit2 + ' -> ' + unit1)
      end if

      if (.not. test_modifiers) then
        ok = .true.
        return
      end if

      num_modifiers = size(mod_names)
      do ind_mod1 = 1, num_modifiers
        do ind_mod2 = 1, num_modifiers
          mod1_name = mod_names(ind_mod1)
          mod2_name = mod_names(ind_mod2)
          
          unit1_mod = trim(adjustl(mod1_name)) // trim(unit1)
          unit2_mod = trim(adjustl(mod2_name)) // trim(unit2)
          
          mod_total_val = mod_values(ind_mod1) / mod_values(ind_mod2)
      
          factor = fu_conversion_factor(unit1_mod, unit2_mod, material)
          if (.not. (factor .eps. expected * mod_total_val)) then
            call msg('Expected:', expected * mod_total_val)
            call msg('Obtained:', factor)
            call msg('Failed conversion: ' + unit1_mod + ' -> ' + unit2_mod)
            return
          else
            call msg('OK: ' + unit1_mod + ' -> ' + unit2_mod)
          end if
          
          factor  = fu_conversion_factor(unit2_mod, unit1_mod, material)
          if (.not. (factor .eps. 1 / (expected*mod_total_val))) then
            call msg('Expected:', 1 / (expected * mod_total_val))
            call msg('Obtained:', factor)
            call msg('Failed conversion: ' + unit2_mod + ' -> ' + unit1_mod)
            return
          else
            call msg('OK: ' + unit2_mod + ' -> ' + unit1_mod)
          end if
          
        end do
      end do

      ok = .true.
      
    end function test_conversion

  end subroutine test_amount_units

end submodule test_materials_impl
