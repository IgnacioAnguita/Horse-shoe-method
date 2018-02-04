%% Constants
N=51;% Number of points
b=1;% Span of the wing
P_Distribution=1; % Type of discretization 0 for linear, 1 for full cosine
A=8; % Aspect ratio
Taper_ratio=1; %Taper Ratio
Quarter_chord_sweep_angle=degtorad(0); %Quarter Chord sweep angle
Dihedral=degtorad(0); %Dihedral angle
alpha_zero_lift_initial=degtorad(0); %alpha zero lift in the root
alpha_zero_lift_final=degtorad(0); %alpha zero lift in the tail
Total_twist=degtorad(0);%total twist in the tail, we supose positive twist in when it is wash-out
S=b^2/A;%Surface of the wing
rho=1;%Density of the air
Alpha=deg2rad(6);
v_inf_mod=1;%module of the free flow velocity
v_inf=[v_inf_mod*cos(Alpha) 0 v_inf_mod*sin(Alpha)];%flow velocity
flap_initial_position=b/2*[0 1/2]; %initial flap's postion (y-potition), we consider symmetrical wing=
flap_final_position=b/2*[0.25 0.75]; %final flap's postion (y-potition), we consider symmetrical wing=
etha=deg2rad(0); %flap deflection
E=0.2; %flap's adimensional chord
theta_h=acos(2*E-1);
%% %% COMPUTATION OF INCREMENT OF ALPHA ZERO LIFT DUE TO THE FLAP
eff_factor_t=-(1-theta_h/pi+sin(theta_h)/pi); %therical efficiency factor
%Real efficiency factor:
if etha<deg2rad(10)
    eff_factor_r=eff_factor_t;
elseif etha==deg2rad(10)
    eff_factor_r=eff_factor_t*0.8;
elseif etha>deg2rad(10) && etha<deg2rad(20) %we caproximate to linear variation in each discretization of the correction factor
    eff_factor_r=eff_factor_t*(0.7-((deg2rad(20)-etha)*(-0.1))/(deg2rad(20)-deg2rad(10)));
elseif etha==deg2rad(20)
    eff_factor_r=eff_factor_t*0.7;
elseif etha>deg2rad(20) && etha<deg2rad(30)
    eff_factor_r=eff_factor_t*(0.53-((deg2rad(30)-etha)*(0.53-0.7))/(deg2rad(30)-deg2rad(20)));
elseif etha==deg2rad(30)
    eff_factor_r=eff_fatcor_t*0.53;
elseif etha>deg2rad(30) && etha<deg2rad(40)
    eff_factor_r=eff_factor_t*(0.45-((deg2rad(40)-etha)*(0.45-0.53))/(deg2rad(40)-deg2rad(30)));
elseif etha==deg2rad(40)
    eff_factor_r=eff_factor_t*0.45;
elseif etha>deg2rad(40) && etha<deg2rad(50)
    eff_factor_r=eff_factor_t*(0.4-((deg2rad(50)-etha)*(0.4-0.45))/(deg2rad(50)-deg2rad(40)));
elseif etha==deg2rad(50)
    eff_factor_r=eff_factor_t*0.4;
elseif etha>deg2rad(50) && etha<deg2rad(60)
    eff_factor_r=eff_factor_t*(0.37-((deg2rad(60)-etha)*(0.37-0.4))/(deg2rad(60)-deg2rad(50)));
elseif etha==deg2rad(60)
    eff_factor_r=eff_factor_t*0.37;
elseif etha>deg2rad(60) && etha<deg2rad(70)
    eff_factor_r=eff_factor_t*(0.34-((deg2rad(70)-etha)*(0.34-0.37))/(deg2rad(70)-deg2rad(60)));
end
A_alpha_l0=eff_factor_r*etha;
%% GEOMETRY Discretization
%X(N,1)  points of which is divided the span
if P_Distribution==0
    x(:,1)=lineal(b,N); %we stablish the coordinates x of each airfoil's point that makes the panel (Linear Dist.)
