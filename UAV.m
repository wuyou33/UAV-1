classdef UAV
    
    
    %%
    properties
        mass=1;
        position = [-5, 0, 0]';
        orientation = [0, 0, 0]';
        
        momentum=ones(3,1);
        states=[0 0 0 0 0 0]';
        extended_states=zeros(12,1);
        
        trust_constant=1;
        cross_section_area=[40 40 10000]'/10000;
        C=1;
        
    end % Properties
    
    
    %% list of functions for UAV class
    methods
        %% Class constructor
        function obj=UAV()
            
            
            
        end % UAV class constructor
        
        
        %%
        function obj = setPosition(obj, position)
            obj.extended_states(1) = position(1);
            obj.extended_states(2) = position(2);
            obj.extended_states(3) = position(3);
        end
        
        
        %%
        function obj = setOrientation(obj, orientation)
            obj.extended_states(4) = orientation(1);
            obj.extended_states(5) = orientation(2);
            obj.extended_states(6) = orientation(3);
        end
        
        
        %%
        function position = getPosition(obj)
            position = zeros(3,1);
            position(1) = obj.extended_states(1);
            position(2) = obj.extended_states(2);
            position(3) = obj.extended_states(3);
        end
        
        
        %%
        function orientation = getOrientation(obj)
            orientation = zeros(3,1);
            orientation(1) = obj.extended_states(4);
            orientation(2) = obj.extended_states(5);
            orientation(3) = obj.extended_states(6);
        end
        
        
        %%
        function velocity = getVelocity(obj)
            velocity = zeros(3,1);
            velocity(1) = obj.extended_states(7);
            velocity(2) = obj.extended_states(8);
            velocity(3) = obj.extended_states(9);
            velocity = rotation(obj) * velocity;
        end
        
        
        %%
        function angular_rates = getAngularRate(obj)
            angular_rates = zeros(3,1);
            angular_rates(1) = obj.extended_states(10);
            angular_rates(2) = obj.extended_states(11);
            angular_rates(3) = obj.extended_states(12);
            angular_rates = rotation(obj) * angular_rates;
        end
        
        
        %%
        function rates=hexacopterModel(obj,inputs)
            % Hexacopter system modelling
            %
            %   states: [u v w p q r]' where u, v, w are linear velocities and p, q,
            %          and r are rotational velocities
            %
            %   inputs: [force torque]'
            %
            %
            
            % Initialization
            % number_of_states=length(states);
            % number_of_inputs=length(inputs);
            
            rates=zeros(size(obj.states));
            
            inputs=forceCalculation(obj,inputs);
            
            [u,v,w,p,q,r]=deal(obj.states(1),obj.states(2),obj.states(3),...
                obj.states(4),obj.states(5),obj.states(6));
            
            [Fx, Fy, Fz, Tx, Ty, Tz]=deal(inputs(1), inputs(2), inputs(3), inputs(4), inputs(5), inputs(6));
            
            rates(1) = (r*v - q*w) + Fx/obj.mass;
            rates(2) = (p*w - r*u) + Fy/obj.mass;
            rates(3) = (q*u - p*v) + Fz/obj.mass;
            rates(4)=(q*r*(obj.momentum(2)-obj.momentum(3))+Tx)/obj.momentum(1);
            rates(5)=(p*r*(obj.momentum(3)-obj.momentum(1))+Ty)/obj.momentum(2);
            rates(6)=(q*p*(obj.momentum(1)-obj.momentum(2))+Tz)/obj.momentum(3);
            
            fprintf('+===========+===========+===========+\n')
            fprintf('|FX:   %+0.2f|FY:   %+0.2f|FZ:   %+0.2f|\n',Fx,Fy,Fz);
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|AccX: %+0.2f|AccY: %+0.2f|AccZ: %+0.2f|\n',rates(1),rates(2),rates(3));
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|TX:   %+0.2f|TY:   %+0.2f|TZ:   %+0.2f|\n',Tx,Ty,Tz);
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|AngX: %+0.2f|AngY: %+0.2f|AngZ: %+0.2f|\n',rates(4),rates(5),rates(6));
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|VelX: %+0.2f|VelY: %+0.2f|VelZ: %+0.2f|\n',obj.states(1),obj.states(2),obj.states(3));
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|OriX: %+0.2f|OriY: %+0.2f|OriZ: %+0.2f|\n',obj.states(4), obj.states(5), obj.states(6));
            fprintf('+-----------+-----------+-----------+\n\n')
        end % HexacopterModel
        
        
        %%
        function rates = hexacopterExtendedModel(obj,inputs)
            % states are:
            %   position in earth frame, orientation in earth frame,
            %   velocity and angular rate
            
            inputs=forceCalculation(obj,inputs);
            
            [u,v,w,p,q,r]=deal(obj.extended_states(7),obj.extended_states(8),obj.extended_states(9),...
                obj.extended_states(10),obj.extended_states(11),obj.extended_states(12));
            
            [Fx, Fy, Fz, Tx, Ty, Tz]=deal(inputs(1), inputs(2), inputs(3), inputs(4), inputs(5), inputs(6));
                        
            rates(1:3) = rotation(obj) * [u; v; w];
            rates(4:6) = rotation(obj) * [p; q; r];
            rates(7) = (r*v - q*w) + Fx/obj.mass;
            rates(8) = (p*w - r*u) + Fy/obj.mass;
            rates(9) = (q*u - p*v) + Fz/obj.mass;
            rates(10)=(q*r*(obj.momentum(2)-obj.momentum(3))+Tx)/obj.momentum(1);
            rates(11)=(p*r*(obj.momentum(3)-obj.momentum(1))+Ty)/obj.momentum(2);
            rates(12)=(q*p*(obj.momentum(1)-obj.momentum(2))+Tz)/obj.momentum(3);
            
            rates=rates';
            
            fprintf('+===========+===========+===========+\n')
            fprintf('|FX:   %+0.2f|FY:   %+0.2f|FZ:   %+0.2f|\n',Fx,Fy,Fz);
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|VelX: %+0.2f|VelY: %+0.2f|VelZ: %+0.2f|\n',rates(1),rates(2),rates(3));
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|TX:   %+0.2f|TY:   %+0.2f|TZ:   %+0.2f|\n',Tx,Ty,Tz);
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|OmgX: %+0.2f|OmgY: %+0.2f|OmgZ: %+0.2f|\n',rates(4),rates(5),rates(6));
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|PosX: %+0.2f|PosY: %+0.2f|PosZ: %+0.2f|\n',obj.extended_states(1),obj.extended_states(2),obj.extended_states(3));
            fprintf('+-----------+-----------+-----------+\n')
            fprintf('|OriX: %+0.2f|OriY: %+0.2f|OriZ: %+0.2f|\n',obj.extended_states(4), obj.extended_states(5), obj.extended_states(6));
            fprintf('+-----------+-----------+-----------+\n\n')
            
            
        end % HexacopterExtendedModel
        
        
        %%
        function forces=forceCalculation(obj,inputs)
            gg = 9.8;
            mu =0;
            friction=.5;
            air_rho=1.225;
            
            gravity=obj.mass*gg*[sin(obj.extended_states(5)),...
                -cos(obj.extended_states(5))*sin(obj.extended_states(4)),...
                -cos(obj.extended_states(5))*cos(obj.extended_states(4))]';
            
            thrust_vector=[0,0,inputs(3)]';
            
            rotor_drag=-mu*[obj.extended_states(7),obj.extended_states(8),0]';
            
            air_resistance=-[obj.cross_section_area.*obj.extended_states(7:9).*abs(obj.extended_states(7:9))].*air_rho*friction/2;
            
            forces=gravity+thrust_vector+rotor_drag+air_resistance;
            
            % TODO: add torque instead of inputs(4:end) here
            
            forces=[forces;inputs(4:end)];
            
        end % ForceCalculation
        
        
        %%
        function torque=torqueCalculation()
            
            yaw_counter_torque=[0,0,obj.propeller_inertia*obj.propeller_speed_change_rate]';
            
            gyroscopic_effect=obj.propeller_inertia*obj.overall_propeller_speed*[]'; % ?????
            
        end % TorqueCalculation
        
        
        %%
        function obj = simulateUAV(obj, inputs, timestep)
            
            acceleration =  hexacopterModel(obj, inputs);
            obj.position = (rotation(obj)*acceleration(1:3) * timestep^2)/2 + rotation(obj)*obj.states(1:3) * timestep + obj.position;
            obj.orientation = (rotation(obj)*acceleration(4:6) * timestep^2)/2 + rotation(obj)*obj.states(4:6) * timestep + obj.orientation;
            obj.states=acceleration*timestep+obj.states;
        end % movement function
        
        
        %%
        function obj = simulateExtendedUAV(obj, inputs, timestep)
            
            rates =  hexacopterExtendedModel(obj, inputs);
            obj.extended_states = rates * timestep + obj.extended_states;
            
            obj.position=obj.extended_states(1:3);
            obj.orientation = obj.extended_states(4:6);
        end % simulateExtendedUAV
        
        
        %%
        function R_overall = rotation(obj)
            
            roll = obj.extended_states(4);
            pitch = obj.extended_states(5);
            yaw = obj.extended_states(6);
            
            RX = [1, 0, 0;
                0, cos(roll), -sin(roll);
                0, sin(roll), cos(roll)];
            RY = [cos(pitch), 0, sin(pitch);
                0, 1, 0;
                -sin(pitch), 0, cos(pitch)];
            RZ = [cos(yaw), -sin(yaw), 0;
                sin(yaw), cos(yaw), 0;
                0, 0, 1];
            
            R_overall = RZ * RY * RX;
        end
        
        
        %%
        function showUAV(obj)
            % description
            %
            radius = 1;
            degrees=-pi*([0:60:300]+30) / 180;
            x_geometrics = radius * cos(degrees);
            y_geometrics = radius * sin(degrees);
            axis_length=1;
            
            x = obj.position(1);
            y = obj.position(2);
            z = obj.position(3);
            
            body = rotation(obj) * [x_geometrics; y_geometrics; zeros(size(x_geometrics))];
            
            body(1,:) = body(1,:) + x;
            body(2,:) = body(2,:) + y;
            body(3,:) = body(3,:) + z;
            
            plot3(body(1,:), body(2,:), body(3,:),'--','LineWidth',3,'MarkerSize',20);
            hold on
            plot3([body(1,end),body(1,1)], [body(2,end),body(2,1)], [body(3,end),body(3,1)],'--r*','LineWidth',3,'MarkerSize',10)
            
        end % showHexa function
        
        %%
        function showExtendedUAV(obj)
            
            radius = 1;
            degrees=-pi*([0:60:360]+30) / 180;
            x_geometrics = radius * cos(degrees);
            y_geometrics = radius * sin(degrees);
            axis_length=1;
            
            x = obj.extended_states(1);
            y = obj.extended_states(2);
            z = obj.extended_states(3);
                        
            body = rotation(obj) * [x_geometrics; y_geometrics; zeros(size(x_geometrics))];
            
            body(1,:) = body(1,:) + x;
            body(2,:) = body(2,:) + y;
            body(3,:) = body(3,:) + z;
            
            plot3(body(1,:), body(2,:), body(3,:),'--','LineWidth',3,'MarkerSize',20)
            hold on
            plot3(body(1,6), body(2,6), body(3,6),'r*','LineWidth',3,'MarkerSize',10)
            plot3(body(1,1), body(2,1), body(3,1),'g*','LineWidth',3,'MarkerSize',10)
            
        end % showExtendedUAV
        
        
        %%
        function history(obj)
            
        end % history
        
        
    end % Methods
    
end