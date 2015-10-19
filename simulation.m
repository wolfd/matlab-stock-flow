% Simulation Library - Danny Wolf
% Based on https://github.com/jdherman/stockflow
classdef simulation < handle
    properties
        t % Time axis
        ix % index of current array for different keys
        flows % map of flow name to flow data
        current % current values
        done % boolean flag indicating whether the simulation has finished
        results % the stored values
        use_ode45 % use integrator
    end
    
    methods
        function self = simulation(t)
            self.t = t;
            self.ix = containers.Map('KeyType','char','ValueType','int32');
            self.flows = containers.Map;
            self.current = [];
            self.done = false;
            self.results = containers.Map;
            self.use_ode45 = false;
        end

        function [] = new_state_var(self, key, IC)
            % optional: validate key
            self.current(end + 1) = IC;
            self.ix(key) = length(self.current);
        end
        
        function stock = get(self, key)
            if ~self.done
                stock = self.current(self.ix(key));
            else
                stock = self.results(self.ix(key), :);
            end
        end
        
        function [] = stocks(self, ic_dict)
            for k = ic_dict.keys
                key = cell2mat(k);
                self.new_state_var(key, cell2mat(ic_dict.values(k)));
            end
        end
        
        function [] = flow(self, key, from, to, func)
            self.new_state_var(key, func(0))
            if from ~= false
                from_f = self.ix(from);
            else
                from_f = false;
            end
            
            if to ~= false
                to_f = self.ix(to);
            else
                to_f = false;
            end
            
            self.flows(key) = {from_f, to_f, func};
        end
        
        function d = xdot(self, t, y, dt)
            self.current = y;
            d = zeros(length(y), 1);
            
            for flow_key = self.flows.keys
                key = cell2mat(flow_key); % needed for accessing ix map
                flow = self.flows.values{flow_key};
                flow = flow{1};
                
                from = cell2mat(flow(1));
                to = cell2mat(flow(2));
                
                flow_func = cell2mat(flow(3));
                
                i = self.ix(key);
                ft = flow_func(t);
                ft = ft * dt;
                
                d(i) = ft - self.current(i);
                
                % From
                if from ~= false
                    d(from) = d(from) - ft;
                end
                
                % To
                if to ~= false
                    d(to) = d(to) - ft;
                end
            end
        end
        
        function [] = run(self, use_ode45)
            if nargin < 2
                self.use_ode45 = false;
            else
                self.use_ode45 = use_ode45;
            end

            self.done = false;
            
            self.results = zeros(length(self.current), length(self.t));
            self.results(:, 1) = self.current;

            if self.use_ode45
                summed = @(t, y) self.xdot(t, y, 1);
                ode_output = ode45(summed, [self.t(1), self.t(end)], self.results(:, 1));
                self.t = ode_output.x;
                self.results = ode_output.y;
            else
                for i = 2:length(self.t)
                    dt = self.t(i) - self.t(i - 1);
                    self.results(:, i) = self.results(:, i - 1) + self.xdot(self.t(i), self.results(:, i - 1), dt);
                end
            end
            
            self.done = true;
            self.current = self.results(:, 1); % restore initial conditions
        end
    end
end