% ARToolbox.m
% Run this file to open a simple GUI for testing AR filters on image, video, webcam.
% Dependencies: Computer Vision System Toolbox (for vision.CascadeObjectDetector)

function ARToolbox
    close all; clc;
    % Create figure
    h.fig = figure('Name','AR Filter Toolbox','NumberTitle','off','MenuBar','none','ToolBar','none',...
        'Position',[200 200 1000 600]);
    
    % Axes for preview
    h.ax = axes('Parent',h.fig,'Units','pixels','Position',[20 120 640 450]);
    axis(h.ax,'off');
    title(h.ax,'Preview');

    % Controls: load image, load filter, process image, run webcam, run video
    uicontrol('Style','pushbutton','String','Load Image','Position',[700 500 250 40],...
        'Callback',@(~,~)onLoadImage());
    uicontrol('Style','pushbutton','String','Load Video','Position',[700 450 250 40],...
        'Callback',@(~,~)onLoadVideo());
    uicontrol('Style','pushbutton','String','Start Webcam','Position',[700 400 250 40],...
        'Callback',@(~,~)onStartWebcam());
    uicontrol('Style','pushbutton','String','Stop Webcam','Position',[700 350 250 40],...
        'Callback',@(~,~)onStopWebcam());
    uicontrol('Style','pushbutton','String','Load Filter (PNG)','Position',[700 300 250 40],...
        'Callback',@(~,~)onLoadFilter());
    uicontrol('Style','pushbutton','String','Apply to Image','Position',[700 250 250 40],...
        'Callback',@(~,~)onApplyToImage());
    uicontrol('Style','pushbutton','String','Process Video File','Position',[700 200 250 40],...
        'Callback',@(~,~)onProcessVideoFile());
    uicontrol('Style','text','Position',[700 140 250 40],'HorizontalAlignment','left',...
        'String','Notes: Choose filter PNG (with transparency) for best result.');

    % Data storage
    data = struct('img',[],'filterImg',[],'filterAlpha',[],'vidObj',[],'camObj',[],'runCam',false);
    guidata(h.fig,data);
    
    % Callbacks ============================================================
    function onLoadImage()
        [f,p] = uigetfile({'*.jpg;*.png;*.bmp;*.tif;*.jpeg','Images'},'Select an image');
        if isequal(f,0), return; end
        img = imread(fullfile(p,f));
        data = guidata(h.fig);
        data.img = img;
        guidata(h.fig,data);
        imshow(img,'Parent',h.ax);
        title(h.ax,'Loaded Image');
    end

    function onLoadFilter()
        [f,p] = uigetfile({'*.png;*.tif','PNG (prefer alpha)';'*.jpg;*.bmp','Image'},'Select filter image (transparent PNG recommended)');
        if isequal(f,0), return; end
        [fimg,~,alpha] = imread(fullfile(p,f));
        % If no alpha returned, create full alpha
        if isempty(alpha)
            alpha = 255*ones(size(fimg,1),size(fimg,2),'uint8');
        end
        data = guidata(h.fig);
        data.filterImg = fimg;
        data.filterAlpha = alpha;
        guidata(h.fig,data);
        % show filter as preview in small axes
        figure(999); clf;
        imshow(fimg); title('Loaded filter (close this window to continue)');
    end

    function onApplyToImage()
        data = guidata(h.fig);
        if isempty(data.img)
            errordlg('Load an image first.','Error'); return;
        end
        if isempty(data.filterImg)
            errordlg('Load a filter PNG first.','Error'); return;
        end
        frame = data.img;
        out = applyFilterToFrame(frame, data.filterImg, data.filterAlpha);
        imshow(out,'Parent',h.ax); title(h.ax,'Image with AR Filter');
    end

    function onLoadVideo()
        [f,p] = uigetfile({'*.mp4;*.avi;*.mkv;*.mov','Videos'},'Select video file');
        if isequal(f,0), return; end
        vidObj = VideoReader(fullfile(p,f));
        data = guidata(h.fig);
        data.vidObj = vidObj;
        guidata(h.fig,data);
        msgbox('Video loaded. Use "Process Video File" to save output.','Info');
    end

    function onProcessVideoFile()
        data = guidata(h.fig);
        if isempty(data.vidObj)
            errordlg('Load a video file first.','Error'); return;
        end
        if isempty(data.filterImg)
            errordlg('Load a filter PNG first.','Error'); return;
        end
        vid = data.vidObj;
        [outFile, outPath] = uiputfile('output_with_filter.avi','Save processed video as');
        if isequal(outFile,0), return; end
        outWriter = VideoWriter(fullfile(outPath,outFile));
        outWriter.FrameRate = vid.FrameRate;
        open(outWriter);
        hWait = waitbar(0,'Processing video frames...');
        frameIdx = 0;
        while hasFrame(vid)
            frame = readFrame(vid);
            frameIdx = frameIdx + 1;
            % apply filter
            outFrame = applyFilterToFrame(frame, data.filterImg, data.filterAlpha);
            writeVideo(outWriter,outFrame);
            if mod(frameIdx,5)==0
                waitbar(frameIdx/vid.NumFrames,hWait);
            end
        end
        close(hWait);
        close(outWriter);
        msgbox('Video processing finished and saved.','Done');
    end

    % Webcam functions
    function onStartWebcam()
        data = guidata(h.fig);
        if isempty(data.filterImg)
            answer = questdlg('No filter loaded. Continue without filter?','Warning','Continue','Cancel','Cancel');
            if strcmp(answer,'Cancel'), return; end
        end
        try
            cam = webcam; % default camera
        catch ME
            errordlg(['Cannot access webcam: ' ME.message],'Error');
            return;
        end
        data.camObj = cam;
        data.runCam = true;
        guidata(h.fig,data);
        % live loop (non-blocking using timer)
        t = timer('ExecutionMode','fixedSpacing','Period',0.03,'TimerFcn',@webcamTick);
        t.UserData.fig = h.fig;
        start(t);
        % store timer to figure (so can stop it later)
        data = guidata(h.fig); data.camTimer = t; guidata(h.fig,data);
    end

    function webcamTick(~,~)
        data = guidata(h.fig);
        if ~isfield(data,'runCam') || ~data.runCam
            return;
        end
        try
            frame = snapshot(data.camObj);
        catch
            return;
        end
        if ~isempty(data.filterImg)
            out = applyFilterToFrame(frame, data.filterImg, data.filterAlpha);
        else
            out = frame;
        end
        imshow(out,'Parent',h.ax);
        drawnow limitrate
    end

    function onStopWebcam()
        data = guidata(h.fig);
        if isfield(data,'camTimer') && isvalid(data.camTimer)
            stop(data.camTimer); delete(data.camTimer);
        end
        if isfield(data,'camObj') && ~isempty(data.camObj)
            clear data.camObj; % release webcam
        end
        data.runCam = false;
        guidata(h.fig,data);
        msgbox('Webcam stopped.','Info');
    end

end