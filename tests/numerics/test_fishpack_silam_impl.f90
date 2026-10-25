submodule (fishpack_silam) test_fishpack_silam_impl
contains
!
!     file tblktri.f
!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 2005 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                    FISHPACK90  version 1.1                    *
!     *                                                               *
!     *                 A Package of Fortran 77 and 90                *
!     *                                                               *
!     *                Subroutines and Example Programs               *
!     *                                                               *
!     *               for Modeling Geophysical Processes              *
!     *                                                               *
!     *                             by                                *
!     *                                                               *
!     *        John Adams, Paul Swarztrauber and Roland Sweet         *
!     *                                                               *
!     *                             of                                *
!     *                                                               *
!     *         the National Center for Atmospheric Research          *
!     *                                                               *
!     *                Boulder, Colorado  (80307)  U.S.A.             *
!     *                                                               *
!     *                   which is sponsored by                       *
!     *                                                               *
!     *              the National Science Foundation                  *
!     *                                                               *
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!
!     PROGRAM TO ILLUSTRATE THE USE OF SUBROUTINE BLKTRI TO
!     SOLVE THE EQUATION
!
!     .5/S*(D/DS)(.5/S*DU/DS)+.5/T*(D/DT)(.5/T*DU/DT)
!                                                          (1)
!                   = 15/4*S*T*(S**4+T**4)
!
!     ON THE RECTANGLE 0 .LT. S .LT. 1 AND 0 .LT. T .LT. 1
!     WITH THE BOUNDARY CONDITIONS
!
!     U(0,T) = 0
!                            0 .LE. T .LE. 1
!     U(1,T) = T**5
!
!     AND
!
!     U(S,0) = 0
!                            0 .LE. S .LE. 1
!     U(S,1) = S**5
!
!     THE EXACT SOLUTION OF THIS PROBLEM IS U(S,T) = (S*T)**5
!
!     DEFINE THE INTEGERS M = 50 AND N = 63. THEN DEFINE THE
!     GRID INCREMENTS DELTAS = 1/(M+1) AND DELTAT = 1/(N+1).
!
!     THE GRID IS THEN GIVEN BY S(I) = I*DELTAS FOR I = 1,...,M
!     AND T(J) = J*DELTAT FOR J = 1,...,N.
!
!     THE APPROXIMATE SOLUTION IS GIVEN AS THE SOLUTION TO
!     THE FOLLOWING FINITE DIFFERENCE APPROXIMATION OF EQUATION (1).
!
!     .5/(S(I)*DELTAS)*((U(I+1,J)-U(I,J))/(2*S(I+.5)*DELTAS)
!                     -(U(I,J)-U(I-1,J))/(2*S(I-.5)*DELTAS))
!     +.5/(T(I)*DELTAT)*((U(I,J+1)-U(I,J))/(2*T(I+.5)*DELTAT) (2)
!                     -(U(I,J)-U(I,J-1))/(2*T(I-.5)*DELTAT))
!               = 15/4*S(I)*T(J)*(S(I)**4+T(J)**4)
!
!             WHERE S(I+.5) = .5*(S(I+1)+S(I))
!                   S(I-.5) = .5*(S(I)+S(I-1))
!                   T(I+.5) = .5*(T(I+1)+T(I))
!                   T(I-.5) = .5*(T(I)+T(I-1))
!
!     THE APPROACH IS TO WRITE EQUATION (2) IN THE FORM
!
!     AM(I)*U(I-1,J)+BM(I,J)*U(I,J)+CM(I)*U(I+1,J)
!       +AN(J)*U(I,J-1)+BN(J)*U(I,J)+CN(J)*U(I,J+1)      (3)
!           = Y(I,J)
!
!     AND THEN CALL SUBROUTINE BLKTRI TO DETERMINE U(I,J)
!
!
!
   logical module function  TBLKTRI(DUMMY)


      TYPE ( fishworkspace) :: w
      integer, intent(in) :: DUMMY ! Does not mean anything
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      INTEGER :: IFLG, NP, N, MP, M, IDIMY, I, J, IERROR
      REAL(fish_kind) , DIMENSION(75,105) :: Y
      REAL(fish_kind) , DIMENSION(75) :: AM, BM, CM
      REAL(fish_kind) , DIMENSION(105) :: AN, BN, CN
      REAL(fish_kind) , DIMENSION(75) :: S
      REAL(fish_kind) , DIMENSION(105) :: T
      REAL(fish_kind) ::DELTAS,DELTAT,HDS,TDS,TEMP1,TEMP2,TEMP3,HDT,TDT,ERR,Z
!-----------------------------------------------
      IFLG = 0
      NP = 1
      N = 63
      MP = 1
      M = 50
      IDIMY = 75
