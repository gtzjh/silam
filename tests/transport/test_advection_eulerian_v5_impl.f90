submodule (advection_eulerian_v5) test_advection_eulerian_v5_impl
contains
  
  !***********************************************************************************

  module subroutine test_advect_mass_many()
    implicit none
    integer :: i
    !
    ! Go through all relaxation strengths
    !
    CMrelax = 1.0
    do i = 1, 11
!      call test_advect_massR() 
      call test_advect_massMAS() 
!      call test_advect_mass2() 
      CMrelax = CMrelax - 0.01
    end do
    CMrelax = 0.5
!    call test_advect_massR() 
    call test_advect_massMAS() 
!    call test_advect_mass2() 
    CMrelax = 0.0
!    call test_advect_massR() 
    call test_advect_massMAS() 
!    call test_advect_mass2() 
    
  end subroutine test_advect_mass_many
  

  !***********************************************************************************


  module subroutine test_advect_massR()
    !
    ! Version with output for Roux Gnuplot scripts..
    !
    implicit none
    
     integer, parameter :: nLine = 100 !300 !100
     integer, parameter :: nTests = 9
     integer, parameter :: nSteps = 900
     integer :: W
     real, parameter :: fMax = 100.0
     real*8 :: Cu 
     integer :: delta, output_every = 60 !90 !60
     real, dimension(0:0,0:nLine+1,2) :: passengersInOut = 0
     real, dimension(nLine,0:nSteps) :: Stepresult
     real, dimension(nLine,2) :: cmInOut =0
     real, dimension(nLine) :: inM
     real, dimension(nLine,nTests) :: outM
     real*8, dimension(0:nLine) :: xr, xr_advected =0
     real, dimension(1:nLine) :: dx
     integer :: ix,istep,  iflip, itest, iUnit_rect, iUnit_rectdiff, iUnit_triangle, iUnit_rectdiff_cm, iUnit_step
     character(len=20) :: testname,chMM


     dx(:) = 1.
     xr(0) = 0.
     call msg("#Nline = ", nLine)
!     call msg("#Cu = ", Cu)
     call msg("#W = ", W)

     do ix=1,nLine
       xr(ix) = xr(ix-1) + dx(ix)
     enddo
     
     do  itest=1,nTests
        inm = 0.0
        W = 15
        select case (itest)
           case (1)  
              testname="rectpulse"
              do ix=1,W
!                 inm(ix+nline/2-w/2) = fMax
                 inm(1+ix) = fMax
              enddo
              inm = inm+10
           case (2)
              testname="tripulse"
              W = 20
              do ix=1, W
!                 inm(ix+nline/2-w/2) =  (W - 2*abs(ix- W/2.)) * fMax / real(W)
                 inm(1 + ix) =  (W - 2*abs(ix- W/2.)) * fMax / real(W)
              enddo
              inm = inm+10
           case (3)
              testname="sinpulse"
              do ix=1,W+1
!                 inm(ix+nline/2-w/2) =  1. + 10*(sin(pi*ix/W)**2)
                 inm(1+ix) = fMax*(sin(pi*(ix-1)/W)**2)
              enddo
              inm = inm+10
           case (4)  
              testname="rectgap"
              inm = fMax   !Background cnc
              do ix=1,W
!                 inm(ix+nline/2-w/2) = 0.1 * fMax
                 inm(1+ix) = 0.1 * fMax
              enddo
           case (5)
              testname="trigap"
              inm = fMax   !Background cnc
              do ix=1,W
!                 inm(ix+nline/2-w/2) =  fMax* (0.1 + 1.8  * abs(ix- W/2.) / W)
                 inm(1+ix) =  fMax* (0.1 + 1.8  * abs(ix- W/2.) / W)
              enddo
           case (6)
              testname="singap"
              inm = fMax   !Background cnc
              do ix=1,W
