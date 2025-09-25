function bboxes = utils_detectFace(img)
% bboxes = utils_detectFace(img)
% Uses Viola-Jones Cascade (vision.CascadeObjectDetector) to detect faces.
% Returns Nx4 bounding boxes [x y w h]. If none found returns [].

    persistent faceDetector eyeDetector
    if isempty(faceDetector)
        faceDetector = vision.CascadeObjectDetector(); % default frontalFaceCART
        % optionally set MinSize if needed: faceDetector.MinSize = [60 60];
    end
    % Convert to grayscale
    if size(img,3)==3
        gray = rgb2gray(img);
    else
        gray = img;
    end
    bboxes = step(faceDetector, gray);
    % If no faces found try alternate detector
    if isempty(bboxes)
        try
            alt = vision.CascadeObjectDetector('FrontalFaceCART');
            bboxes = step(alt, gray);
        end
    end
end
