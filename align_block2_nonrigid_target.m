function [imin,yblk, F0, F0m] = align_block2_nonrigid_target(F, ysamp, nblocks)

%fprintf('Align block with non-rigid target template\n', dmin)

% F is y bins by amp bins by batches
% ysamp are the coordinates of the y bins in um

Nbatches = size(F,3);

% look up and down this many y bins to find best alignment
n = 30;
dc = zeros(2*n+1, Nbatches);
dt = -n:n;

% we do everything on the GPU for speed, but it's probably fast enough on
% the CPU
Fg = gpuArray(single(F));

% mean subtraction to compute covariance
Fg = Fg - mean(Fg, 1);

% initialize the target "frame" for alignment with a single sample
F0 = Fg(:,:, min(300, floor(size(Fg,3)/2)));

% We do rigid registration by integer shifts,
% Then upsample and do non-rigid registration (register each block)
% The target frame is updated at each iteration (both rigid and non rigid)
niter_rigid = 10;
niter_nonrigid = 10;

% figure out how to split the probe into nblocks pieces
% if nblocks = 1, then we're doing rigid registration
nybins = size(F,1);
yl = floor(nybins/nblocks)-1;
ifirst = round(linspace(1, nybins - yl, 2*nblocks-1));
ilast  = ifirst + yl; %287;
nblocks = length(ifirst);
yblk = zeros(length(ifirst), 1);

% Keep track of the shifts at each iteration
dall = zeros(niter_rigid + niter_nonrigid, Nbatches, nblocks);

%% first we do rigid registration by integer shifts
% everything is iteratively aligned until most of the shifts become 0. 
for iter = 1:niter_rigid    
    for t = 1:length(dt)
        % for each NEW potential shift, estimate covariance
        Fs = circshift(Fg, dt(t), 1);
        dc(t, :) = gather(sq(mean(mean(Fs .* F0, 1), 2)));
    end
    
    % estimate the best shifts
    [~, imax] = max(dc, [], 1);

    % align the data by these integer shifts
    for t = 1:length(dt)
        ib = imax==t;
        Fg(:, :, ib) = circshift(Fg(:, :, ib), dt(t), 1);
        for j = 1:nblocks
            % Same shift for each block during this rigid main loop
            dall(iter, ib, j) = dt(t);
        end
    end
    
    % new target frame based on our current best alignment
    F0 = mean(Fg, 3);
end

%%

% for each small block, we only look up and down this many samples to find
% nonrigid shift
n = 30;
dt = -n:n;
dcs = zeros(2*n+1, Nbatches, nblocks);

%% Non-rigid iterations (integer shifts)
% Now we register each block and update the target frame
% All shifts are integer except the very last iteration
for iter = 1:niter_nonrigid - 1

    % Shift each block independently
    for j = 1:nblocks
        isub = ifirst(j):ilast(j);
        yblk(j) = mean(ysamp(isub));
        
        Fsub = Fg(isub, :, :);
        
        for t = 1:length(dt)
            % for each potential shift, estimate covariance
            Fs = circshift(Fsub, dt(t), 1);
            dcs(t, :, j) = gather(sq(mean(mean(Fs .* F0(isub, :, :), 1), 2)));
        end

        % integer shift for all iterations except last one
        if iter < niter_nonrigid
            % estimate the best shifts
            [~, imax] = max(dcs(:, :, j), [], 1);
            
            % align the data by these integer shifts
            for t = 1:length(dt)
                ib = imax==t;
                % NB: circular shift could become problematic for large shifts/small blocks
                % I believe 0-padding would be better in theory
                Fg(isub, :, ib) = circshift(Fg(isub, :, ib), dt(t), 1);
                dall(niter_rigid + iter, ib, j) = dt(t);
            end

            % new target frame based on current best alignment for current block
            F0(isub, :) = mean(Fg(isub, :, :), 3);

        end
    end

end

%% (last iteration): sub-integer shifts

% to find sub-integer shifts for each block , 
% we now use upsampling, based on kriging interpolation
dtup = linspace(-n, n, (2*n*10)+1);    
K = kernelD(dt,dtup,1); % this kernel is fixed as a variance of 1
dcs = my_conv2(dcs, .5, [1, 2, 3]); % some additional smoothing for robustness, across all dimensions

for j = 1:nblocks
    % using the upsampling kernel K, get the upsampled cross-correlation
    % curves
    dcup = K' * dcs(:,:,j);
    
    % find the  max of these curves
    [~, imax] = max(dcup, [], 1);
    
    % add the value of the shift to the last row of the matrix of shifts
    % (as if it was the last iteration of the main non-rigid loop )
    dall(niter_rigid + niter_nonrigid, :, j) = dtup(imax);
end


% the sum of all the shifts (rigid and non-rigid) equals the final shifts for each block
imin = zeros(Nbatches, nblocks);
for j = 1:nblocks
    imin(:,j) = sum(dall(:,:,j),1);% 
end


%%
% Doesn't include the last upsampled iteration
F0m = mean(Fg,3);