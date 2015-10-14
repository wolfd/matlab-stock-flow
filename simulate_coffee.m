import simulation
% Freshly brewed coffee
% Independent variables
cup_diameter = 8/100; %m
cup_wall_thickness = 0.7/100; %m
coffee_height = 10/100; %m

coffee_init_temp = 370; %K
room_temperature = 290; %K

coffee_specific_heat = 4186; % J / kg*K
coffee_density = 1000; %kg / m^3

cup_thermal_conductivity = 1.5; %W / m*K

coffee_air_transfer_coefficient = 100; %W / m^2*K

% Dependent variables
coffee_volume = pi * (cup_diameter / 2)^2 * coffee_height; % cm^3
coffee_mass = coffee_volume * coffee_density; % kg
coffee_heat_capacity = coffee_specific_heat * coffee_mass; % J / K
area_of_conduction = pi * cup_diameter * coffee_height ...
    + pi * (cup_diameter / 2)^2;
area_of_convection = pi * cup_diameter^2;

% Transformation functions
current_temp = @(energy, heat_capacity) energy / heat_capacity;

% Stock Flow code
s = simulation(linspace(0, 60 * 30, 100));

% Define stocks
stocks = containers.Map;
stocks('Coffee Energy') = coffee_init_temp * coffee_heat_capacity;

s.stocks(stocks)

% Define flows
conduction = @(t) (cup_thermal_conductivity * area_of_conduction / cup_wall_thickness) ...
    * (current_temp(s.get('Coffee Energy'), coffee_heat_capacity) - room_temperature);

s.flow('Heat Loss to Conduction', 'Coffee Energy', false, conduction);

convection = @(t) (coffee_air_transfer_coefficient * area_of_convection) ...
    * (current_temp(s.get('Coffee Energy'), coffee_heat_capacity) - room_temperature);

s.flow('Heat Loss to Convection', 'Coffee Energy', false, convection);

s.run()

% Plot results
coffee_energy = s.get('Coffee Energy');
figure();
hold on;
title('Coffee Temperature over Time');
xlabel('Time (min)');
ylabel('Coffee Temperature (K)');
plot(s.t / 60, current_temp(coffee_energy, coffee_heat_capacity));