!
!     GENERATE AND STORE GRID POINTS FOR THE PURPOSE OF COMPUTING THE
!     COEFFICIENTS AND THE ARRAY Y.
!
      DELTAS = 1./FLOAT(M + 1)
      DO I = 1, M
         S(I) = FLOAT(I)*DELTAS
      END DO
      DELTAT = 1./FLOAT(N + 1)
      DO J = 1, N
         T(J) = FLOAT(J)*DELTAT
      END DO
!
!     COMPUTE THE COEFFICIENTS AM,BM,CM CORRESPONDING TO THE S DIRECTION
!
      HDS = DELTAS/2.
      TDS = DELTAS + DELTAS
      DO I = 1, M
         TEMP1 = 1./(S(I)*TDS)
         TEMP2 = 1./((S(I)-HDS)*TDS)
         TEMP3 = 1./((S(I)+HDS)*TDS)
         AM(I) = TEMP1*TEMP2
         CM(I) = TEMP1*TEMP3
         BM(I) = -(AM(I)+CM(I))
      END DO
!
!     COMPUTE THE COEFFICIENTS AN,BN,CN CORRESPONDING TO THE T DIRECTION
!
      HDT = DELTAT/2.
      TDT = DELTAT + DELTAT
      DO J = 1, N
         TEMP1 = 1./(T(J)*TDT)
         TEMP2 = 1./((T(J)-HDT)*TDT)
         TEMP3 = 1./((T(J)+HDT)*TDT)
         AN(J) = TEMP1*TEMP2
         CN(J) = TEMP1*TEMP3
         BN(J) = -(AN(J)+CN(J))
      END DO
!
!     COMPUTE RIGHT SIDE OF EQUATION
!
      DO J = 1, N
         Y(:M,J) = 3.75*S(:M)*T(J)*(S(:M)**4+T(J)**4)
      END DO
!
!     THE NONZERO BOUNDARY CONDITIONS ENTER THE LINEAR SYSTEM VIA
!     THE RIGHT SIDE Y(I,J). IF THE EQUATIONS (3) GIVEN ABOVE
!     ARE EVALUATED AT I=M AND J=1,...,N THEN THE TERM CM(M)*U(M+1,J)
!     IS KNOWN FROM THE BOUNDARY CONDITION TO BE CM(M)*T(J)**5.
!     THEREFORE THIS TERM CAN BE INCLUDED IN THE RIGHT SIDE Y(M,J).
!     THE SAME ANALYSIS APPLIES AT J=N AND I=1,..,M. NOTE THAT THE
!     CORNER AT J=N,I=M INCLUDES CONTRIBUTIONS FROM BOTH BOUNDARIES.
!
      Y(M,:N) = Y(M,:N) - CM(M)*T(:N)**5
      Y(:M,N) = Y(:M,N) - CN(N)*S(:M)**5
!
!     DETERMINE THE APPROXIMATE SOLUTION U(I,J)
!
      CALL BLKTRI(IFLG,NP,N,AN,BN,CN,MP,M,AM,BM,CM,IDIMY,Y,IERROR,W)
      IFLG = IFLG + 1
      DO WHILE(IFLG - 1 <= 0)
         CALL BLKTRI (IFLG, NP, N, AN, BN, CN, MP, M, AM, BM, CM, IDIMY, Y, IERROR, W)
         IFLG = IFLG + 1
      END DO
      ERR = 0.
      DO J = 1, N
         DO I = 1, M
            Z = ABS(Y(I,J)-(S(I)*T(J))**5)
            ERR = AMAX1(Z,ERR)
         END DO
      END DO
!     Print earlier output from platforms with 32 and 64 bit floating point
!     arithemtic followed by the output from this computer
      call msg('    BLKTRI TEST RUN *** ')
      call msg('    Previous 64 bit floating point arithmetic result ')
      call msg('    IERROR = 0,  Discretization Error = 1.6478E-05')
      call msg('    Previous 32 bit floating point arithmetic result ')
      call msg('    IERROR = 0,  Discretization Error = 1.2737E-02')
      call msg('    The output from your computer is: ')
      call msg('    IERROR ='+fu_str( IERROR) +', Discretization Error = ',ERR)
!     release dynamically allocated work space
      CALL FISHFIN (W)
      if (fish_kind == 4) then 
            TBLKTRI = (ERR<1.3E-02)
      elseif (fish_kind == 8) then 
            TBLKTRI = (ERR<1.7E-05)
      else
           call msg("Unknown fish_kind",fish_kind)
           TBLKTRI = .false.
      endif
      return 
   END function TBLKTRI



end submodule test_fishpack_silam_impl
