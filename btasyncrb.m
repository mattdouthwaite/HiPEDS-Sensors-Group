function btasyncrb(block)
%SSERIALRB Underlying S-Function for the ICT Serial Receive block.
%
%    SSERIALRB(BLOCK) is the underlying S-Function for the ICT Serial Receive
%    block.

%    SS 10/15/07
%    Copyright 2007-2011 The MathWorks, Inc.


% The setup method is used to setup the basic attributes of the
% S-function such as ports, parameters, etc. Do not add any other
% calls to the main body of the function.
setup(block);
SetOutputPortDataType(block);
SetOutputPortDims(block);

end
%endfunction

%% Function: setup ===================================================
%   Set up the S-function block's basic characteristics such as:
%   - Output ports
%   - Dialog parameters
%   - Options
%
function setup(block)
disp('setup()');

% Parameters:
% 1:ComPortMenu,
% 2:ComPort,
% 3:ObjConstructor,
% 4:Header,
% 5:Terminator,
% 6:DataSize,
% 7:DataType,
% 8:EnableBlockingMode,
% 9:ActionDataUnavailable,
%10:CustomValue,
%11:SampleTime

% Register number of ports
if strcmpi(block.DialogPrm(8).Data, 'on')
    block.NumOutputPorts = 1;
else
    block.NumOutputPorts = 2;
end
block.NumInputPorts = 0;

% Register parameters
block.NumDialogPrms = 11;
block.DialogPrmsTunable = {'Nontunable', 'Nontunable', 'Nontunable', ...
    'Nontunable', 'Nontunable', 'Nontunable', ...
    'Nontunable', 'Nontunable', 'Nontunable', ...
    'Nontunable', 'Nontunable'};

% Register sample times
block.SampleTimes = [block.DialogPrm(11).Data 0];

% Specify if Accelerator should use TLC or call back into
% MATLAB file
block.SetAccelRunOnTLC(false);
block.SetSimViewingDevice(true);% no TLC required

% Allow multi dimensional signal support.
block.AllowSignalsWithMoreThan2D = true;

%% -----------------------------------------------------------------
%% Register methods called during update diagram/compilation
%% -----------------------------------------------------------------

%%
%% SetOutputPortDimensions:
%%   Functionality    : Check and set output port dimensions
block.RegBlockMethod('SetOutputPortDimensions', @SetOutputPortDims);

%%
%% SetOutputPortDatatype:
%%   Functionality    : Check and set output port datatypes
block.RegBlockMethod('SetOutputPortDataType', @SetOutputPortDataType);

%%
%% PostPropagationSetup:
%%   Functionality    : Setup work areas and state variables. Can
%%                      also register run-time methods here
%%   C-Mex counterpart: mdlSetWorkWidths
%%
block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
%% -----------------------------------------------------------------
%% Register methods called at run-time
%% -----------------------------------------------------------------

%%
%% Start:
%%   Functionality    : Called in order to initialize state and work
%%                      area values
block.RegBlockMethod('Start', @Start);

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
block.RegBlockMethod('Outputs', @Outputs);

%%
%% Terminate:
%%   Functionality    : Called at the end of simulation for cleanup
%%
block.RegBlockMethod('Terminate', @Terminate);
end
%endfunction setup

%% DoPostPropSetup - Set up the Dwork elements.
function DoPostPropSetup(block)
disp('DoPostPropSetup()');

%== Restore output value during timeout to Dwork space ==
block.NumDworks = 1;
block.Dwork(1).Name            = 'CustomOutValue';
block.Dwork(1).Dimensions      = prod(block.OutputPort(1).Dimensions);
block.Dwork(1).DatatypeID      = block.OutputPort(1).DatatypeID;
block.Dwork(1).Complexity      = 'Real'; % real

end
%endfunction

%% SetOutputPortDims - Check and set output port dimensions
function SetOutputPortDims(block)
disp('SetOutputPortDims()');