!                 inm(ix+nline/2-w/2) =  (1. - 0.9*(sin(pi*ix/W)**2)) * fMax
                 inm(1+ix) =  (1. - 0.9*(sin(pi*ix/W)**2)) * fMax
              enddo
           case(7)
              testname="delta"
              inm(w/2) = fMax
           case(8)
              inm = 0.1 * fMax
              testname="deltabckgr"
              inm(w/2) = fMax
           !   inm(nLine - 2) = fMax
        endselect
        Stepresult(1:nLine,0)=inm(1:nLine)
   
        cu = nline*1.0D0 / nsteps
        xr_advected(0:nLine) = xr(0:nLine) + Cu

        iUnit_rect = fu_next_free_unit()
        OPEN(iUnit_rect,file="00"+testname+"_rectangle.txt",action='write')
        iUnit_triangle = fu_next_free_unit()
        OPEN(iUnit_triangle,file="00"+testname+"_triangle.txt",action='write')
        iUnit_step = fu_next_free_unit()
        OPEN(iUnit_step,file="00"+testname+"_step.txt",action='write')

        write (iunit_rect,*) "#Test name:", testname
        write (iunit_rect,*) "#Steps per turn:", nsteps
        write (iunit_rect,*) "#Courrant:", cu
!        write (iunit_rect,'(i5,1x,A10,1000(F9.3,1x))') 0, "Initial = ", (inm(ix),ix=1,nLine), sum(inm(:))


        write (iUnit_triangle,*) "#Test name:", testname
        write (iUnit_triangle,*) "#Steps per turn:", nsteps
        write (iUnit_triangle,*) "#Courrant:", cu
!        write (iunit_triangle,'(i5,1x,A10,1000(F9.3,1x))') 0, "Initial = ", (inm(ix),ix=1,nLine), sum(inm(:))

        write (iUnit_step,*) "#Test name:", testname
        write (iUnit_step,*) "#Steps per turn:", nsteps
        write (iUnit_step,*) "#Courrant:", cu
!        write (iunit_step,'(i5,1x,A10,1000(F9.3,1x))') 0, "Initial = ", (inm(ix),ix=1,nLine), sum(inm(:))

        ! Silam default
        !
        passengersInOut(0,1:nLine,1) = inm(:)
        cmInOut(:,:) = 0
        iflip = 1
        do istep=1, nsteps
            call test_bind_advect_mass(cmInOut(:,iflip), cmInOut(:,3-iflip), &
                           & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                           & xr, xr_advected, dx,&
                           & .true., 1, nLine, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
               & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)
            iflip = 3 -  iflip
            Stepresult(1:nLine,iStep)= passengersInOut(0,1:nLine,iflip)
        enddo
        write (iunit_rect,'(A2,1000(F9.3,1x))')"#",sum(Stepresult(:,0:nSteps:9),dim=1)
        do ix=1,nLine
             write (iunit_rect,'(1000(F9.3,1x))') Stepresult(ix,0:nSteps:9)
        enddo 
            
        ! Pure triangle
        !
        passengersInOut(0,1:nLine,1) = inm(:)
        cmInOut(:,:) = 0
        iflip = 1
        do istep=1, nsteps
           where (passengersInOut(:,:,iflip)< 1e-20) passengersInOut(:,:,iflip) = 0.
           call test_bind_advect_mass_trislab(cmInOut(:,iflip), cmInOut(:,3-iflip), &
                                  & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                                  & xr, xr_advected,&
                                  & .true., 1, nLine, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
                                  & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)
           iflip = 3 -  iflip
            Stepresult(1:nLine,iStep)= passengersInOut(0,1:nLine,iflip)
        enddo
        write (iunit_triangle,'(A2,1000(F9.3,1x))')"#",sum(Stepresult(:,0:nSteps:9),dim=1)
        do ix=1,nLine
             write (iunit_triangle,'(1000(F9.3,1x))') Stepresult(ix,0:nSteps:9)
        enddo 


        ! Step
        !
        passengersInOut(0,1:nLine,1) = inm(:)
        cmInOut(:,:) = 0
        iflip = 1
        do istep=1, nsteps
