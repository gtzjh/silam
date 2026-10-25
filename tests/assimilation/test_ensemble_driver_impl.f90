submodule (ensemble_driver) test_ensemble_driver_impl
  implicit none
contains

    module subroutine test_repl_loc(replicate_localisation)
      implicit none
      interface
        subroutine replicate_localisation(loc_full_step, loc_chunk, &
            num_steps, size_full_step, my_offset, my_size)
          implicit none
          real, dimension(:,:), intent(in) :: loc_full_step
          real, dimension(:,:), intent(out) :: loc_chunk
          integer, intent(in) :: num_steps, size_full_step, my_offset, my_size
        end subroutine replicate_localisation
      end interface
      
      real, dimension(1,8) :: loc_full_step
      integer, parameter :: num_steps = 2
      real, target :: loc_chunk1(1,3*num_steps), loc_chunk2(1,3*num_steps), loc_chunk3(1,2*num_steps)
      type(silja_rp_2d), dimension(3) :: chunkptr

      integer, dimension(3) :: sizes = (/6,6,4/), offsets=(/1, 7, 13/)
      integer ::ii, ind_chunk

      chunkptr(1)%pp => loc_chunk1
      chunkptr(2)%pp => loc_chunk2
      chunkptr(3)%pp => loc_chunk3
      
      loc_full_step(1,:) = (/(ii, ii=1, 8)/)
      
      do ind_chunk = 1, 3
        call replicate_localisation(loc_full_step, chunkptr(ind_chunk)%pp, num_steps, 8, &
                                  & offsets(ind_chunk), sizes(ind_chunk))
      end do
      
      print *, 'loc_full_step', loc_full_step
      print *, ''

      do ind_chunk = 1, 3
        print *, 'loc', ind_chunk, chunkptr(ind_chunk)%pp
      end do

      !stop
      
    end subroutine test_repl_loc

end submodule test_ensemble_driver_impl
