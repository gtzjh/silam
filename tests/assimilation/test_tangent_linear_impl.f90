submodule (tangent_linear) test_tangent_linear_impl
  implicit none
contains

  module subroutine test_tl_structs()
    implicit none

    type(t_tla_trajectory) :: traj
    integer, parameter :: nx = 2, ny = 3, nz = 4,  nsteps = 200
    integer, parameter :: dim1 = 2, dim2=3, dim3=4
    integer :: ind_step, itry
    
    call add_tla_traj(dim1, traj, dim1)
    call add_tla_traj(dim2, traj, dim2)
    call add_tla_traj(dim3, traj, dim3)
    
    if (error) return

    call alloc_tla_trajs(traj, nx, ny, nz, nsteps, 6000_8, '.')

    if (error) return
    
    do itry=1,2
      do ind_step = 1, nsteps
        print *, 'Forward:', ind_step
        call prepare_tla_step(traj, ind_step)
        if (error) return
        call storeTLAbypoint(traj, ind_step, dim1)
        call storeTLAbypoint(traj, ind_step, dim2)
        call storeTLAbypoint(traj, ind_step, dim3)
      end do

      do ind_step = nsteps, 1, -1
        print *, 'Backwards:', ind_step
        call prepare_tla_step(traj, ind_step)
        if (error) return
        call checkTLAbycol(traj, ind_step, dim3)
        call checkTLAbycol(traj, ind_step, dim2)
        call checkTLAbycol(traj, ind_step, dim1)
      end do

    end do
    contains
       !*******************************************************
      
      subroutine storeTLAbypoint(traj, indstep, tag)
          implicit none
          type(t_tla_trajectory), intent(in) :: traj
          integer, intent(in) :: indstep, tag
          character(len = *), parameter :: sub_name = 'storeTLA'
          integer :: ix, iy, iz
          real, dimension(:), pointer :: storevec

          do iy = 1,ny
             do ix = 1,nx
               do iz = 1,nz
                  storevec => fu_get_tla_point(traj, tag, iz, ix, iy)
                  storevec(:) = real(tag + 10*(ix +10*(iy +10*(iz + 1000*indstep))))
               enddo
             enddo
          enddo
      end subroutine storeTLAbypoint

      subroutine checkTLAbycol(traj, indstep, tag)
          implicit none
          type(t_tla_trajectory), intent(in) :: traj
          integer, intent(in) :: indstep, tag
          character(len = *), parameter :: sub_name = 'storeTLA'
          integer :: ix, iy, iz
          real :: val
          real, dimension(:,:), pointer :: storevec

          do iy = 1,ny
             do ix = 1,nx
               storevec => fu_get_tla_column(traj, tag, ix, iy)
               do iz = 1,nz
                 val = real(tag + 10*(ix +10*(iy +10*(iz + 1000*indstep))))
                 if (any( storevec(:, iz) /= val)) then
                    print *, "Failed  traj, istep, tag, ix, iy" , indstep, tag, ix, iy
                    print *, storevec(:, iz)
                    print *, val
                 endif
               enddo
             enddo
          enddo
      end subroutine checkTLAbycol
  end subroutine test_tl_structs

end submodule test_tangent_linear_impl
