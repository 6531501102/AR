function processVideoWithFilter(videoFile, filterFile, outputFile)
    % อ่านวิดีโอ mp4
    v = VideoReader(videoFile);
    
    % โหลดฟิลเตอร์ PNG (ต้องมี transparency)
    filterImg = imread(filterFile);
    if size(filterImg,3) == 4
        alpha = double(filterImg(:,:,4))/255; % mask ความโปร่งใส
        filterImg = filterImg(:,:,1:3);
    else
        alpha = ones(size(filterImg,1), size(filterImg,2));
    end
    
    % สร้าง VideoWriter สำหรับบันทึกผลลัพธ์
    if nargin < 3
        outputFile = 'output.mp4';
    end
    writer = VideoWriter(outputFile, 'MPEG-4');
    writer.FrameRate = v.FrameRate;
    open(writer);

    % Loop ผ่านแต่ละเฟรม
    while hasFrame(v)
        frame = readFrame(v);

        % resize ฟิลเตอร์ ให้มีขนาดเท่ากับ 1/3 ของเฟรม
        scale = size(frame,2)/3 / size(filterImg,2);
        filterResized = imresize(filterImg, scale);
        alphaResized = imresize(alpha, scale);

        % กำหนดตำแหน่งวางฟิลเตอร์ (ตรงกลางด้านบน)
        [fh, fw, ~] = size(frame);
        [hh, hw, ~] = size(filterResized);

        xpos = round(fw/2 - hw/2);
        ypos = round(fh/5);

        % วางฟิลเตอร์ลงบนเฟรม
        for c = 1:3
            roi = frame(ypos:ypos+hh-1, xpos:xpos+hw-1, c);
            roi = uint8(double(roi).*(1-alphaResized) + double(filterResized(:,:,c)).*alphaResized);
            frame(ypos:ypos+hh-1, xpos:xpos+hw-1, c) = roi;
        end

        % เขียนเฟรมลงไฟล์ใหม่
        writeVideo(writer, frame);
    end

    close(writer);
    disp(['✅ Processed video saved as: ', outputFile]);
end
