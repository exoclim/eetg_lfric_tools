module deep_hot_jupiter_forcings_mod

  use constants_mod,     only: i_def, r_def, pi
  use planet_config_mod, only: omega, p_zero, kappa

  implicit none

  private

  public :: deep_hot_jupiter_newton_frequency
  public :: deep_hot_jupiter_equilibrium_theta

  public :: night_side_temp, day_side_temp

contains

function deep_hot_jupiter_equilibrium_theta(exner, lat, lon) result(theta_eq)

  implicit none

  ! Arguments
  real(kind=r_def), intent(in)    :: exner, lat, lon

  ! Local variables
  real(kind=r_def)                :: t_night, t_day
  real(kind=r_def)                :: t_eq, theta_eq ! Equilibrium temperature and theta theta

  ! Calculate night and day side temperature model variables
  t_night = night_side_temp(exner)
  t_day = day_side_temp(exner)

  ! Calculate equilibrium temperature according to equation 29 in Mayne et. al. 2014 
  if (lon >= pi/2.0_r_def .and. lon <= 3.0*pi/2.0_r_def) then
    t_eq = (t_night**4_i_def + (t_day**2_i_def + t_night**2_i_def) * (t_day + t_night) * (t_day - t_night) &
                      * cos(lon - pi) * cos(lat))**0.25_r_def
  else
    t_eq = t_night
  end if

  ! Recall using potential temperature
  ! Therefore, must convert the temperature to potential
  ! temperature using the Exner function (exner*theta=Temp)
  theta_eq = t_eq / exner

end function deep_hot_jupiter_equilibrium_theta

function deep_hot_jupiter_newton_frequency(exner) result(jupiter_like_frequency)

  implicit none

  ! Arguments
  real(kind=r_def), intent(in) :: exner

  ! Parameters
  real(kind=r_def), parameter :: p_low = 1.0, p_high = 1.0e6

  ! Local variables
  real(kind=r_def) :: pressure, log_sigma
  real(kind=r_def) :: jupiter_like_frequency

  ! Calculate pressure from exner function
  pressure = pressure_from_exner(exner)

  ! Calculate the relaxation frequency (inverse of Newton radiative cooling timescale)
  if (pressure >= p_high) then
    jupiter_like_frequency = 0.0_r_def
  else 
    if (pressure >= p_low) then
      log_sigma = log10(pressure / 1.0e5_r_def)
    else
      log_sigma = log10(p_low / 1.0e5_r_def)
    endif
    jupiter_like_frequency = 1.0_r_def /                                     &
                               (10.0_r_def **                                &
                                 (  5.4659686_r_def                          &
                                  + 1.4940124_r_def * log_sigma              &
                                  + 0.66079196_r_def * log_sigma ** 2_i_def  &
                                  + 0.16475329_r_def * log_sigma ** 3_i_def  &
                                  + 0.014241552_r_def * log_sigma ** 4_i_def &
                                 )                                           &
                               )
  end if                   
 
end function deep_hot_jupiter_newton_frequency

function day_side_temp(exner) result(t_day)

   implicit none

   ! Arguments
   real(kind=r_def), intent(in) :: exner

   ! Parameters
   real(kind=r_def), parameter :: p_low = 100.0, p_high = 1.0e6
   real(kind=r_def), parameter :: t_low = 1000.0, alpha = 0.015
   real(kind=r_def), parameter :: beta = -120.0

   ! Local variables
   real(kind=r_def) :: pressure
   real(kind=r_def) :: log_sigma, t_day_active, t_day

   pressure = pressure_from_exner(exner)

   if (pressure >= p_high) THEN
     log_sigma = log10(p_high / 1.0e5_r_def)
   else if (pressure < p_low) THEN
     log_sigma = log10(p_low / 1.0e5_r_def)
   else
     log_sigma = log10(pressure / 1.0e5_r_def)
   end if

   t_day_active = 2149.9581                             &
                  + 4.1395571 * log_sigma               &
                  - 186.24851 * log_sigma ** 2_i_def    &
                  + 135.52524 * log_sigma ** 3_i_def    &
                  + 106.20433 * log_sigma ** 4_i_def    &
                  - 35.851966 * log_sigma ** 5_i_def    &
                  - 50.022826 * log_sigma ** 6_i_def    &
                  - 18.462489 * log_sigma ** 7_i_def    &
                  - 3.3319965 * log_sigma ** 8_i_def    &
                  - 0.30295925 * log_sigma ** 9_i_def   &
                  - 0.011122316 * log_sigma ** 10_i_def 
   
   if (pressure >= p_high) then
     t_day = t_day_active + beta * (1.0_r_def - exp(log10(p_high / pressure)))
   else if (pressure < p_low) then
     t_day = max(t_day_active * exp(alpha * log10(pressure / p_low)), t_low)
   else
     t_day = t_day_active
   end if 
   
end function day_side_temp

function night_side_temp(exner) result(t_night)

   implicit none

   ! Arguments
   real(kind=r_def), intent(in) :: exner

   ! Parameters
   real(kind=r_def), parameter :: p_low = 100.0, p_high = 1.0e6
   real(kind=r_def), parameter :: t_low = 250.0, alpha = 0.10
   real(kind=r_def), parameter :: beta = 100.0

   ! Local variables
   real(kind=r_def) :: pressure 
   real(kind=r_def) :: log_sigma, t_night_active, t_night

   pressure = pressure_from_exner(exner)

   if (pressure >= p_high) THEN
     log_sigma = log10(p_high / 1.0e5_r_def)
   else if (pressure < p_low) THEN
     log_sigma = log10(p_low / 1.0e5_r_def)
   else
     log_sigma = log10(pressure / 1.0e5_r_def)
   end if

   t_night_active = 1388.2145                             &
                    + 267.66586 * log_sigma               &
                    - 215.53357 * log_sigma ** 2_i_def    &
                    + 61.814807 * log_sigma ** 3_i_def    &
                    + 135.68661 * log_sigma ** 4_i_def    &
                    + 2.0149044 * log_sigma ** 5_i_def    &
                    - 40.907246 * log_sigma ** 6_i_def    &
                    - 19.015628 * log_sigma ** 7_i_def    &
                    - 3.8771634 * log_sigma ** 8_i_def    &
                    - 0.38413901 * log_sigma ** 9_i_def   &
                    - 0.015089084 * log_sigma ** 10_i_def

   if (pressure >= p_high) then
     t_night = t_night_active + beta * (1.0_r_def - exp(log10(p_high / pressure)))
   else if (pressure < p_low) then
     t_night = max(t_night_active * exp(alpha * log10(pressure / p_low)), t_low)
   else
     t_night = t_night_active
   end if

end function night_side_temp
 
function pressure_from_exner(exner) result(pressure)

  implicit none

  ! Arguments
  real(kind=r_def), intent(in) :: exner
   
  ! Local variables
  real(kind=r_def) :: pressure
  
  pressure = p_zero * exner ** (1.0_r_def / kappa)

end function pressure_from_exner

end module deep_hot_jupiter_forcings_mod
