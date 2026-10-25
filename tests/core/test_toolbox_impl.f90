submodule (toolbox) test_toolbox_impl
  implicit none

contains

  module subroutine testremapcon_1D()
    integer i, n
    integer, parameter :: n1 = 1801
    integer, parameter :: n2 = 1801

    real, dimension (n1) :: bnd1 
    real, dimension (n2) :: bnd2
    real, dimension (n1+n2) :: bndout
    integer, dimension (n1+n2) :: idx1, idx2
    integer :: nSeg

    do i = 1,n1
      bnd1(i) = -180. + 0.2*(i-1)
    enddo
    do i = 1,n2
      bnd2(i) = -180 + 0.2*(i-1)
    enddo

    call msg("bnd1", bnd1)
    call msg("bnd2", bnd2)
    call remapcon_1D(bnd1, bnd2, 0.001, bndout, idx1, idx2, nSeg)
    call msg("Bndout(1)", bndout(1))
    do i = 1, nSeg-1
        call msg ("idx1,idx2", idx1(i), idx2(i))
        call msg("Bndout(i+1), i", bndout(i+1)) 
    enddo

  endsubroutine testremapcon_1D

  module subroutine test_sort()

    integer, parameter ::  N = 160
    integer, dimension(N) :: ivals, indices
    integer :: i
    character(len=8), dimension(160), parameter :: strings= (/&
   & "oo5Aa7ve","taiPai8a","Ob0Yei5n","ahBi8uil","ohV6oovo","Oophah9I","oqu0Ieng","Ufee5lo1", &
   & "kee8Aeri","eish8Ahf","Shei7Viu","ohChi9da","Toaca5ea","xee2iCi4","du5aic1X","daeZahz7", &
   & "ahBi7tha","eeS2vahX","moh7maeM","Shiejah4","eCa9bez2","joQu4zie","Aehee5th","Chie5aep", &
   & "Uu0ge6au","aexa1aeR","ohSei2oo","AiPh2ait","iu3yeiFu","too3RahL","Aaqu6li4","aiYier5S", &
   & "chefah9A","Cahcuju4","Eef1Zie8","ahKah9ei","Iene8ahn","ooL3zoo0","aiMei7ga","aeB0ahva", &
   & "aMeeV4ei","Iu2vohzu","equ9BaH3","wuet7Mee","eiVu2jee","Loop7Eil","as8heeNu","chotoj1A", &
   & "aj7eQuah","eiN4weJi","nooWe2pa","Wughe4de","riesahX0","ahZ3she8","Ioviey3w","xiM5eiqu", &
   & "Uaz2Hael","sheiG4gu","nah2Heiy","hei2Wu4e","Aizae2ca","mohs0Wi6","Thir3tah","eiquuQu7", &
   & "Ahjai9ie","ohCe3Uo4","Ohgh5hoh","Izie3cha","ooPh9rae","leiSeiG1","aeDahk0e","Shai8yie", &
   & "Loo1cies","ieXoina6","toopo4Ie","yahc7Sho","geDu9bo6","Ahz0ohdi","waN3ohGu","Pae5kae0", &
   & "Ieno8ain","quai6aeK","eeQu1ieL","iexeeB6v","DohL1eiD","ieGhoh0c","eJ4guqua","Kiek2ieh", &
   & "Othur4ai","Yah3keel","Vun0eshi","ShohB6ze","Zo4aiche","ohl4theT","ahM9quee","eeYo1oqu", &
   & "Cachai5o","Eevoo9ee","oog2shuG","BahJ2shu","gei2iaNg","Niuj4osh","siLu0hae","oht1Tuc6", &
   & "eeFaej8p","ooh4Aok3","duuho8Ah","deiNgeg6","aiZa0Ohs","giLahd0o","dueCh2zo","Yah6aen8", &
   & "eeBaib8e","queXiex3","ooMie6xu","booKoh3A","Yei5ub8w","sahqu1iW","seeK2ier","ug8Ag3te", &
   & "Kiphahh4","Zae8oogh","eedoh8Ba","kah6LieR","bieLie2a","he3si8Po","eer1Ieme","xahy8Rei", &
   & "iech7aWo","uph5Ku2i","ib7ees2D","ohThu3EP","oopeeNg0","EeveeJ2i","ooV0waip","Ohqua7qu", &
   & "eex4yuJ4","ier8Ungu","yae6Uthe","eeXai8ni","Aihook9z","sasoh8Se","Aepi7Ubi","fa0Mabae", &
   & "ieTh7zi8","Iuyies6y","Ahdai0Oo","pohTii2b","Olu9xo9A","shoh1Cae","chas8Aow","ohQuae4x", &
   & "Shais6Ch","SooH8boo","iV5odee5","fo9Laem1","fuDahng6","shei2Umu","daiti9Ae","ACi2ka8c" /)

    CALL SRAND(0)
    do i=1,N
      ivals(i) = fu_irand()   ! irand is not a standard function of FORTRAN. wrapper is in md
      indices(i) = i
    enddo
    call argMergeSort_int(ivals,indices)
    call msg("Array", ivals)
    call msg("Sorted indices", indices)
    call msg("Sorted:")
    do i=1,N
      call msg("",indices(i), ivals(indices(i)))
    enddo

    !!! Strings
    do i=1,N
      indices(i) = i
    enddo
    call argMergeSort_char(strings,indices)
    call msg("Sorted:")
    do i=1,N
      call msg(strings(indices(i)),indices(i))
    enddo

  end subroutine test_sort

  module subroutine test_AMOEBA()
    implicit none
    
    integer, PARAMETER :: MP=21,NP=20

    real, dimension(MP,NP) :: P
    real, dimension(MP) :: Y, PT
    integer :: nDim, i, j, iter
    real :: fTol
    real, dimension(1) :: arExtra = 0.0
    
    NDIM=2       ! 2 variables
    FTOL=1.D-8   ! Required tolerance

    !define NDIM+1 initial vertices (one by row)
    P(1,1)=1.
    P(1,2)=2.
    P(2,1)=-2.
    P(2,2)=-3.
    P(3,1)=4.
    P(3,2)=2.

    !Initialize Y to the values of FUNC evaluated 
    !at the NDIM+1 vertices (rows) of P
    DO I=1, NDIM+1
      PT(1)=P(I,1)
      PT(2)=P(I,2)
      Y(I)=fu_func_to_minimize(PT, arExtra)
    END DO

    !call main subroutine
    CALL AMOEBA(fu_func_to_minimize, P,Y,NDIM,FTOL, arExtra, ITER, 2)

    !print results
    print *,' '
    print *,' Number of iterations:', ITER
    print *,' '
    print *,' Best NDIM+1 points:'
    write(*,'(2e16.8)') ((P(I,J),J=1,NDIM),I=1,NDIM+1)
    print *,' '
    print *,' Best NDIM+1 mimimum values:'
    write(*,'(E16.8)') (Y(I),I=1,NDIM+1) 
    print *,' '
  END subroutine test_AMOEBA

  module subroutine test_2_AMOEBA()
    ! A bit more realisitc test, from real minimization of 4D-VAR
    implicit none
    
    integer, PARAMETER :: MP=3,NP=2

    real, dimension(MP,NP) :: P
    real, dimension(MP) :: Y, PT
    integer :: nDim, i, j, iter
    real :: fTol
    real, dimension(23) :: arExtra = (/11.0, &
      & 0.00000E+00, 0.16703E-04, 0.41758E-03, 0.73662E-02, 0.28468E+00, 0.44339E+00, &
                     &  0.10000E+01,  0.56212E+00,  0.46808E+00,  0.44857E+00,  0.44448E+00,  &
      & 0.00000E+00,  -.74898E-03, -.36734E-02, -.14178E-01,  -.54283E-01, -.64279E-01, &
                     & -.81352E-01,  -.69870E-01,  -.65598E-01,  -.64563E-01,  -.64339E-01/)
    
    NDIM=2       ! 2 variables
    FTOL=1.D-4   ! Required tolerance

    !define NDIM+1 initial vertices (one by row)
    P(:,1) = 0.5
    P(:,2) = 10
    P(2,1) = 0.6    ! 1  - too far
    P(3,2) = 11     ! 5  - too far
    !
    ! Get RMSE for the vectors in P (each point of the simplex)
    !
    do i = 1, NDIM+1
      Y(i) = fu_L_curve_log10_fit_RMSE(P(i,:), arExtra)
    end do
    !
    ! Call the minimizing subroutine
    !
    print *,'Calling optimiser for the first time...'
    CALL AMOEBA(fu_L_curve_log10_fit_RMSE, P,Y, NDIM, FTOL, arExtra, ITER, 2)
    if(error)return
   
    !print results
    print *,' '
    print *,' Number of iterationsin minimization:', ITER
    print *,' '
    print *,' Best NDIM+1 points:'
    write(*,'(2e16.8)') ((P(I,J),J=1,NDIM),I=1,NDIM+1)
    print *,' '
    print *,' Best NDIM+1 mimimum values:'
    write(*,'(E16.8)') (Y(I),I=1,NDIM+1) 
    print *,' '
    
    contains

      real function fu_L_curve_log10_fit_RMSE(arParams, arExtraInput)result(RMSE)
        !
        ! A function to call from the minimization routine. It calculates RMSE of the fit:
        ! obs_err = fu_L_curve_log10(bckgr_err)
        !
        implicit none
    
        ! Imported parameters
        real, dimension(:), intent(in) :: arParams, arExtraInput  ! (/params/), (/nVals,bckgr_err,obs_err/)
    
        ! Local variables
        integer :: nIter, iVal
    
        ! How many iterations to fit?
        nIter = nint(arExtraInput(1))
        !
        ! Get the RMSE of the fit: sum( (obs_err - fit(bckg_err)) **2 )
        !
        RMSE = 0
        do iVal = 1, nIter
          RMSE = RMSE + (arExtraInput(nIter+1+iVal) - fu_L_curve_log10(arExtraInput(1+iVal), &
                                                                 & arParams(1), arParams(2))) ** 2
        end do
        return
      end function fu_L_curve_log10_fit_RMSE
  
      !===========================================================

      real function fu_L_curve_log10(bckgr_err, a, b)
        !
        ! L-Curve itself, computes one value
        ! Take care of the area of definition of log
        !
        implicit none
    
        ! Imported parameters
        real, intent(in) :: bckgr_err
        real, intent(in) :: a, b
    
        ! Local variables
        real :: fTmp
    
        fTmp = a * exp(-b * bckgr_err) + (1.0 - a)
        if(fTmp > 0)then
          fu_L_curve_log10 = log10(fTmp)
        else
          fu_L_curve_log10 = -1e10  ! big enough and negative
          print *, 'Out of area of definition, bckgr_err, a, b, log-argval:', bckgr_err, a, b, fTmp
          print *, 'Out of area of definition', 'fu_L_curve_log10'
        endif
    
      end function fu_L_curve_log10

  END subroutine test_2_AMOEBA

  module REAL FUNCTION fu_func_to_minimize(P, arExtra)
    implicit none
    REAL, dimension(:), intent(in) :: P, arExtra
    real :: R
    R=SQRT(P(1)*P(1)+P(2)*P(2))
    IF (ABS(R).LT.1.e-12) THEN
      fu_func_to_minimize=1.
    ELSE
      fu_func_to_minimize=SIN(R)/R
    END IF
    RETURN
  END function fu_func_to_minimize

end submodule test_toolbox_impl
