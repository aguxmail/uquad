function [x_hat,P] = kalman_imu(x_hat,P,T,u,z)

%% Constantes

Ixx  = 2.32e-2; % Tensor de inercia del quad - según x
Iyy  = 2.32e-2; % Tensor de inercia del quad - según y
Izz  = 4.37e-2; % Tensor de inercia del quad - según z
Izzm = 1.54e-5; % Tensor de inercia de los motores - segun z
L    = 0.29;    % Largo en metros del los brazos del quad
M    = 1.541;   % Masa del Quad en kg
g    = 9.81;    % Aceleracion gravitatoria
Ns   = 12;      % Largo del vector de estados

% Q = diag(.1*[100 100 100 100 100 100 100 100 100 10 10 10]); 
% R = diag(1000*[.1 .1 .1 100 100 100 10 10 10 10]);           

Q = diag(1*[100 100 100 1 1 1 10 10 10 1 1 1]);
R = diag(100*[100 100 100 100 100 100 1 1 1 100]);

%% Entradas

dw = zeros(4);  % Derivada de w. Cada columna corresponde a 1 motor
TM = drive(u);  % Fuerzas ejercidas por los motores en N. Cada columna corresponde a 1 motor.
D  = drag(u);   % Torque de Drag ejercido por los motores en N*m. Cada columna corresponde a cada motor

%% Funciones
     
f = @(x,y,z,psi,phi,theta,vqx,vqy,vqz,wqx,wqy,wqz,w,dw,TM,D,T) [ ...    
    x     + T *(vqx*cos(phi)*cos(theta)+vqy*(cos(theta)*sin(phi)*sin(psi)-cos(phi)*sin(theta))+vqz*(sin(psi)*sin(theta)+cos(psi)*cos(theta)*sin(phi)) ) ;
    y     + T *(vqx*cos(phi)*sin(theta)+vqy*(sin(theta)*sin(phi)*sin(psi)+cos(psi)*cos(theta))+vqz*(cos(psi)*sin(theta)*sin(phi)-cos(theta)*sin(psi)) ) ;
    z     + T *(-vqx*sin(phi)+vqy*cos(phi)*sin(psi)+vqz*cos(psi)*cos(psi));
    ...
    psi   + T*( wqx+wqz*tan(phi)*cos(psi)+wqy*tan(phi)*sin(psi));
    phi   + T*( wqy*cos(psi)-wqz*sin(psi));
    theta + T*( wqz*cos(psi)/cos(phi)+wqy*sin(psi)/cos(phi));
    ...
    vqx   + T*( vqy*wqz-vqz*wqy+g*sin(phi));
    vqy   + T*( vqz*wqx-vqx*wqz-g*cos(phi)*sin(psi));
    vqz   + T*( vqx*wqy-vqy*wqx-g*cos(phi)*cos(psi)+1/M*(TM(1)+TM(2)+TM(3)+TM(4)));
    ...   
    wqx   + T*( wqy*wqz*(Iyy-Izz)+wqy*Izzm*(w(1)-w(2)+w(3)-w(4))+L*(TM(2)-TM(4)) )/Ixx ;
    wqy   + T*( wqx*wqz*(Izz-Ixx)+wqx*Izzm*(w(1)-w(2)+w(3)-w(4))+L*(TM(3)-TM(1)) )/Iyy;
    wqz   + T*( -Izzm*(dw(1)-dw(2)+dw(3)-dw(4))+(D(1)-D(2)+D(3)-D(4)) )/Izz ...
    ];

h = @(z,psi,phi,theta,vqx,vqy,vqz,wqx,wqy,wqz,TM) [ ... 
    psi ; 
    phi ; 
    theta ; 
    0;
    0;
    1/M*(TM(1)+TM(2)+TM(3)+TM(4));
    wqx ; 
    wqy ; 
    wqz ;
    z ...
    ];

