submodule (chemical_setup) test_chemical_setup_impl
  implicit none

contains

  module subroutine chemical_setup_tests(nlSetup)
    implicit none
    type(Tsilam_namelist), pointer :: nlSetup
    type(silam_species) :: species1, species2, species3
    type(silam_species), dimension(500), target :: species_list
    type(Taerosol_mode) :: small, big, strange

    integer :: nspecies = 0, i, j, k, bignum = 100
    type(chemical_mapper) :: mapper
    logical :: ifSpecies
    type(Tcocktail_descr) :: descr1

    type(silam_species), dimension(:), pointer :: species_list_ptr

    species_list_ptr => species_list

    call init_chemical_materials(fu_expand_environment(fu_content(nlSetup,'chemical_database_fnm')), &
                               & fu_expand_environment(fu_content(nlSetup,'nuclide_database_fnm')))

    !small = fu_set_mode(.5e-6, .9e-6, .1e-6, 1.e3)
    !big = fu_set_mode(5.0e-6, 10.0e-6, 2.5e-6, 1.e3)
   
    call set_species(species1, fu_get_material_ptr('passive'), small)
    call set_species(species2, fu_get_material_ptr('passive'), in_gas_phase)
    call set_species(species3, fu_get_material_ptr('generic_aerosol'), big)
    call report(species1)
    call report(species2)
    call report(species3)

    call addSpecies(species_list_ptr, nspecies, (/species1/), 1)
    print *, nspecies
    call addSpecies(species_list_ptr, nspecies, (/species2, species3, species3/), 3)
    print *, nspecies
    print *, ''
    do i = 1, nspecies
      call report(species_list(i))
    end do
    
    call create_chemical_mapper(species_list, mapper, nspecies)
    
    do i = 1, fu_nsubst(mapper)
      do j = 1, fu_nmodes(i, mapper)
        print *, i, j, fu_isp(i,j,1,mapper), fu_nwaves(1,j,mapper)
      end do
    end do

    call msg('1 OK')
    
    ! a stress test
    do i = bignum, 1, -1
      call set_species(species_list(i), &
                     fu_get_material_ptr('generic_aerosol'), &
                     & fu_set_mode(fixed_diameter_flag, &
                                 & i*1.0e-8+1e-9, i*1.0e-8-1e-9, 1.e3))
      if (error) return
    end do
    nspecies = bignum
    call addSpecies(species_list_ptr, nspecies, (/species2/), 1)
    
    call free_chemical_mapper(mapper)
    do i = 1, 100
      !call msg('i = ', i)
      call create_chemical_mapper(species_list, mapper, nSpecies)
      call free_chemical_mapper(mapper)
    end do

    call msg('2 OK')

    call create_chemical_mapper(species_list, mapper, nSpecies)

    do i = 1, fu_nsubst(mapper)
      do j = 1, fu_nmodes(i, mapper)
        call report(species_list(fu_isp(i,j,1,mapper)))
      end do
    end do

    call msg('3 OK')
    
    ! try some wavelengths
    call set_species(species_list(1), fu_get_material_ptr('passive'), small, 550.0e-9)
    call set_species(species_list(2), fu_get_material_ptr('passive'), in_gas_phase, 550.0e-9)
    call set_species(species_list(3), fu_get_material_ptr('generic_aerosol'), big, 550.0e-9)
    call set_species(species_list(4), fu_get_material_ptr('generic_aerosol'), big, 650.0e-9)
    call set_species(species_list(5), fu_get_material_ptr('generic_aerosol'), big, 750.0e-9)
    nspecies = 5
    call set_species(species1, fu_get_material_ptr('passive'), in_gas_phase, 650.0e-9)
    call set_species(species2, fu_get_material_ptr('passive'), small, 950.0e-9)
    call addspecies(species_list_ptr, nspecies, (/species1,species2,species1/), 3)
    
    do i = 1, nspecies
      call report(species_list(i))
    end do
    
    call create_chemical_mapper(species_list, mapper, nspecies)
    
    call msg('4 OK')

    do i = 1, fu_nsubst(mapper)
      do j = 1, fu_nmodes(i, mapper)
        do k = 1, fu_nwaves(i,j,mapper)
          call report(species_list(fu_isp(i,j,k,mapper)))
        end do
      end do
    end do

    ! descriptors

!    chCocktailDescrFile = '/home/vira/silam/silam_v4_6/ini/v4_6_test.cocktails'

    call set_cocktail_description('TEST_1', descr1, ifSpecies)
    call set_cocktail_description('TEST_2', descr1, ifSpecies)
    call set_cocktail_description('TEST_2', descr1, ifSpecies)

  end subroutine chemical_setup_tests

end submodule test_chemical_setup_impl
