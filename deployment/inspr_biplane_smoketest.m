function result = inspr_biplane_smoketest
% Match loc_channel_specific_model's 22-input, 5-output native interface.
% Two different focal planes, independent photon/background parameters and a
% nonzero registration/segmentation offset exercise the biplane-specific path.
% Synthetic execution sanity check only; run in an isolated MATLAB process.
dx = 0.03; dz = 0.05; startxy = -1.5; startz = -1.3;
[x,y,z] = meshgrid(startxy+(0:99)*dx,startxy+(0:99)*dx,startz+(0:52)*dz);
truth = [8;8;0.12;3000;2100;5;8];
initial = single([7.55;8.4;-0.08;2400;2600;7;5]);
planes = [-0.35,0.35];
affine = single([1 0;0 1;0.25 -0.2]); % native column-major 3x2 layout
offset = single([1 -1]);
sample = []; data = []; derivatives = cell(1,7);
fields = {'Fx','Fy','Fz','Fxy','Fxz','Fyz','Fxyz'};
for channel = 1:2
    width = 0.18*sqrt(1+((z-planes(channel))/0.5).^2);
    grid = dx^2./(2*pi*width.^2).*exp(-(x.^2+y.^2)./(2*width.^2));
    sample = cat(3,sample,single(grid));
    st = genpsfstruct(grid,dx,dz,'matrix');
    for k = 1:7, derivatives{k} = cat(3,derivatives{k},single(st.(fields{k}))); end
    center = truth(1:2);
    if channel == 2, center = double(affine(1:2,:))'*center + double(affine(3,:))' + double(offset)'; end
    [xd,yd] = meshgrid(((0:63)+0.5)*dx-center(1)*4*dx, ...
        ((0:63)+0.5)*dx-center(2)*4*dx);
    width0 = 0.18*sqrt(1+((truth(3)-planes(channel))/0.5)^2);
    subpixels = dx^2/(2*pi*width0^2)*exp(-(xd.^2+yd.^2)/(2*width0^2));
    pixels = squeeze(sum(sum(reshape(subpixels,4,16,4,16),1),3));
    data = [data; single(truth(3+channel)*pixels(:)+truth(5+channel))]; %#ok<AGROW>
end
[parameters,convergence,crlb,fitError,psf] = cuda_channel_specific_model( ...
    data,single([1;1;0]),sample,dx,dz,startxy,startxy,startz,80,1,0,initial, ...
    derivatives{:},affine,offset,zeros(512,1,'single'));
assert(numel(parameters)==7 && numel(convergence)==7 && numel(crlb)==7 ...
    && numel(fitError)==2 && numel(psf)==512,'INSPR:Runtime:Dimensions', ...
    'Biplane GPU MEX returned unexpected dimensions.');
values = [parameters(:);convergence(:);crlb(:);fitError(:);psf(:)];
assert(all(isfinite(values)) && all(crlb>=0) && all(psf>=0), ...
    'INSPR:Runtime:Numerics','Biplane GPU MEX returned invalid outputs.');
assert(all(abs(double(parameters(1:2))-truth(1:2))<0.25) ...
    && abs(double(parameters(3))-truth(3))<0.15 ...
    && all(abs(double(parameters(4:5))-truth(4:5))./truth(4:5)<0.15) ...
    && all(abs(double(parameters(6:7))-truth(6:7))<2), ...
    'INSPR:Runtime:Fit','The synthetic two-channel GPU fit did not recover a reasonable solution.');
result.parameters = double(parameters(:));
result.truth = truth;
result.passed = true;
result.toolbox = 'biplane';
fprintf('INSPR_BIPLANE_GPU_SMOKE_OK: x=%.4f y=%.4f z=%.4f I1=%.2f I2=%.2f bg1=%.3f bg2=%.3f\n',parameters);
clear cuda_channel_specific_model;
end
