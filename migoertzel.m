function yy = migoertzel(x)
%Mi implementacion del goertzel


%%inicializacion
N=800; %Tiene que ser minimo 800 para una resolucion de 10hz
dtmf=[697 770 852 941 1209 1336 1477 1633];
k = round(dtmf.*N/8000);
num_frecuencias = length(k);
y = zeros(num_frecuencias,1); %reserva de espacio para las respuestas
lx = length(x);
calculos = floor(lx/N);
yy = zeros(calculos,num_frecuencias);

%% Se calcula para las diferentes frecuencias
for i = 1:calculos
    % [1+(i-1)*N i*N] ;

    for tono = 1:num_frecuencias
        
        ang = 2*pi*(k(tono))/N;
        coef = cos(ang) * 2;


        s0 = 0;
        s1 = 0;
        s2 = 0;
        
        for ind = 1+(i-1)*N:i*N             %Para tener 800 muestras cada vez
            s0 = x(ind) + coef *s1 - s2 ;
            s2 = s1;
            s1 = s0;

        end
       
        s0 = coef*s1 - s2;                  %ultima entrada
        y(tono)=s0^2+s1^2-s1*s0*coef;       %valor a devolver para el tono

    end
    yy(i,:)=abs(y);
    
end