!            call msg("")
!           print *,"Step", istep
           where (passengersInOut(:,:,iflip)< 1e-20) passengersInOut(:,:,iflip) = 0.
           call test_bind_advect_mass_step(cmInOut(:,iflip), cmInOut(:,3-iflip), &
                                  & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                                  & xr, xr_advected, dx,&
                                  & .true., 1, nLine, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
                                  & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)
           iflip = 3 -  iflip
           Stepresult(1:nLine,iStep)= passengersInOut(0,1:nLine,iflip)
        enddo
        write (iunit_step,'(A2,1000(F9.3,1x))')"#",sum(Stepresult(:,0:nSteps:9),dim=1)
        do ix=1,nLine
             write (iunit_step,'(1000(F9.3,1x))') Stepresult(ix,0:nSteps:9)
        enddo 

        close(iUnit_rect)
        close(iUnit_triangle)
        close(iUnit_step)

     enddo ! test patterns

  endsubroutine test_advect_massR


  !***********************************************************************************

  module subroutine test_advect_massMAS()
     ! MAS version
    implicit none

    integer, parameter :: nLine = 100
     integer, parameter :: nTests = 8
     integer :: W
     real, parameter :: fMax = 100.0
     real*8 :: Cu 
     integer :: delta, output_every = 60 !90 !60
     real, dimension(0:0,0:nLine+1,2) :: passengersInOut = 0
     real, dimension(nLine,2) :: cmInOut =0
     real, dimension(nLine) :: inM
     real, dimension(nLine,nTests) :: outM
     real*8, dimension(0:nLine) :: xr, xr_advected =0
     real, dimension(1:nLine) :: dx
     integer :: ix,istep, nsteps, iflip, itest, iUnit_rect, iUnit_rectdiff, iUnit_triangle, iUnit_rectdiff_cm
     character(len=20) :: testname,chMM
     logical :: myErr


     dx(:) = 1.
     xr(0) = 0.
     nsteps=9999
     call msg("#Nline = ", nLine)
!     call msg("#Cu = ", Cu)
     call msg("#W = ", W)

     do ix=1,nLine
       xr(ix) = xr(ix-1) + dx(ix)
     enddo
     
     do  itest=0,nTests
        inm = 0.0
        W = 15 ! 25  !15
        select case (itest)
          case(0)
            testname="plain"
            inm(:) = fMax
          case (1)  
              testname="rectpulse"
              do ix=1,W
!                 inm(ix+nline/2-w/2) = fMax
                 inm(1+ix) = fMax
              enddo
          case (2)
              testname="tripulse"
              W = 20
              do ix=1, W
!                 inm(ix+nline/2-w/2) =  (W - 2*abs(ix- W/2.)) * fMax / real(W)
                 inm(1 + ix) =  (W - 2*abs(ix- W/2.)) * fMax / real(W)
              enddo
          case (3)
              testname="sinpulse"
              do ix=1,W+1
!                 inm(ix+nline/2-w/2) =  1. + 10*(sin(pi*ix/W)**2)
                 inm(1+ix) = fMax*(sin(pi*(ix-1)/W)**2)
              enddo
          case (4)  
              testname="rectgap"
              inm = fMax   !Background cnc
              do ix=1,W
!                 inm(ix+nline/2-w/2) = 0.1 * fMax
                 inm(1+ix) = 0.1 * fMax
              enddo
          case (5)
              testname="trigap"
              inm = fMax   !Background cnc
              do ix=1,W
!                 inm(ix+nline/2-w/2) =  fMax* (0.1 + 1.8  * abs(ix- W/2.) / W)
                 inm(1+ix) =  fMax* (0.1 + 1.8  * abs(ix- W/2.) / W)
              enddo
          case (6)
              testname="singap"
              inm = fMax   !Background cnc
              do ix=1,W