F = @(psi,phi,theta,vqx,vqy,vqz,wqx,wqy,wqz,w,T) ...
	[ ... 
    1, 0, 0,                          T*(vqz*(cos(psi)*sin(theta) - cos(theta)*sin(phi)*sin(psi)) + vqy*cos(psi)*cos(theta)*sin(phi)), T*(vqy*(sin(phi)*sin(theta) + cos(phi)*cos(theta)*sin(psi)) - vqx*cos(theta)*sin(phi) + vqz*cos(phi)*cos(psi)*cos(theta)), -T*(vqy*(cos(phi)*cos(theta) + sin(phi)*sin(psi)*sin(theta)) - vqz*(cos(theta)*sin(psi) - cos(psi)*sin(phi)*sin(theta)) + vqx*cos(phi)*sin(theta)), T*cos(phi)*cos(theta), -T*(cos(phi)*sin(theta) - cos(theta)*sin(phi)*sin(psi)),  T*(sin(psi)*sin(theta) + cos(psi)*cos(theta)*sin(phi)),                                                       0,                                                            0,                        0 ;
    0, 1, 0, -T*(vqy*(cos(theta)*sin(psi) - cos(psi)*sin(phi)*sin(theta)) + vqz*(cos(psi)*cos(theta) + sin(phi)*sin(psi)*sin(theta))),                         T*(vqz*cos(phi)*cos(psi)*sin(theta) - vqx*sin(phi)*sin(theta) + vqy*cos(phi)*sin(psi)*sin(theta)),  T*(vqz*(sin(psi)*sin(theta) + cos(psi)*cos(theta)*sin(phi)) - vqy*(cos(psi)*sin(theta) - cos(theta)*sin(phi)*sin(psi)) + vqx*cos(phi)*cos(theta)), T*cos(phi)*sin(theta),  T*(cos(psi)*cos(theta) + sin(phi)*sin(psi)*sin(theta)), -T*(cos(theta)*sin(psi) - cos(psi)*sin(phi)*sin(theta)),                                                       0,                                                            0,                        0 ;    0, 0, 1,                                                                      T*(vqy*cos(phi)*cos(psi) - 2*vqz*cos(psi)*sin(psi)),                                                                                 -T*(vqx*cos(phi) + vqy*sin(phi)*sin(psi)),                                                                                                                                                  0,           -T*sin(phi),                                     T*cos(phi)*sin(psi),                                            T*cos(psi)^2,                                                       0,                                                            0,                        0 ;
    0, 0, 0,                                                                    T*(wqy*cos(psi)*tan(phi) - wqz*sin(psi)*tan(phi)) + 1,                                                         T*(wqz*cos(psi)*(tan(phi)^2 + 1) + wqy*sin(psi)*(tan(phi)^2 + 1)),                                                                                                                                                  0,                     0,                                                       0,                                                       0,                                                       T,                                          T*sin(psi)*tan(phi),      T*cos(psi)*tan(phi) ;
    0, 0, 0,                                                                                         -T*(wqz*cos(psi) + wqy*sin(psi)),                                                                                                                         1,                                                                                                                                                  0,                     0,                                                       0,                                                       0,                                                       0,                                                   T*cos(psi),              -T*sin(psi) ;
    0, 0, 0,                                                                    T*((wqy*cos(psi))/cos(phi) - (wqz*sin(psi))/cos(phi)),                                               T*((wqz*cos(psi)*sin(phi))/cos(phi)^2 + (wqy*sin(phi)*sin(psi))/cos(phi)^2),                                                                                                                                                  1,                     0,                                                       0,                                                       0,                                                       0,                                        (T*sin(psi))/cos(phi),    (T*cos(psi))/cos(phi) ;
    0, 0, 0,                                                                                                                        0,                                                                                                              T*g*cos(phi),                                                                                                                                                  0,                     1,                                                   T*wqz,                                                  -T*wqy,                                                       0,                                                       -T*vqz,                    T*vqy ;
    0, 0, 0,                                                                                                   -T*g*cos(phi)*cos(psi),                                                                                                     T*g*sin(phi)*sin(psi),                                                                                                                                                  0,                -T*wqz,                                                       1,                                                   T*wqx,                                                   T*vqz,                                                            0,                   -T*vqx ;
    0, 0, 0,                                                                                                    T*g*cos(phi)*sin(psi),                                                                                                     T*g*cos(psi)*sin(phi),                                                                                                                                                  0,                 T*wqy,                                                  -T*wqx,                                                       1,                                                  -T*vqy,                                                        T*vqx,                        0 ;
    0, 0, 0,                                                                                                                        0,                                                                                                                         0,                                                                                                                                                  0,                     0,                                                       0,                                                       0,                                                       1, (T*(wqz*(Iyy - Izz) + Izzm*(w(1) - w(2) + w(3) - w(4))))/Ixx,  (T*wqy*(Iyy - Izz))/Ixx ;
    0, 0, 0,                                                                                                                        0,                                                                                                                         0,                                                                                                                                                  0,                     0,                                                       0,                                                       0, -(T*(wqz*(Ixx - Izz) - Izzm*(w(1)-w(2)+w(3)-w(4))))/Iyy,                                                            1, -(T*wqx*(Ixx - Izz))/Iyy ;
    0, 0, 0,                                                                                                                        0,                                                                                                                         0,                                                                                                                                                  0,                     0,                                                       0,                                                       0,                                                       0,                                                            0,                        1 ...
    ]; 
 
H = @() ...
    [ ...
    0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
    0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0
    0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
    0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ];

%% Kalman

% Predict
x_   = f(x_hat(1),x_hat(2),x_hat(3),x_hat(4),x_hat(5),x_hat(6),x_hat(7),...
    x_hat(8),x_hat(9),x_hat(10),x_hat(11),x_hat(12),u,dw,TM,D,T);

Fk_1 = F(x_hat(4),x_hat(5),x_hat(6),x_hat(7),x_hat(8),x_hat(9), ...
    x_hat(10),x_hat(11),x_hat(12),u,T);

P_   = Fk_1 * P * Fk_1'+ Q; 

% Update
yk         = z - h(x_(3),x_(4),x_(5),x_(6),x_(7),x_(8),x_(9),x_(10), ...
    x_(11),x_(12),TM);
Hk         = H();
Sk         = Hk*P_*Hk' + R;
Kk         = P_*Hk'*Sk^-1;
x_hat      = x_ + Kk*yk;
P          = (eye(Ns)-Kk*Hk)*P_;