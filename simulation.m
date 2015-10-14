% Simulation Library - Danny Wolf
% Based on 
classdef simulation < handle
    properties
        t % Time axis
        ix % index of current array for different keys
        flows % map of flow name to flow data
        current % current values
        done % boolean flag indicating whether the simulation has finished
        results % the stored values
    end
    
    methods
        function self = simulation(t)
            self.t = t;
            self.ix = containers.Map('KeyType','char','ValueType','int32');
            self.flows = containers.Map;
            self.current = [];
            self.done = false;
            self.results = containers.Map;
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
                stock = self.results(:, self.ix(key));
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
        
        function d = xdot(self, y, t, dt)
            self.current = y;
            d = zeros(1, length(y));
            
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
        
        function [] = run(self)
            self.done = false;
            
            self.results = zeros(length(self.t), length(self.current));
            self.results(1, :) = self.current;
            
            for i = 2:length(self.t)
                dt = self.t(i) - self.t(i - 1);
                self.results(i, :) = self.results(i - 1, :) + self.xdot(self.results(i - 1, :), self.t(i), dt);
            end
            
            self.done = true;
            self.current = self.results(1, :); % restore initial conditions
        end
    end
end