!                 inm(ix+nline/2-w/2) =  (1. - 0.9*(sin(pi*ix/W)**2)) * fMax
                 inm(1+ix) =  (1. - 0.9*(sin(pi*ix/W)**2)) * fMax
              enddo
          case(7)
              testname="delta"
              inm(w/2) = fMax
          case(8)
              inm = 0.1 * fMax
              testname="deltabckgr"
              inm(w/2) = fMax
          case(9)
              inm = 0.
              testname="chair"
              do ix=1,W
                 inm(1+ix) =  0.5 * fMax
              enddo
              do ix=W,W*2
                 inm(1+ix) =  fMax
              enddo
        endselect
   
        cu = 0.4   !nline*1.0_r8k / nsteps
        xr_advected(0:nLine) = xr(0:nLine) + Cu

        iUnit_rect = fu_next_free_unit()
        OPEN(iUnit_rect,file="00"+testname+"_rectangle.txt",action='write')
        iUnit_rectdiff = fu_next_free_unit()
        write(unit=chMM,fmt='(F5.3)')maxmix
        print *, '==>',trim(chMM),'<=='
        OPEN(iUnit_rectdiff,file="00"+testname+"_rectangle_diff_"+trim(chMM)+".txt",action='write')
        iUnit_rectdiff_cm = fu_next_free_unit()
        write(unit=chMM,fmt='(F5.3)')CMRelax
        print *, '==>',trim(chMM),'<=='
        OPEN(iUnit_rectdiff_cm,file="00"+testname+"_rectangle_diff_cm_"+trim(chMM)+".txt",action='write')
        iUnit_triangle = fu_next_free_unit()
        OPEN(iUnit_triangle,file="00"+testname+"_triangle.txt",action='write')

        write (iunit_rect,*) "#Test name:", testname
        write (iunit_rect,*) "#Steps per turn:", nsteps
        write (iunit_rect,*) "#Courrant:", cu
        write (iunit_rect,'(i5,1x,A10,1000(F9.3,1x))') 0, "Initial = ", (inm(ix),ix=1,nLine), sum(inm(:))

        write (iunit_rectdiff,*) "#Test name:", testname
        write (iunit_rectdiff,*) "#Steps per turn:", nsteps
        write (iunit_rectdiff,*) "#Courrant, maxmix:", cu, maxmix
        write (iunit_rectdiff,'(i5,1x,A10,1000(F9.3,1x))') 0, "Initial = ", (inm(ix),ix=1,nLine), sum(inm(:))

        write (iunit_rectdiff_cm,*) "#Test name:", testname
        write (iunit_rectdiff_cm,*) "#Steps per turn:", nsteps
        write (iunit_rectdiff_cm,*) "#Courrant, maxmix:", cu, maxmix
        write (iunit_rectdiff_cm,'(i5,1x,A10,1000(F9.3,1x))') 0, "Initial = ", (inm(ix),ix=1,nLine), sum(inm(:))

        write (iUnit_triangle,*) "#Test name:", testname
        write (iUnit_triangle,*) "#Steps per turn:", nsteps
        write (iUnit_triangle,*) "#Courrant:", cu
        write (iunit_triangle,'(i5,1x,A10,1000(F9.3,1x))') 0, "Initial = ", (inm(ix),ix=1,nLine), sum(inm(:))

        ! Silam default
        !
        passengersInOut(0,1:nLine,1) = inm(:)
        cmInOut(:,:) = 0
        iflip = 1
        do istep=1, nsteps
          call test_bind_advect_mass(cmInOut(:,iflip), cmInOut(:,3-iflip), &
                         & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                         & xr, xr_advected, dx,&
                         & .true., 1, nLine, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
                         & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)
          iflip = 3 -  iflip
          if(mod(istep,output_every) == 0) write (iunit_rect,'(I5,1x,A10,1000(F9.3,1x))') istep, "Values = ", (passengersInOut(0,ix,iflip),ix=1,nLine), sum(passengersInOut(0,1:nline,iflip))
        enddo
        outM(:,1) =  passengersInOut(0,1:nLine,iflip)

        !
        ! Silam default with mass-centre diffusion
        !
        passengersInOut(0,1:nLine,1) = inm(:)
        cmInOut(:,:) = 0
        iflip = 1
        do istep=1, nsteps
          call test_bind_advect_mass(cmInOut(:,iflip), cmInOut(:,3-iflip), &
                         & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                         & xr, xr_advected, dx,&
                         & .true., 1, nLine, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
                         & 1e-10, .false., .True., & !& fMinAdvectedMass, have_negatives, ifCMout)
                         & CMRelax)
          iflip = 3 -  iflip
          if(mod(istep,output_every) == 0) write (iunit_rectdiff_cm,'(I5,1x,A10,1000(F9.3,1x))') istep, "Values = ", (passengersInOut(0,ix,iflip),ix=1,nLine), sum(passengersInOut(0,1:nline,iflip))
        enddo
        outM(:,1) =  passengersInOut(0,1:nLine,iflip)

        ! Pure triangle
        !
        passengersInOut(0,1:nLine,1) = inm(:)
        cmInOut(:,:) = 0
        iflip = 1
        do istep=1, nsteps
 !          print *, ""
 !          print *, "#Step=", istep-1
 !          do ix=1,nLine
 !           print *, ix,  passengersInOut(0,ix,iflip)
 !          enddo
          call test_bind_advect_mass_trislab(cmInOut(:,iflip), cmInOut(:,3-iflip), &
                                 & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                                 & xr, xr_advected,&
                                 & .true., 1, nLine, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
                                 & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)
          iflip = 3 -  iflip
          if(mod(istep,output_every) == 0) write (iunit_triangle,'(I5,1x,A10,1000(F9.3,1x))') istep, "Values = ", (passengersInOut(0,ix,iflip),ix=1,nLine), sum(passengersInOut(0,1:nline,iflip))
        enddo