% Set the output port dimensions.
block.OutputPort(1).Dimensions = block.DialogPrm(6).Data;

% If there are two ports, set the second one too.
if (block.NumOutputPorts == 2)
    block.OutputPort(2).Dimensions = 1; % Size is 1.
end
end
%endfunction SetOutputPortDims

%% SetOutputPortDataType - Check and set output port datatypes
function SetOutputPortDataType(block)
disp('SetOutputPortDataType()');

% Set the output port properties.
block.OutputPort(1).DatatypeID = tamslgate('privateslgetdatatypeid', ...
    block.DialogPrm(7).Data);
block.OutputPort(1).Complexity  = 'Real';
block.OutputPort(1).SamplingMode = 'Sample';

% If there are two ports, set the second one too.
if (block.NumOutputPorts == 2)
    block.OutputPort(2).DatatypeID = 0; % double
    block.OutputPort(2).SamplingMode = 'Sample';
    block.OutputPort(2).Complexity = 'Real';
end
end
%endfunction SetOutputPortDataType

%% Start - Set up the environment by creating objects, initializing data.
function Start(block)
disp('Start()');

% Get the block name.
blockName = get_param(block.BlockHandle, 'Name');

% Create the object.
serialObj = Bluetooth('HC-05', 1);

% Set the block parameters.
serialObj.Timeout = 10;

% Store the serial object to receive blocks' user data field.
userData = get_param(block.BlockHandle, 'UserData');
userData.zzzSimulinkSerialObject = serialObj;
set_param(block.BlockHandle, 'UserData', userData);

% Set the error value in Dwork element.
customValue = block.DialogPrm(10);
% Find the data type.
dataType = class(block.OutputPort(1).Data);

% Cast data to required type.
data = cast(customValue.Data, dataType);
% Check the dimensions of the custom value.
if isequal(prod(customValue.Dimensions), prod(block.OutputPort(1).Dimensions))
    data = data(:)';
elseif isscalar(customValue.Data) % If scalar, build it to same size as output port.
    data = repmat(data, 1, prod(block.OutputPort(1).Dimensions));
else
    % Display error if mismatch.
    error(message('instrument:instrumentblks:outputSizeMismatch'));
end
% Save the work element.
block.Dwork(1).Data = data;

sizeOfData = block.OutputPort(1).DataStorageSize;

callback = @(bt,evt) readAndSetData(...
    block, serialObj, sizeOfData, block.OutputPort(1).Datatype);
serialObj.BytesAvailableFcnMode  = 'byte';
serialObj.BytesAvailableFcnCount = sizeOfData;
serialObj.BytesAvailableFcn      = callback;

disp(serialObj);
disp(get(serialObj));

fopen(serialObj);
end
%endfunction Start

function readAndSetData(block, bt, numBytes, datatype)
disp('readAndSetData()');
data = typecast(uint8(fread(bt, numBytes)), datatype);
block.Dwork(1).Data = data;
%disp(data);
end

%% Outputs - Generate block outputs at every timestep.
function Outputs(block)
disp('Outputs()');
data = block.Dwork(1).Data;
disp(data);
block.OutputPort(1).Data = data;
end
% endfunction Outputs

%% Terminate - Clean up
function Terminate(block)
disp('Terminate()');

% Call the terminate method for serial object.
% Get the ID of the serial object.
userData = get_param(block.BlockHandle, 'UserData');

if isfield(userData, 'zzzSimulinkSerialObject')
    serialObj = userData.zzzSimulinkSerialObject;
    
    % Check if the object is still valid.
    if isa(serialObj, 'Bluetooth') && isvalid(serialObj)
        % Check if receive and transmit operations are done.
        while ~(strcmpi(get(serialObj, 'TransferStatus'), 'idle'))
            % Pause for some time for asynchronous operation to get over.
            pause(0.01);
        end
        % Close and delete is done by the configuration block.
        fclose(serialObj);
    end
end
userData = [];
set(block.BlockHandle, 'UserData', userData);
end %endfunction