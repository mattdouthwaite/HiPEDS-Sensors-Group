classdef bluetoothOut < matlab.System & coder.ExternalDependency
    % bluetoothOut
    
    properties (Nontunable)
        % baudRate - the baud rate, in bits/s
        baudRate = 9600;
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            % Implement tasks that need to be performed only once,
            % such as pre-computed constants.
            if coder.target('Rtw')% done only for code gen
                %coder.cinclude('bluetooth.h');
                coder.ceval('btInit', obj.baudRate);
            end
        end
        
        function stepImpl(~, data)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('bluetooth.h');
                b = single(0);
                b = coder.ceval('btIsPaired');
                if b
                    coder.ceval('btSendBytes', data, length(data));
                end
            end
        end
        
        function releaseImpl(~)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('bluetooth.h');
                coder.ceval('btDisconnect');
            end
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Bluetooth Out';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                buildInfo.addIncludePaths({'../include'});
                buildInfo.addSourcePaths({'../src'});
                buildInfo.addSourceFiles({'bluetooth.cpp'});
            end
        end
    end
end