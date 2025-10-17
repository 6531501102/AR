function AR_Toolbox_Final_Elliptical_Fixed
    % ===========================================================
    % Smart Image Processing Toolbox (AR Filter - Final Fixed)
    % By Phurichaya
    % ===========================================================

    clc; close all; clear;

    % -----------------------------------------------------------
    % GUI Window
    % -----------------------------------------------------------
    f = figure('Name','Smart Image Processing Toolbox (AR Filter Final)', ...
        'NumberTitle','off','Position',[250 80 1100 600], ...
        'MenuBar','none','Resize','off','Color',[0.95 0.95 0.95]);

    img = [];
    resultImg = [];
    cam = [];
    stopCam = false;

    % -----------------------------------------------------------
    % Mode Selection
    % -----------------------------------------------------------
    bgMode = uibuttongroup('Parent',f,'Position',[0.05 0.83 0.3 0.08],...
        'Title','Mode','FontSize',11,'SelectionChangedFcn',@modeChange);
    uicontrol(bgMode,'Style','radiobutton','String','Image',...
        'Position',[20 10 80 30],'FontSize',11,'Value',1);
    uicontrol(bgMode,'Style','radiobutton','String','Webcam',...
        'Position',[120 10 100 30],'FontSize',11);

    % -----------------------------------------------------------
    % Controls
    % -----------------------------------------------------------
    btnUpload = uicontrol('Style','pushbutton','String','Upload Image',...
        'FontSize',12,'Position',[50 520 150 40],'Callback',@uploadImage);

    uicontrol('Style','text','String','Module','FontSize',11,...
        'Position',[240 540 60 20],'BackgroundColor',[0.95 0.95 0.95]);
    moduleMenu = uicontrol('Style','popupmenu','String', ...
        {'Select','Module 1','Module 2','Module 3','All'}, ...
        'FontSize',11,'Position',[300 530 130 30],'Callback',@moduleChange);

    uicontrol('Style','text','String','Filter','FontSize',11,...
        'Position',[450 540 60 20],'BackgroundColor',[0.95 0.95 0.95]);
    filterDropdown = uicontrol('Style','popupmenu','String', ...
        {'Select Filter','Joker','Glasses','Mask','Makeup'}, ...
        'FontSize',11,'Position',[500 530 150 30],'Enable','off');

    btnApply = uicontrol('Style','pushbutton','String','Apply Image',...
        'FontSize',12,'Position',[670 530 150 40],'Callback',@applyImage);

    btnStartCam = uicontrol('Style','pushbutton','String','Start Webcam',...
        'FontSize',12,'BackgroundColor',[0.2 0.8 0.4],...
        'Position',[850 530 150 40],'Callback',@startWebcamMode);

    btnStopCam = uicontrol('Style','pushbutton','String','Stop Webcam',...
        'FontSize',12,'BackgroundColor',[0.9 0.3 0.3],...
        'Position',[850 480 150 40],'Callback',@stopWebcamMode);

    btnSave = uicontrol('Style','pushbutton','String','Save Result',...
        'FontSize',12,'BackgroundColor',[0.7 0.7 0.9],...
        'Position',[850 430 150 40],'Callback',@saveResult);

    % -----------------------------------------------------------
    % Display Axes
    % -----------------------------------------------------------
    ax1 = axes('Parent',f,'Position',[0.07 0.1 0.4 0.4]);
    title(ax1,'Original Image'); axis off;
    ax2 = axes('Parent',f,'Position',[0.55 0.1 0.4 0.4]);
    title(ax2,'Processed Image'); axis off;

    % -----------------------------------------------------------
    % Mode Switch
    % -----------------------------------------------------------
    function modeChange(~,event)
        if strcmp(event.NewValue.String,'Image')
            set(btnUpload,'Enable','on');
            set(btnApply,'Enable','on');
            set(btnStartCam,'Enable','off');
            set(btnStopCam,'Enable','off');
        else
            set(btnUpload,'Enable','off');
            set(btnApply,'Enable','off');
            set(btnStartCam,'Enable','on');
            set(btnStopCam,'Enable','on');
        end
    end

    % -----------------------------------------------------------
    % Upload Image
    % -----------------------------------------------------------
    function uploadImage(~,~)
        [file,path] = uigetfile({'*.jpg;*.png;*.jpeg'},'Select an image');
        if isequal(file,0), return; end
        img = imread(fullfile(path,file));
        imshow(img,'Parent',ax1);
    end

    % -----------------------------------------------------------
    % Module Change
    % -----------------------------------------------------------
    function moduleChange(src,~)
        if src.Value == 5 % All
            set(filterDropdown,'Enable','on');
        else
            set(filterDropdown,'Enable','off');
        end
    end

