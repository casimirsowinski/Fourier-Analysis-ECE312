%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tDfD - realtime spectral analyzer
% Casimir Sowinski, 2015
% Written for ECE-312 final project
% A spectral analyzer with a GUI that shows the spectral content of an 
% audio stream. If it doesn't work, change the input device in the 'Sound' 
% window found in 'Control Panel' then restart tDfD.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = GUI_test_01(varargin)
% GUI_TEST_01 MATLAB code for GUI_test_01.fig
%      GUI_TEST_01, by itself, creates a new GUI_TEST_01 or raises the existing
%      singleton*.
%
%      H = GUI_TEST_01 returns the handle to a new GUI_TEST_01 or the handle to
%      the existing singleton*.
%
%      GUI_TEST_01('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_TEST_01.M with the given input arguments.
%
%      GUI_TEST_01('Property','Value',...) creates a new GUI_TEST_01 or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_test_01_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_test_01_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_test_01

% Last Modified by GUIDE v2.5 12-Mar-2015 22:15:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_test_01_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_test_01_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before GUI_test_01 is made visible.
function GUI_test_01_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_test_01 (see VARARGIN)
% UIWAIT makes GUI_test_01 wait for user response (see UIRESUME)
% uiwait(handles.figure1);
% Init global variables
global RecordingDuration                                    % 
global MaxIPfrequency                                       % 
global SampleRate                                           % 
global WindowDuration                                       % 
global ColorRange                                           % 
global Running
global Strongest
global Intensity
global UpdateColorRange
global UpdateWindowFunction

% Set defaults
RecordingDuration       = 10;                               % [s]
MaxIPfrequency          = 4000;                             % [Hz]
SampleRate              = 8000;                             % [Hz]
WindowDuration          = 50E-3;                            % [s]
ColorRange              = 'Jet';                            % [NA]
Running                 = 0;                                % [Bool]
Strongest               = 0;                                % [Hz]
Intensity               = 0.3;                              % [NA]
UpdateColorRange        = 1;                                % [Bool]
UpdateWindowFunction    = 1;                                % [Bool]

% Display logo
J = imread('logo_halftone_2.png');
axes(handles.axes_Logo);
imshow(J);

% Print to consol
fprintf('\nBegin Spectrogram\n');

% Choose default command line output for GUI_test_01
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
initialize_gui(hObject, handles, false);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_test_01_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the reset flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to reset the data.
% % if isfield(handles, 'metricdata') && ~isreset
% %     return;
% % end
% Update handles structure
guidata(handles.figure1, handles);


% --- Executes on button press in pushbutton_START.
function pushbutton_START_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_START (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Turn on spectrogram
%                           Main Algorithm
% vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
% Init Global vars
% First letter of var name of globals is CAPITAL
global RecordingDuration    
global MaxIPfrequency       
global WindowDuration       
global SampleRate           
global ColorRange            
global Running
global Strongest
global WindowFunction
global Intensity
global UpdateColorRange
global UpdateWindowFunction

if Running == 0                                             % Allow to Restart only if stopped first.
    % Init main vars    
    Running         = 1;                                    % Set flag Running to 1, 'true'
    windowFactor    = 10*2^10;                                
    windowSize      = windowFactor.*WindowDuration;         % Window Size
    overlap         = 2;
    hopSize         = windowSize/overlap-1;                 % Hop Size, 50% Overlap
    hopBeg          = 1;                                    % Beginning point of Window
    hopEnd          = windowSize;                           % End point of Window    
    timePerCol      = hopSize/SampleRate;                   % Time per column    
    numCol          = floor(RecordingDuration/timePerCol);  % Number of columns   
    NFFT            = 2^nextpow2(2*windowSize);             % Length to zero pad to
    freqVec         = SampleRate/2*(linspace(0,1,NFFT/2+1));% Frequency vector for display
    timeVec         = 0:1:RecordingDuration;                % Time vector for display
    data            = zeros(windowSize,numCol);             % Set up empty matrix for data 
    batchTotal      = 2;                                    % Total number of FFT attempts to do each Draw command    
    N               = SampleRate*windowSize;                % Number of samples 
    UpdateWindowFunction = 1;                               % Ensure changes while not running are initiated                   
    
    % Print to consol
    fprintf('START\n');
    fprintf('N:\t%d\n', N);
            
    % Set default WindowFunction
    contents        = cellstr(get(handles.popupmenu_WindowFunction,'String'));
    WindowFunction  = contents{get(hObject,'Value')};       % Set WindowFunction   
    
    % Set up audiorecorder
    recObj = audiorecorder(SampleRate,8,1); 
    resume(recObj);                              
    pause(1);                                   
    audioData = getaudiodata(recObj);              
    resume(recObj);                 
    
    % Set up image, format
    axes(handles.axes_Main);                                % Focus on main axes
    h_image = imagesc(timeVec, freqVec, data, [0 0.01]);
    axis xy;       
    xlabel('time (s)');
    ylabel('frequency (Hz)');
    colorbar;  
    if MaxIPfrequency <= SampleRate/2                       % Set y-limit   
        ylim([1,MaxIPfrequency]); 
    else
        ylim([1,SampleRate/2]);
    end
    %ylim([1,11025]);
    
    % Disable START button
    set(handles.pushbutton_START,'String','Running')
    set(handles.pushbutton_START,'Enable','off')
    
    % Main loop
    while Running %%&& ~PAUSE%%        
        % Init loop vars        
        batchAttempts    = 0;                               % Number of FFT attempts taken
        batchHits  = 0;                                     % Number of FFTs successfully taken
                
        % Update WindowFunction 
        if UpdateWindowFunction                             % Check if WindowFunction needs to be updated
            windowFunction = window(WindowFunction, windowSize);
            UpdateWindowFunction = 0;                       % Reset flag
            disp('Updated WindowFunction');
        end
               
        while batchAttempts <= batchTotal                   % Number of attempts to get FFTs to get before refreshing the display
            %fprintf('batchAttempts:\t%d\n', batchAttempts);
            %fprintf('batchTotal:\t\t%d\n', batchTotal);
            audioDataLength = length(audioData);            % For DEBUG
            
            if audioDataLength >= hopEnd                    % Check if enough samples have come in                
                % Window data with choosen WindowFunction
                windowedData = audioData((hopBeg:hopEnd)).*windowFunction;                  
                % Get FFT                     
                dataFFT = fft(windowedData, NFFT)/length(windowedData);   
                data = horzcat(data, dataFFT(1:NFFT/2));    % Concatenate new FFT data (to f_nyq) onto data array
                                
                hopBeg = hopBeg + hopSize;                  % Set new hop range
                hopEnd = hopEnd + hopSize;                  % Set new hop range
                batchHits = batchHits+1;                    % Inc batchHits
            end
            batchAttempts = batchAttempts+1;                % Inc batchAttempts
        end 

        if batchHits > 0                                    % Check if any FFTs were taken (successful attempts)        
            batchHits = batchHits+1;                        % Inc batchHits
            data = data(:, batchHits:end);                  % Number of concatenated columns
            plotdata = abs(data);                           % get absolute value of data
            set(h_image, 'CData', 2*Intensity*plotdata);    % Plot image, use Intensity from slider        
            
            % Update color map from pulldown if needed
            if UpdateColorRange    
                colormap(ColorRange);                       
                UpdateColorRange = 0;                       % Reset flag
                disp('Updated Color Range');
            end
            
            drawnow;                                        % Redraw in axes
%         % Animate logo
%         axes(handles.axes_Logo);
%         imshow(IMG_1);                                    % Red logo                            
%         axes(handles.axes_Main);           
        else                    
            plotdata = abs(data);
            set(h_image, 'CData', 2*Intensity*plotdata);    % Plot image, use Intensity from slider       
            
            % Update color map from pulldown if needed
            if UpdateColorRange    
                colormap(ColorRange);                       
                UpdateColorRange = 0;                       % Reset flag
                disp('Updated Color Range');
            end
            
            drawnow;                                        % Redraw in axes
            audioData = getaudiodata(recObj);               % Refresh audioData if no FFTs were taken last loop
%             % Animate logo
%             axes(handles.axes_Logo);
%             imshow(IMG_2);                                   % Orange logo
%             axes(handles.axes_Main);
        end  
        
         % Display the current highest amplitude tone playing
        [val, idx] = max(abs(dataFFT));                     % Find the index of the highest amplitude component
        HzPerDivision = SampleRate/size(dataFFT, 1);        % Find the frequency per division number
        Strongest = HzPerDivision*idx;                      % The frequncey of the strongest component
        if ishandle(handles.edit_Strongest)                 % Check that it exists, DEBUG
            set(handles.edit_Strongest,'String', Strongest);% Set value
        end
    end    
end
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


% --- Executes on button press in pushbutton_STOP.
function pushbutton_STOP_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_STOP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Turn off spectrogram
global Running
Running = 0;
% Enable the START button with its original name
set(handles.pushbutton_START,'String','START')
set(handles.pushbutton_START,'Enable','on')
% Print to consol
fprintf('STOP\n');


function edit_MaxIPfrequency_Callback(hObject, eventdata, handles)
% hObject    handle to edit_MaxIPfrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_MaxIPfrequency as text
%        str2double(get(hObject,'String')) returns contents of edit_MaxIPfrequency as a double
global MaxIPfrequency
MaxIPfrequency = str2double(get(hObject,'String'));
if isnan(MaxIPfrequency) || ~isreal(MaxIPfrequency)  
    % isdouble returns NaN for non-numbers and f1 cannot be complex
    % Disable the Plot button and change its string to say why
    set(handles.pushbutton_START,'String','Invalid Max I/P Frequency')
    set(handles.pushbutton_START,'Enable','off')
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
else 
    % Enable the Plot button with its original name
    set(handles.pushbutton_START,'String','START')
    set(handles.pushbutton_START,'Enable','on')
end
% Verify that the text in MaxIPfrequency field is in range
% min = 100, max = 10000
if MaxIPfrequency < 100
    set(hObject,'String',100);
    MaxIPfrequency = 100;
elseif MaxIPfrequency > 10000
    set(hObject,'String',10000);
    MaxIPfrequency = 10000;
end
disp('MaxIPfrequency set');


% --- Executes during object creation, after setting all properties.
function edit_MaxIPfrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_MaxIPfrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_SampleRate.
function popupmenu_SampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_SampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_SampleRate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_SampleRate
global SampleRate
global RefreshWindow
% Get SampleRate as a double
contents = cellstr(get(hObject,'String')); % Get cell array
SampleRateArray = contents(get(hObject,'Value')); % Get value
SampleRateString = cellstr(cell2mat(SampleRateArray)); % Concatenate cell array to one element
SampleRate = str2double(SampleRateString); % Convert to double
RefreshWindow = 1;
disp('SampleRate set');


% --- Executes during object creation, after setting all properties.
function popupmenu_SampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_SampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_RecordingDuration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_RecordingDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_RecordingDuration as text
%        str2double(get(hObject,'String')) returns contents of edit_RecordingDuration as a double
% Validate that the text in the RecodingDuration field converts to a real number
global RecordingDuration
RecordingDuration = str2double(get(hObject,'String'));
if isnan(RecordingDuration) || ~isreal(RecordingDuration)  
    % isdouble returns NaN for non-numbers and f1 cannot be complex
    % Disable the Plot button and change its string to say why
    set(handles.pushbutton_START,'String','Invalid Recording Duration')
    set(handles.pushbutton_START,'Enable','off')
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
else 
    % Enable the Plot button with its original name
    set(handles.pushbutton_START,'String','START')
    set(handles.pushbutton_START,'Enable','on')
end
% Verify that the text in RecordingDuration field is in range
% min = 2, max = 20
if RecordingDuration < 2
    set(hObject,'String',2);
    RecordingDuration = 2;
elseif RecordingDuration > 20
    RecordingDuration = 20;
    set(hObject,'String',20);
end
disp('RecordingDuration set');


% --- Executes during object creation, after setting all properties.
function edit_RecordingDuration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_RecordingDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_WindowDuration_Callback(hObject, eventdata, handles)
% hObject    handle to edit_WindowDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_WindowDuration as text
%        str2double(get(hObject,'String')) returns contents of edit_WindowDuration as a double
global WindowDuration
WindowDuration = str2double(get(hObject,'String'))/1000; % Convert to millisecons
if isnan(WindowDuration) || ~isreal(WindowDuration)  
    % isdouble returns NaN for non-numbers and f1 cannot be complex
    % Disable the Plot button and change its string to say why
    set(handles.pushbutton_START,'String','Invalid Window Duration')
    set(handles.pushbutton_START,'Enable','off')
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
else 
    % Enable the Plot button with its original name
    set(handles.pushbutton_START,'String','START')
    set(handles.pushbutton_START,'Enable','on')
end
% Verify that the text in WindowDuration field is in range
% min = 10, max = 500
if WindowDuration < 10E-3
    set(hObject,'String',10);
    WindowDuration = 10E-3;
elseif WindowDuration > 500E-3    
    set(hObject,'String',500);
    WindowDuration = 500E-3;
end
disp('WindowDuration set');


% --- Executes during object creation, after setting all properties.
function edit_WindowDuration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_WindowDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_ColorRange.
function popupmenu_ColorRange_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_ColorRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_ColorRange contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_ColorRange
global ColorRange
global UpdateColorRange
contents = cellstr(get(hObject,'String'));
ColorRange = contents{get(hObject,'Value')};
UpdateColorRange = 1;
disp('ColorRange set');


% --- Executes during object creation, after setting all properties.
function popupmenu_ColorRange_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_ColorRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axes_Main_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_Main (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: place code in OpeningFcn to populate axes_Main


% --- Executes during object creation, after setting all properties.
function axes_Logo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes_Logo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: place code in OpeningFcn to populate axes_Logo


% --- Executes during object creation, after setting all properties.
function text_Credit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_Credit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function edit_Strongest_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Strongest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function edit_Strongest_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Strongest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit_Strongest as text
%        str2double(get(hObject,'String')) returns contents of edit_Strongest as a double


% --- Executes during object creation, after setting all properties.
function text_Strongest_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_Strongest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in pushbutton_PAUSE.
function pushbutton_PAUSE_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_PAUSE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global PAUSE
% Toggle PAUSE status
if PAUSE == 1
    PAUSE = 0;
else 
    PAUSE = 1;
end


% --- Executes on selection change in popupmenu_WindowFunction.
function popupmenu_WindowFunction_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_WindowFunction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_WindowFunction contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_WindowFunction
global WindowFunction
global UpdateWindowFunction
contents = cellstr(get(hObject,'String'));
WindowFunction = contents{get(hObject,'Value')};
UpdateWindowFunction = 1;
disp('WindowFunction set');

% --- Executes during object creation, after setting all properties.
function popupmenu_WindowFunction_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_WindowFunction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider_Intensity_Callback(hObject, eventdata, handles)
% hObject    handle to slider_Intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% Min     = 0
% Max     = 1
% Default = 0.5
global Intensity
Intensity = get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function slider_Intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_Intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
