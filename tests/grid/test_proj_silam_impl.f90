submodule (proj_silam) test_proj_silam_impl
  implicit none

contains

  module subroutine test_proj()
     implicit none

     integer, parameter :: np = 4
     real(8), dimension(np) :: lats, lons
     integer :: i
     real(8) :: x, y
     character (len=*), parameter :: hirlam_rll_proj4 ="+proj=ob_tran +o_proj=longlat +o_lon_p=0 +o_lat_p=30 +lon_0=0"
     character (len=*), parameter ::       lcc_example="+proj=lcc  +lon_0=-90 +lat_1=33 +lat_2=45"
     character (len=*), parameter ::      merc_example="+proj=merc +lon_0=-90 +lat_1=33 +lat_2=45"

     !! corners of EU meteo in projected lon-lat
     lons(1:np) = (/-26., -26., 40., 40./)  
     lats(1:np) = (/-35., 22.5, 22.5, -35./)

     call msg("rotated-pole coordinates lon, lat")
     call msg(hirlam_rll_proj4)
     do i=1,np
       call msg(fu_str(i), lons(i),lats(i))
     enddo

     call ll2proj(hirlam_rll_proj4, lons, lats, np, backwards)

     call msg("Same in WGS84 coordinates lon, lat")
     call msg(lonlat_proj4)
     do i=1,np
       call msg(fu_str(i), lons(i),lats(i))
     enddo

     call ll2proj(hirlam_rll_proj4, lons, lats, np, forwards)

     call msg("And back! lon, lat")
     call msg(hirlam_rll_proj4)
     do i=1,np
       call msg(fu_str(i), lons(i),lats(i))
     enddo
     call msg("Done")

     !Aditional test: single value
     print*,"(t) Aditional test 1: single value transformation.."
     x=lons(1); y=lats(1)
     print*,"original lons(1),y=lats(1) ",lons(1),lats(1)
     call ll2proj_pt(hirlam_rll_proj4,x,y,backwards)
     print*,"transformed to x,y         ",x,y
     call ll2proj_pt(hirlam_rll_proj4,x,y,forwards)
     print*,"back to lons(1),y=lats(1): ",x,y
     call msg("Done")

     !Aditional test: any 2 any
     print*,"(t) Aditional test 2: any to any transformation.."
     
     print*,"Original lons(1),y=lats(1) ",lons(1),lats(1)
     call proj_trans(hirlam_rll_proj4, lcc_example, lons(1:1), lats(1:1), 1)
     print*,"transformed to lcc         ", lons(1), lats(1)
     call proj_trans(lcc_example, hirlam_rll_proj4, lons(1:1), lats(1:1), 1)
     print*,"back to lons(1),y=lats(1): ", lons(1), lats(1)
     call msg("Done")

  end subroutine test_proj

end submodule test_proj_silam_impl