elseif P_Distribution==1
    x(:,1)=full_cosine(b,N); %we stablish the coordinates x of each airfoil's point that makes the panel (Full Cosine Dist.)
else
    output ERROR
end
%Calculation of the Cr and Ct
[Cr,Ct]=Cr_Ct_Calculation(b,A,Taper_ratio);
%Calculation of the Vortex Points
[x_vortex_1]= Vortex_points_1(x(:,1),Cr,Quarter_chord_sweep_angle,Dihedral,N);
[x_vortex_A]=Vortex_points_2(x(:,1),x_vortex_1,b,N,Dihedral);
[x_vortex_D]=Vortex_points_3(x(:,1),x_vortex_1,b,N,Dihedral);
x_vortex_B=[x_vortex_1(:,1),x_vortex_A(:,2),x_vortex_A(:,3)];
x_vortex_C=[x_vortex_1(:,1),x_vortex_D(:,2),x_vortex_D(:,3)];
%Calculation of the control points
[x_control]= Control_points(x_vortex_1,Cr,Ct,b,N,Dihedral);
%Calculation of the normal vectors
[normal_vector]=Normal_vector(alpha_zero_lift_initial,alpha_zero_lift_final,Total_twist,x_control,Dihedral,N,b,flap_initial_position,flap_final_position,A_alpha_l0);
%% Solver
[gamma,induced_velocity_w]=gamma_solver(x_vortex_A,x_vortex_B,x_vortex_C,x_vortex_D,x_control,normal_vector,v_inf,N,x_vortex_1);
A_Lift=Lifts(x,gamma,rho,v_inf_mod,N); %lift generated by each section of the wing
Lift=ones(1,N-1)*A_Lift; %total lift generated by the wing
CL=Lift/(0.5*rho*v_inf_mod^2*S); %lift coefficient of the wing
Cly=Cl_y(A_Lift,rho,v_inf_mod,x_vortex_B,x_vortex_C,Cr,Ct,b,N,x); %lift coefficient of each section
M_LE=Moment_LE(A_Lift,x_vortex_1,N); %leading edge moment
CMLE=CM_LE(M_LE,rho,S,v_inf_mod,Cr,Taper_ratio); %leading edge moment coefficient
[alpha_ind,CDi,Di]=induced_alpha_drag(gamma,induced_velocity_w,A_Lift,v_inf_mod,S,N,x );
function [ x ] = lineal(b,N) 
x=zeros(N,1);
x(1,1)=-b/2;
for i=2:N %Calculation of the points
    x(i,1)=b/(N-1)+x(i-1,1);
end
end
function [x] = full_cosine(b,N)
i=1:N;
x=-b/2 +(b/2)*(1-cos((i-1)*pi/(N-1)));
end
function [Cr,Ct] = Cr_Ct_Calculation(b,A,Taper_ratio)
Cr=2*b/(A*(1+Taper_ratio));%Calculation of the Cr
Ct=Cr*(Taper_ratio); %Calculation of the Ct
end
function[x_control] = Control_points(x_vortex_1 ,Cr,Ct,b,N,Dihedral)
%Calculation of the 3/4 tangent chord line
for i=1:N-1
    section_chord(i)=Cr-(Cr-Ct)*abs(x_vortex_1(i,2))/(0.5*b);
end
    
x_control=zeros(N-1,3);%Definition of the matrix
for i=1:N-1%Calculation of the second component (which is the same of the vortex_1)
x_control(i,2)=x_vortex_1(i,2);
end
for i=1:N-1%Calculation of the first componente
x_control(i,1)=x_vortex_1(i,1)+0.5*section_chord(i);
end
if(Dihedral~=0)%in case of dihedral we put a Z coordinate different than 0
for i=1:N-1
x_control(i,3)=sin(Dihedral)*abs(x_control(i,2));
end
end
end
function[x_vortex_1] = Vortex_points_1(x,Cr,Quarter_chord_sweep_angle,Dihedral,N)
x_vortex_1=zeros(N-1,3);%Definition of the matrix
for i=1:N-1%Calculation of the second component (which is in the middle of two points)
    x_vortex_1(i,2)=(x(i,1)+x(i+1,1))/2;
