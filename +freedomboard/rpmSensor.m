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
        
        function [leftRpm, rightRpm] = stepImpl(~)
            leftRpm = 0;
            rightRpm = 0;
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('rpmsensor.h');
                leftRpm = coder.ceval('getLeftRpm');
                rightRpm = coder.ceval('getRightRpm');
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
                buildInfo.addIncludePaths({'../include'});
                buildInfo.addSourcePaths({'../src'});
                buildInfo.addSourceFiles({'rpmsensor.cpp'});
            end
        end
    end
end