!        outM(:,2) =  passengersInOut(0,1:nLine,iflip)

        close(iUnit_rect)
        close(iUnit_rectdiff)
        close(iUnit_rectdiff_cm)
        close(iUnit_triangle)

!        write (iunit,*) "# M0    Standard triangle" ! triangle02 triangle04"
!        do ix=1,nLine
!            write (iunit,*) ix,  inm(ix), outM(ix,1), outM(ix,2) !, outM(ix,3), outM(ix,4) 
!        enddo
!        write (iunit,*), "#" sum(inm), sum(outm(:,1)), sum(outm(:,2)) !, sum(outm(:,3)), sum(outm(:,4))
!        close(iunit)
     enddo ! test patterns

  endsubroutine test_advect_massMAS

  !***********************************************************************************

  module subroutine test_advect_mass2()
     implicit none
     integer, parameter :: nLine = 8
     real, dimension(0:0,0:nLine+1,2) :: passengersInOut = 0
     real, dimension(nLine,2) :: cmInOut =0
     real(r8k), dimension(0:nLine) :: xr, xr_advected =0
     real, dimension(1:nLine) :: dx
     integer :: ix,istep, nsteps, iflip, itest, iUnit
     character(len=20) :: testname

  xr = (/0.00000E+00, 0.15247E+12, 0.45545E+12, 0.10485E+13, 0.21797E+13, 0.41732E+13, 0.70728E+13, 0.11237E+14, 0.14675E+14/)
  xr_advected = (/-.00000E+00, 0.15424E+12, 0.46153E+12, 0.10611E+13, 0.22022E+13, 0.41973E+13, 0.70852E+13, 0.11276E+14, 0.14695E+14/)
     dx(1:nLine) = xr(1:nLine)-xr(0:nLine-1)

  passengersInOut(0,0:nLine+1,1) = (/0.00000E+00, 0.32388E+03, 0.75720E+03, 0.17067E+04, 0.29992E+04, 0.39749E+04, 0.37227E+04,  0.00000E+00, 0.00000E+00, 0.11391E+04/)
     cmInOut(:,1) = 0
     iFlip=1
     call test_bind_advect_mass(cmInOut(:,iflip), cmInOut(:,3-iflip), &
               & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                & xr, xr_advected, dx,&
               & .false., 1, nLine+1, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
               & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)
      print *, passengersInOut(0,1:nLine,2)

  endsubroutine test_advect_mass2
  
  module subroutine test_advect_cell()
     implicit none
    integer, parameter :: nLine = 8
     real, dimension(0:0,0:nLine+1,2) :: passengersInOut = 0
     real, dimension(0:0,0:nLine+1,2) :: passengersInOut1 = 0
     real, dimension(nLine,2) :: cmInOut =0
     real, dimension(0:nLine) :: u_right
     real, dimension(0:nLine) :: u_right1
     logical, dimension(0:nLine+1) :: ifSkipCell
     real*8, dimension(0:nLine) :: xr, xr_advected, xr_advected1
     real, dimension(1:nLine) :: dx
     integer :: ix,istep, nsteps, iflip, itest, iUnit
     character(len=20) :: testname
     real :: seconds
     integer :: i

    seconds=0.7
    do i = 0,nLine
       u_right(0:nLine) = (/2., 1., 0., 1., 2., 3., 2., 1., 0./)
    enddo
    dx(1:nLine) = 1.
    ifSkipCell = .false.

    call test_bind_advect_cellboundaries(u_right, dx, xr, xr_advected,& 
       & ifSkipCell, seconds, .false., 1, nLine, nLine)

    print *, xr
    print *, xr_advected  ! Prints advected boundaries

    ! flip wind
    u_right1(0:nLine) = -u_right(nLine:0:-1)
    call test_bind_advect_cellboundaries(u_right1, dx, xr, xr_advected1,& 
       & ifSkipCell, seconds, .false., 1, nLine, nLine)
    print *, xr(nLine)-xr_advected1(nLine:0:-1) !must print the same

 print *, ""
  passengersInOut(0,0:nLine+1,1) = (/1., 0., 0., 1., 0., 0., 0.,  0., 0., 0./)
  passengersInOut1(0,0:nLine+1,1) = passengersInOut(0,nLine+1:0:-1,1)
  cmInOut(:,1) = 0.2
     iFlip=1
     call test_bind_advect_mass_trislab(cmInOut(:,iflip), cmInOut(:,3-iflip), &
               & passengersInOut(:,:,iflip),  passengersInOut(:,:,3-iflip), 0, &
                & xr, xr_advected,&
               & .false., 0, nLine+1, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
               & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)
            print *, passengersInOut(0,0:nLine+1,2)
            print *, sum(passengersInOut(0,0:nLine+1,2))
     
  cmInOut(:,1) = -0.2
     call test_bind_advect_mass_trislab(cmInOut(:,iflip), cmInOut(:,3-iflip), &
               & passengersInOut1(:,:,iflip),  passengersInOut1(:,:,3-iflip), 0, &
                & xr, xr_advected1, &
               & .false., 0, nLine+1, nLine, &! ifLoop, iCellStart, iCellEnd, nCells,
               & 1e-10, .false., .True., 1.0) !& fMinAdvectedMass, have_negatives, ifCMout)

     print *, passengersInOut1(0,nLine+1:0:-1,2)
     print *, sum(passengersInOut1(0,0:nLine+1,2))

  endsubroutine test_advect_cell
  

end submodule test_advection_eulerian_v5_impl