end
for i=1:N-1%Calculation of the first component, using the quarter chord sweep angle
    x_vortex_1(i,1)=0.25*Cr+abs(x_vortex_1(i,2))*tan(Quarter_chord_sweep_angle);
end
if(Dihedral~=0)%in case of dihedral we put a Z coordinate different than 0
    for i=1:N-1
        x_vortex_1(i,3)=sin(Dihedral)*abs(x_vortex_1(i,2));
    end
end
end
function[x_vortex_2] = Vortex_points_2(x,x_vortex_1,b,N,Dihedral)
x_vortex_2=zeros(N-1,3);%Definition of the matrix
for i=1:N-1%Calculation of the second component 
    x_vortex_2(i,2)=x(i);
end
for i=1:N-1%Calculation of the first component
    x_vortex_2(i,1)=(x_vortex_1(i,1))+20*b;
end
if(Dihedral~=0)
    for i=1:N-1%in case of dihedral we put a Z coordinate different than 0
        x_vortex_2(i,3)=sin(Dihedral)*abs(x_vortex_2(i,2));
    end
end
end
function[x_vortex_3] = Vortex_points_3(x,x_vortex_1,b,N,Dihedral)
x_vortex_3=zeros(N-1,3);%Definition of the matrix
for i=1:N-1%Calculation of the second component 
    x_vortex_3(i,2)=x(i+1);
end
for i=1:N-1%Calculation of the first component
    x_vortex_3(i,1)=(x_vortex_1(i,1))+20*b;
end
if(Dihedral~=0)
    for i=1:N-1 %in case of dihedral we put a Z coordinate different than 0
        x_vortex_3 (i,3)=sin(Dihedral)*abs(x_vortex_3(i,2));
    end
end
end
function[normal_vector]=Normal_vector(alpha_zero_lift_initial,alpha_zero_lift_final,Total_twist,x_control,Dihedral, N,b, flap_ini,flap_fin,A_alpha_l0)
%First we define the function of the zero lift line, where m is the slope
%and n the initial value.
m=((alpha_zero_lift_final-Total_twist-alpha_zero_lift_initial)*2/b);
n=alpha_zero_lift_initial;
rotation_matrix=[1 0 0; 0 cos(Dihedral) -sin(Dihedral); 0 sin(Dihedral) cos(Dihedral)]; %definition of the rotation matrix
normal_vector=zeros(N-1,3);%definition of the normal vector matrix
verification_vector=zeros(N-1,1); %we define this vector to see which points have the influence of the flap
for i=1:N-1 %in this loop we find which control points have the influence of the flap
    for j=1:length(flap_ini)
        if abs(x_control(i,2))>flap_ini(j) && abs(x_control(i,2))<flap_fin(j)
            verification_vector(i)=1;
        end
    end
end
for i=1:N-1 %in this loop we calculate the first component (the x)of the normal vector and the third component (the z)
    if verification_vector(i)==0
        normal_vector(i,1)=-sin(m*abs(x_control(i,2))+n);  %it is the sinus of the angle of the ZLL  
        normal_vector(i,3)=cos(m*abs(x_control(i,2))+n);    %it is the cosine of the angle of the ZLL
    else
        normal_vector(i,1)=-sin(m*abs(x_control(i,2))+n+A_alpha_l0);    
        normal_vector(i,3)=cos(m*abs(x_control(i,2))+n+A_alpha_l0);
    end
end
if(Dihedral~=0)%in case of Dihedral we apply a rotation matrix
for i=1:N-1
    normal_vector(i,:)=normal_vector(i,:)*rotation_matrix; 