% ===========================================================
% Apply Image (Static Mode) - Enhanced + AR Filter
% ===========================================================
function applyImage(~,~)
    if isempty(img)
        msgbox('Please upload an image first!','Error','error');
        return;
    end

    modChoice = moduleMenu.Value;
    filterChoice = filterDropdown.Value;

    base = im2double(img);
    proc = base;

    switch modChoice
        case 5  % All + AR Filter
            if filterChoice > 1
                filterNames = {'','joker.jpeg','glasses.png','mask.png','makeup.png'};
                selectedFilter = filterNames{filterChoice};
                if isfile(selectedFilter)
                    filterImg = im2double(imread(selectedFilter));

                    detectImg = imresize(base, [480 NaN]);
                    detectGray = rgb2gray(detectImg);
                    detectGray = imadjust(detectGray);
                    faceDetector = vision.CascadeObjectDetector('FrontalFaceCART');
                    bbox = step(faceDetector, detectGray);

                    if isempty(bbox)
                        msgbox('No face detected.','Warning','warn');
                    else
                        for i = 1:size(bbox,1)
                            scaleX = size(base,2) / size(detectGray,2);
                            scaleY = size(base,1) / size(detectGray,1);
                            x = round(bbox(i,1) * scaleX);
                            y = round(bbox(i,2) * scaleY);
                            w = round(bbox(i,3) * scaleX);
                            h = round(bbox(i,4) * scaleY);

                            % ✅ Standardized filter scaling (used by both Image & Webcam)
                            scaleW = 1.10;
                            scaleH = 1.30;
                            offsetX = 5;
                            offsetY = -100;

                            

                            newW = round(w * scaleW);
                            newH = round(h * scaleH);

                            x = x - round((newW - w)/2) + offsetX;
                            y = y - round((newH - h)/2) + round(h * 0.15) + offsetY;

                            resizedFilter = imresize(filterImg,[newH newW]);

                            [rows, cols, ~] = size(resizedFilter);
                            [X, Y] = meshgrid(1:cols, 1:rows);
                            ellipseMask = ((X-cols/2).^2)/((cols/2)*0.65)^2 + ...
                                          ((Y-rows/2).^2)/((rows/2)*0.90)^2 <= 1;
                            alphaVal = 0.4;
                            alpha = alphaVal * ellipseMask;

                            xEnd = min(x+newW-1,size(base,2));
                            yEnd = min(y+newH-1,size(base,1));
                            hEff = yEnd-y+1; wEff = xEnd-x+1;

                            for c = 1:3
                                base(y:yEnd,x:xEnd,c) = ...
                                    alpha(1:hEff,1:wEff).*resizedFilter(1:hEff,1:wEff,c) + ...
                                    (1-alpha(1:hEff,1:wEff)).*base(y:yEnd,x:xEnd,c);
                            end
                        end
                    end
                end
            end
            proc = base;
            title(ax2,'All Modules + AR Filter');
        otherwise
            title(ax2,'Other Module');
    end

    resultImg = proc;
    imshow(resultImg,'Parent',ax2);
end

% ===========================================================
% Webcam Mode (use same scaling as Image Mode)
% ===========================================================
function startWebcamMode(~,~)
    stopCam = false;

    if strcmp(filterDropdown.Enable,'off') || filterDropdown.Value == 1
        msgbox('Please select a filter before starting the webcam.','Warning','warn');
        return;
    end

    filterNames = {'','joker.jpeg','glasses.png','mask.png','makeup.png'};
    selectedFilter = filterNames{filterDropdown.Value};
    if ~isfile(selectedFilter)
        msgbox(['Filter file not found: ' selectedFilter],'Error','error');
        return;
    end
    filterImg = im2double(imread(selectedFilter));

    try
        cam = webcam;
    catch
        msgbox('Cannot access webcam!','Error','error');
        return;
    end

    faceDetector = vision.CascadeObjectDetector('FrontalFaceCART');
    alphaVal = 0.4; % same transparency as image mode

    % ✅ ใช้ scale และ offset เดียวกับ Image Mode
    scaleW = 1.20;
    scaleH = 1.30;
    offsetX = 5;
    offsetY = -20;

    while ~stopCam && isvalid(f)
        frame = im2double(snapshot(cam));
        gray = rgb2gray(frame);
        bbox = step(faceDetector, gray);

        if ~isempty(bbox)
            for i = 1:size(bbox,1)
                x = bbox(i,1); y = bbox(i,2);
                w = bbox(i,3); h = bbox(i,4);

                newW = round(w * scaleW);
                newH = round(h * scaleH);

                x = x - round((newW - w)/2) + offsetX;
                y = y - round((newH - h)/2) + round(h * 0.15) + offsetY;

                resizedFilter = imresize(filterImg,[newH newW]);
                [rows, cols, ~] = size(resizedFilter);
                [X, Y] = meshgrid(1:cols, 1:rows);
                ellipseMask = ((X-cols/2).^2)/((cols/2)*0.65)^2 + ...
                              ((Y-rows/2).^2)/((rows/2)*0.90)^2 <= 1;
                alpha = alphaVal * ellipseMask;

                xEnd = min(x+newW-1,size(frame,2));
                yEnd = min(y+newH-1,size(frame,1));
                hEff = yEnd-y+1; wEff = xEnd-x+1;

                for c = 1:3
                    frame(y:yEnd,x:xEnd,c) = ...
                        alpha(1:hEff,1:wEff).*resizedFilter(1:hEff,1:wEff,c) + ...
                        (1-alpha(1:hEff,1:wEff)).*frame(y:yEnd,x:xEnd,c);
                end
            end
        end
        imshow(frame,'Parent',ax2);
        title(ax2,'Webcam Live (Matched Filter Size)');
        drawnow;
        pause(0.02);
    end
    clear cam;
end

function stopWebcamMode(~,~)
    stopCam = true;
    msgbox('Webcam stopped successfully.','Info','help');
end

% -----------------------------------------------------------
% Save Result
% -----------------------------------------------------------
function saveResult(~,~)
    if isempty(resultImg)
        msgbox('No result image to save.','Warning','warn');
        return;
    end
    [file,path] = uiputfile('result.jpg','Save Result As');
    if isequal(file,0), return; end
    imwrite(resultImg, fullfile(path,file));
    msgbox('Result image saved successfully!','Success','help');
end
end
