function out = applyFilterToFrame(frame, filterImg, filterAlpha)
% out = applyFilterToFrame(frame, filterImg, filterAlpha)
% - frame: input RGB frame (HxWx3)
% - filterImg: filter image (RGB) (hf x wf x 3)
% - filterAlpha: alpha channel (hf x wf) uint8 (0..255) or logical
% Returns out: result RGB frame with filter overlaid using face detection
%
% Strategy:
% 1) detect face bounding box (if multiple, use largest)
% 2) scale filter to match face width (width factor can be tuned)
% 3) center filter at a relative position above/beside bbox (tweak for glasses/mask)
% 4) alpha-blend filter onto frame

    % Ensure frame is RGB
    if size(frame,3)==1
        frame = cat(3,frame,frame,frame);
    end
    out = frame;
    try
        bbox = utils_detectFace(frame);
    catch
        bbox = [];
    end
    if isempty(bbox)
        % no face found: return original
        return;
    end
    % choose largest bbox
    areas = bbox(:,3).*bbox(:,4);
    [~, idx] = max(areas);
    face = bbox(idx,:); % [x y w h]
    fx = face(1); fy = face(2); fw = face(3); fh = face(4);

    % Decide overlay placement & scaling:
    % Many filters (e.g. glasses) are narrower than face width; a factor ~0.9 works.
    scaleFactor = 1.0; % tuneable (1.0 = filter width ~= face width)
    newW = round(fw * scaleFactor);
    % keep aspect ratio
    [hf, wf, ~] = size(filterImg);
    aspect = hf/wf;
    newH = round(newW * aspect);

    % Resize filter and alpha
    filtRGB = imresize(filterImg, [newH newW]);
    filtAlpha = imresize(filterAlpha, [newH newW]);
    % Normalize alpha to 0..1
    if isa(filtAlpha,'uint8') || max(filtAlpha(:))>1
        a = double(filtAlpha)/255;
    else
        a = double(filtAlpha);
    end
    if size(a,3)>1, a=a(:,:,1); end

    % Compute position: center horizontally on face,
    % vertical position: for glasses set slightly lower than top; for mask adjust
    centerX = round(fx + fw/2);
    % position Y: place filter so that its center is at face centerY * factor
    centerY = round(fy + fh*0.4); % 0.4 places filter roughly at eye region
    top = centerY - round(newH/2);
    left = centerX - round(newW/2);

    % Boundary checks
    [H,W,~] = size(frame);
    x1 = max(1,left); y1 = max(1,top);
    x2 = min(W,left+newW-1); y2 = min(H,top+newH-1);
    if x1>x2 || y1>y2
        return;
    end

    % Regions in frame and filter
    fx1 = x1 - left + 1;
    fy1 = y1 - top + 1;
    fx2 = fx1 + (x2-x1);
    fy2 = fy1 + (y2-y1);

    region = double(frame(y1:y2,x1:x2,:));
    filt_region = double(filtRGB(fy1:fy2,fx1:fx2,:));
    alpha_region = double(a(fy1:fy2,fx1:fx2));

    % alpha blending: out = alpha .* filt + (1-alpha) .* bg
    for c = 1:3
        region(:,:,c) = alpha_region .* filt_region(:,:,c) + (1 - alpha_region) .* region(:,:,c);
    end

    out(y1:y2,x1:x2,:) = uint8(region);
end