end
end
end
function [ vector,modul ] = vector_r( x,y )
vector=(x-y)'; %we calculate the vector that goes from point y to x
modul=sqrt(vector'*vector); %we calculate the modul of this vector
end
function [ vel_induced ] = induced_velocity_line( x1, x2, xp )
%Computation of the induced velocity by a single vortex line
[r0,mod_r0]=vector_r(x2,x1);
[r1,mod_r1]=vector_r(xp,x1);
[r2,mod_r2]=vector_r(xp,x2);
ror=cross(r1,r2);
mod_ror=sqrt(ror'*ror);
vel_induced=(1/(4*pi))*((r0/mod_ror)'*(r1/mod_r1-r2/mod_r2))*ror/mod_ror;
if (mod_r1<=1e-6 || mod_r2<=1e-6 || mod_ror<=1e-6)
   vel_induced=zeros(3,1); 
end
end
function [gamma,w_induced ] = gamma_solver(xA,xB,xC,xD,xp,vn,v_inf,N,x )
M=N-1;
w_induced=zeros(M,M);
A=zeros(M,M);
B=zeros(M,1);
for i=1:M
   for j=1:M
      vel_induced_AB=induced_velocity_line(xA(j,:),xB(j,:),xp(i,:));
      vel_induced_BC=induced_velocity_line(xB(j,:),xC(j,:),xp(i,:));
      vel_induced_CD=induced_velocity_line(xC(j,:),xD(j,:),xp(i,:));
      vel_induced=vel_induced_AB+vel_induced_BC+vel_induced_CD; %induced velocity on 1 by horseshoe vortex j
      A(i,j)=vel_induced'*vn(i,:)'; %influence coefficient a(i,j)
      w_induced_AB=induced_velocity_line(xA(j,:),xB(j,:),x(i,:));
      w_induced_CD=induced_velocity_line(xC(j,:),xD(j,:),x(i,:));
      w_induced(i,j)=w_induced_AB(3)+w_induced_CD(3);
   end
   B(i)=-v_inf*vn(i,:)';
end
gamma=A\B;
end
function[Lift] = Lifts(x,gamma,rho,u,N)
Lift=zeros(N-1,1);
for i=1:N-1
    Lift(i)=abs(rho*(x(i+1)-x(i)))*gamma(i)*u;
end
end
function[Cl]= Cl_y(Lift,rho,u,x_vortex_B,x_vortex_C,Cr,Ct,b,N,x)
%Calculation of every panel surface
S_section=zeros(N-1,1);
partial_chord=zeros(N,1); %chord of each division
for i=1:N
  partial_chord(i)=Cr-(Cr-Ct)/(b/2)*abs(x(i));
end
partial_chord(N)=Ct;
for i=1:N-1
    S_section(i)=(partial_chord(i)+partial_chord(i+1))*0.5*abs(x_vortex_C(i,2)-x_vortex_B(i,2));
end
%Calculation of every Cl
Cl=zeros(N-1,1);
for i=1:N-1
   Cl(i)=Lift(i)/(0.5*rho*u*u*S_section(i));
end
end
function[Leading_Edge_Moment]=Moment_LE(Lift,x_vortex_1,N)
%Calculation of the Leading edge moment with the aproximations:
%cos(alpha)=1, Xle=0;
Leading_Edge_Moment=0;
for i=1:N-1
    Leading_Edge_Moment=Leading_Edge_Moment-(Lift(i)*x_vortex_1(i,1));     
end
end
function[CMLE]= CM_LE(Leading_Edge_Moment,rho,S,u,Cr,Taper_ratio)
%Calculation of the mean chord line
mean_chord=(2/3)*Cr*(1+Taper_ratio+Taper_ratio^2)/(1+Taper_ratio);
%Calculation of the CM_LE
CMLE=Leading_Edge_Moment/(0.5*rho*u*u*S*mean_chord);
end
function [ alpha_ind, Cdi, Di ] = induced_alpha_drag(gamma,w_wake,A_Lift,u_inf,S,N,x )
alpha_ind=zeros(N-1,1);
Cdi=0;
Di=0;
for i=1:N-1
    for j=1:N-1
        alpha_ind_partial(j)=gamma(j)*w_wake(i,j);
    end
    alpha_ind(i)=-1/u_inf*sum(alpha_ind_partial);
    Di=Di+A_Lift(i)*alpha_ind(i);
    Cdi=Cdi+gamma(i)*abs(x(i+1)-x(i))*alpha_ind(i);
end
Cdi=2*Cdi/(u_inf*S);
end