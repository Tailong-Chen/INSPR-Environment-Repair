function result = inspr_gpu_smoketest(toolbox)
% Run the real bundled MEX with a small, deterministic synthetic input.
% Environment sanity check only: this does not validate experimental results.
% Run in a separate MATLAB process: the legacy MEX calls cudaDeviceReset.
if nargin < 1, toolbox = 'astigmatism'; end
root = fileparts(fileparts(mfilename('fullpath')));
profile = inspr_toolbox_profile(root,toolbox);
inspr_prepare_runtime(root,profile.id);
names = {'listGPUs','cMakeSubregions','cHistRecon','cHistRecon3D',profile.localizationMex,'genpsfstruct'};
expected = {fullfile(profile.helpers,'listGPUs.mexw64'), ...
    fullfile(profile.directory,'Segmentation','cMakeSubregions.mexw64'), ...
    fullfile(profile.helpers,'cHistRecon.mexw64'),fullfile(profile.helpers,'cHistRecon3D.mexw64'), ...
    fullfile(profile.directory,'3D_localization',[profile.localizationMex '.mexw64']), ...
    fullfile(profile.directory,'3D_localization','genpsfstruct.m')};
for k = 1:numel(names)
    assert(strcmpi(which(names{k}),expected{k}),'INSPR:Runtime:Shadowed', ...
        'Wrong or missing %s. Expected: %s. Start a fresh MATLAB process.',names{k},expected{k});
end
listGPUs;

% Exercise the VC++ 2008 segmentation dependency using the production API.
image = single(reshape(1:32*32*2, 32, 32, 2));
[crops, left, top] = cMakeSubregions([15;15], [15;15], [0;1], 8, image);
assert(isequal(size(crops), [8 8 2]) && numel(left) == 2 && numel(top) == 2, ...
    'INSPR:Runtime:Segmentation', 'Segmentation MEX returned unexpected dimensions.');
assert(all(isfinite(crops(:))));

% Exercise the VC++ 2010/2013 reconstruction dependencies as well.
hist2 = cHistRecon(single(8), single(8), single([2;3]), single([2;3]), 0);
hist3 = cHistRecon3D(8, 8, 8, single([2;3]), single([2;3]), single([2;3]), 0);
assert(numel(hist2) == 64 && numel(hist3) == 512);
assert(all(isfinite(hist2(:))) && all(isfinite(hist3(:))));
assert(sum(hist2(:)) > 0 && sum(hist3(:)) > 0);
if strcmp(profile.id,'biplane')
    result = inspr_biplane_smoketest;
    return;
end

% Same input layout as loc_ast_model: 16x16 fit, four subpixels per pixel,
% 20 inputs and five outputs, single data/derivatives, double scalar options.
dx = 0.03;
dz = 0.05;
startxy = -1.5;
startz = -1.3;
[x,y,z] = meshgrid(startxy+(0:99)*dx, startxy+(0:99)*dx, startz+(0:52)*dz);
sx = 0.17 + 0.04*z;
sy = 0.20 - 0.04*z;
sample = dx^2 ./ (2*pi*sx.*sy) .* exp(-x.^2./(2*sx.^2)-y.^2./(2*sy.^2));
derivatives = genpsfstruct(sample, dx, dz, 'matrix');
truth = [8;8;0.12;3000;5];
[xd,yd] = meshgrid(((0:63)+0.5)*dx-8*4*dx);
sx0 = 0.17+0.04*truth(3);
sy0 = 0.20-0.04*truth(3);
subpixels = dx^2/(2*pi*sx0*sy0)*exp(-xd.^2/(2*sx0^2)-yd.^2/(2*sy0^2));
pixels = squeeze(sum(sum(reshape(subpixels,4,16,4,16),1),3));
data = single(truth(4)*pixels(:)+truth(5));
initial = single([8.05;7.95;0.10;2900;5.2]);
[parameters, convergence, crlb, fitError, psf] = cuda_ast_model( ...
    data, single([1;1;0]), single(sample), dx, dz, startxy, startxy, startz, ...
    30, 1, 0, initial, single(derivatives.Fx), single(derivatives.Fy), ...
    single(derivatives.Fz), single(derivatives.Fxy), single(derivatives.Fxz), ...
    single(derivatives.Fyz), single(derivatives.Fxyz), zeros(256,1,'single'));
assert(numel(parameters)==5 && numel(convergence)==5 && numel(crlb)==5 ...
    && numel(fitError)==2 && numel(psf)==256, 'INSPR:Runtime:Dimensions', ...
    'GPU MEX returned unexpected dimensions.');
values = [parameters(:); convergence(:); crlb(:); fitError(:); psf(:)];
assert(all(isfinite(values)) && all(crlb>=0) && all(psf>=0), ...
    'INSPR:Runtime:Numerics', 'GPU MEX returned non-finite or invalid outputs.');
% Broad, independent sanity bounds catch non-running/broken kernels without
% treating this synthetic PSF as a scientific accuracy benchmark.
assert(all(abs(double(parameters(1:2))-truth(1:2)) < 0.25) ...
    && abs(double(parameters(3))-truth(3)) < 0.15 ...
    && abs(double(parameters(4))-truth(4))/truth(4) < 0.15, ...
    'INSPR:Runtime:Fit', 'The synthetic GPU fit did not recover a reasonable solution.');
result.parameters = double(parameters(:));
result.truth = truth;
result.passed = true;
result.toolbox = 'astigmatism';
fprintf('INSPR_GPU_SMOKE_OK: x=%.4f y=%.4f z=%.4f photons=%.2f bg=%.3f\n', parameters);
clear cuda_ast_model;
end
