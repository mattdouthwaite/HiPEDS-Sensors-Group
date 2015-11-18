classdef rpmSensor < matlab.System & coder.ExternalDependency
    % rpmSensor
        
    methods (Access = protected)
        function setupImpl(~)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('rpmsensor.h');
                coder.ceval('rpmInit');
            end
        end
        
        function rpm = stepImpl(~)
            rpm = 0;
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('rpmsensor.h');
                rpm = coder.ceval('getRpm');
            end
        end
        
        function releaseImpl(~)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('rpmsensor.h');
                coder.ceval('rpmRelease');
            end
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'RPM Sensor';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                blockRoot = 'C:/Users/dc315/FreedomBT';
                buildInfo.addIncludePaths({[blockRoot, '/include']});
                buildInfo.addSourcePaths({[blockRoot, '/src']});
                buildInfo.addSourceFiles({'rpmsensor.cpp'});
            end
        end
    end
end
