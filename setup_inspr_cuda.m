function report = setup_inspr_cuda(varargin)
%SETUP_INSPR_CUDA Diagnose the bundled Windows MEX files and repair session paths.
%   report = setup_inspr_cuda('Toolbox', 'astigmatism')
%   report = setup_inspr_cuda('Toolbox', 'biplane')
%   report = setup_inspr_cuda('RuntimeDirectory', 'D:\trusted-cuda-runtime')
%   report = setup_inspr_cuda('TestGPU', false, 'ReportFile', '')
%
% Run from the repository root in the MATLAB used for INSPR. This function
% adds project paths and any matching, existing x64 CUDA runtime directories
% to this MATLAB session only. It does not download/install software, change
% the system PATH, savepath, replace binaries, or run localization kernels.
% Use only official NVIDIA/Microsoft files in RuntimeDirectory. Never rename
% a newer cudart DLL to an older version's name.
%
% The default UTF-8 report is written to tempdir; its path is printed.
% TestGPU calls only the project's listGPUs MEX, not gpuDevice (which tests
% MATLAB's own GPU stack). Enumeration is NOT a 3D localization smoke test.

p = inputParser;
addParameter(p, 'Toolbox', 'auto', @ischar);
addParameter(p, 'RuntimeDirectory', '', @ischar);
addParameter(p, 'ReportFile', fullfile(tempdir, ...
    ['inspr_cuda_' datestr(now, 'yyyymmdd_HHMMSS') '.txt']), @ischar); %#ok<DATST,TNOW1> Older MATLAB compatibility.
addParameter(p, 'TestGPU', true, @(x) islogical(x) && isscalar(x));
parse(p, varargin{:});
opt = p.Results;
if ~ispc || ~strcmp(computer('arch'), 'win64')
    error('INSPR:CUDA:Platform', 'The bundled MEX files require 64-bit Windows MATLAB.');
end
if ~isempty(opt.RuntimeDirectory) && exist(opt.RuntimeDirectory, 'dir') ~= 7
    error('INSPR:CUDA:RuntimeDirectory', 'RuntimeDirectory does not exist: %s', opt.RuntimeDirectory);
end

root = fileparts(mfilename('fullpath'));
deployment = fullfile(root,'deployment');
if ~any(strcmpi(regexp(path,pathsep,'split'),deployment)), addpath(deployment); end
profile = inspr_toolbox_profile(root,opt.Toolbox);
inspr_configure_paths(profile);
toolbox = profile.directory;
helpers = profile.helpers;
projectPaths = profile.paths;

report = struct;
report.toolbox = profile.id;
report.matlabVersion = version;
report.matlabRoot = matlabroot;
report.projectRoot = root;
report.localizationVerified = false;
report.reportFile = opt.ReportFile;
report.addedRuntimePaths = {};
report.notes = {};
[report.osStatus, report.os] = system('ver');
% Use the driver-installed executable when present; PATH is the fallback.
smi = fullfile(getenv('SystemRoot'), 'System32', 'nvidia-smi.exe');
if exist(smi, 'file') ~= 2, smi = 'nvidia-smi'; end
[report.nvidiaStatus, report.nvidia] = system( ...
    ['"' smi '" --query-gpu=name,driver_version --format=csv,noheader']);
[report.nvccStatus, report.nvcc] = system('nvcc --version');

names = {'listGPUs', profile.localizationMex, 'SRsCMOS_MLE', ...
    'GPUgaussMLE', 'cMakeSubregions', 'cHistRecon3D', 'cHistRecon'};
files = {fullfile(helpers, 'listGPUs.mexw64'), ...
    fullfile(toolbox, '3D_localization', [profile.localizationMex '.mexw64']), ...
    fullfile(toolbox, '2D_localization', 'SRsCMOS_MLE.mexw64'), ...
    fullfile(helpers, 'GPUgaussMLE.mexw64'), ...
    fullfile(toolbox, 'Segmentation', 'cMakeSubregions.mexw64'), ...
    fullfile(helpers, 'cHistRecon3D.mexw64'), fullfile(helpers, 'cHistRecon.mexw64')};
roles = {'GPU enumeration', '3D GPU localization', '2D GPU localization', ...
    'optional Gaussian initializer (not used by the standard 3D call)', ...
    'segmentation, including CPU workflow', '3D reconstruction histogram', ...
    '2D reconstruction histogram'};
if strcmp(profile.id,'biplane')
    names(3) = []; files(3) = []; roles(3) = [];
end
allImports = {};
for k = 1:numel(names)
    b = struct('name', names{k}, 'file', files{k}, 'role', roles{k}, ...
        'resolvedFile', which(names{k}), 'machine', '', 'imports', {{}}, 'error', '');
    try
        [b.imports, b.machine] = readPEImports(files{k});
        allImports = [allImports b.imports]; %#ok<AGROW>
    catch ME
        b.error = ME.message;
    end
    report.binaries(k) = b;
end
allImports = unique(allImports);

% Search a bounded set of installed/toolbox/private directories, not a disk scan.
candidates = {fullfile(root, 'runtime', 'win64')};
if ~isempty(opt.RuntimeDirectory)
    candidates = [{opt.RuntimeDirectory, fullfile(opt.RuntimeDirectory, 'bin')} candidates];
end
envNames = {'CUDA_PATH', 'CUDA_PATH_V7_5', 'CUDA_PATH_V7_0'};
for k = 1:numel(envNames)
    value = getenv(envNames{k});
    if ~isempty(value), candidates{end+1} = fullfile(value, 'bin'); end %#ok<AGROW>
end
cudaRoot = fullfile(getenv('ProgramFiles'), 'NVIDIA GPU Computing Toolkit', 'CUDA');
versions = dir(fullfile(cudaRoot, 'v*'));
for k = 1:numel(versions)
    if versions(k).isdir
        candidates{end+1} = fullfile(cudaRoot, versions(k).name, 'bin'); %#ok<AGROW>
    end
end
candidates = uniquePaths(candidates);
searchPaths = uniquePaths([{fullfile(matlabroot, 'bin', 'win64'), ...
    fullfile(getenv('SystemRoot'), 'System32')} projectPaths strsplit(getenv('PATH'), ';')]);
% Only add a directory if it supplies an exact missing CUDA runtime filename.
% VC runtimes often use SxS manifests and should be installed via Microsoft.
for k = 1:numel(allImports)
    dll = allImports{k};
    if isempty(regexpi(dll, '^cudart64_.*\.dll$', 'once')), continue; end
    if ~isempty(findDLL(dll, searchPaths)), continue; end
    for j = 1:numel(candidates)
        found = findDLL(dll, candidates(j));
        if isempty(found), continue; end
        try
            [~, machine] = readPEImports(found);
            if ~strcmp(machine, 'AMD64'), continue; end
        catch
            continue;
        end
        setenv('PATH', [candidates{j} ';' getenv('PATH')]);
        searchPaths = [candidates(j) searchPaths]; %#ok<AGROW>
        report.addedRuntimePaths{end+1} = candidates{j};
        break;
    end
end

for k = 1:numel(allImports)
    report.dependencies(k).name = allImports{k};
    report.dependencies(k).file = findDLL(allImports{k}, searchPaths);
end
report.notes{end+1} = 'DLL scan covers direct imports and explicit directories only; Windows SxS/transitive dependencies are not certified.';
report.notes{end+1} = 'A newer Toolkit does not supply cudart64_75.dll. A CUDA Version in nvidia-smi is not an installed Toolkit inventory.';
report.notes{end+1} = 'Bundled 3D and listGPUs require CUDA 7.5 runtime and VC++ 2013 x64; inspect the actual imports above if binaries are replaced.';
report.notes{end+1} = 'MSVCR90/100/120 correspond to VC++ 2008/2010/2013. A current VC++ 2015-2022 runtime alone does not replace them.';
report.notes{end+1} = 'GPUgaussMLE uses CUDA 7.0 but the standard 3D genIniguess(data,median) branch does not call it.';
report.notes{end+1} = 'No driver/runtime installers were run. Use official NVIDIA/Microsoft packages, not DLL download sites or renamed DLLs.';

report.gpuCheck = struct('status', 'NOT_RUN', 'output', '', ...
    'errorIdentifier', '', 'errorMessage', '', 'stack', '');
if opt.TestGPU
    if ~samePath(which('listGPUs'), files{1})
        report.gpuCheck.status = 'SHADOWED';
        report.gpuCheck.errorMessage = 'A different listGPUs is selected. Start a clean MATLAB session and check which listGPUs -all.';
    else
        try
            report.gpuCheck.output = evalc('listGPUs;');
            report.gpuCheck.status = 'ENUMERATION_RETURNED';
        catch ME
            report.gpuCheck.status = 'FAILED';
            report.gpuCheck.errorIdentifier = ME.identifier;
            report.gpuCheck.errorMessage = ME.message;
            report.gpuCheck.stack = getReport(ME, 'extended', 'hyperlinks', 'off');
        end
    end
end
report.notes{end+1} = 'Enumeration returning does not prove a usable device or successful localization. Check its output and run a small representative 3D dataset.';
report.notes{end+1} = 'RTX 2080 Ti requires compatible device code/PTX. If localization reports no kernel image/invalid device function, rebuild the MEX; PATH changes cannot fix it.';
report.notes{end+1} = [profile.localizationMex ' is deliberately not called without inputs: the native source dereferences prhs before validating nrhs.'];
report.notes{end+1} = 'To start the GUI, change to the reported toolbox directory and run main. Session path changes disappear after MATLAB exits.';
report.toolboxDirectory = toolbox;
report.text = formatReport(report);
fprintf('%s\n', report.text);
if ~isempty(opt.ReportFile)
    [fid, message] = fopen(opt.ReportFile, 'w', 'n', 'UTF-8');
    if fid < 0
        warning('INSPR:CUDA:ReportWrite', 'Cannot write report: %s', message);
        report.reportFile = '';
    else
        closeFile = onCleanup(@() fclose(fid));
        fprintf(fid, '%s\n', report.text);
        fprintf('Report saved: %s\n', opt.ReportFile);
    end
end
end

function text = formatReport(r)
lines = {'INSPR CUDA diagnostic (session-only path repair)', ...
    ['Toolbox: ' r.toolbox], ['MATLAB: ' r.matlabVersion], ['MATLAB root: ' r.matlabRoot], ...
    ['OS: ' strtrim(r.os)], ['NVIDIA query: ' strtrim(r.nvidia)], ...
    ['nvcc query (not required for running prebuilt MEX): ' strtrim(r.nvcc)], ...
    ['GPU enumeration status: ' r.gpuCheck.status], ...
    '3D localization verified: NO', ['Toolbox directory: ' r.toolboxDirectory], ''};
for k = 1:numel(r.addedRuntimePaths)
    lines{end+1} = ['Added to this MATLAB PATH: ' r.addedRuntimePaths{k}]; %#ok<AGROW>
end
for k = 1:numel(r.binaries)
    b = r.binaries(k);
    lines = [lines {['MEX: ' b.name ' [' b.machine '] - ' b.role], ...
        ['  Expected: ' b.file], ['  MATLAB resolves: ' b.resolvedFile], ...
        ['  Direct DLL imports: ' strjoin(b.imports, ', ')]}]; %#ok<AGROW>
    if ~isempty(b.error), lines{end+1} = ['  Inspection error: ' b.error]; end %#ok<AGROW>
end
lines{end+1} = '';
if isfield(r, 'dependencies')
    for k = 1:numel(r.dependencies)
        d = r.dependencies(k);
        if isempty(d.file), location = 'NOT FOUND in checked directories (SxS not checked)';
        else, location = d.file; end
        lines{end+1} = [d.name ': ' location]; %#ok<AGROW>
    end
end
lines = [lines {'' r.gpuCheck.output r.gpuCheck.errorIdentifier ...
    r.gpuCheck.errorMessage r.gpuCheck.stack ''} r.notes];
text = strjoin(lines, char(10)); %#ok<CHARTEN> Compatible with MATLAB before newline().
end

function paths = uniquePaths(paths)
out = {};
for k = 1:numel(paths)
    p = strtrim(strrep(paths{k}, '"', ''));
    if isempty(p) || exist(p, 'dir') ~= 7, continue; end
    % Canonical absolute paths also keep relative runtime folders valid later.
    [ok, attr] = fileattrib(p);
    if ok, p = attr.Name; end
    if ~any(cellfun(@(x) samePath(x, p), out)), out{end+1} = p; end %#ok<AGROW>
end
paths = out;
end

function equal = samePath(a, b)
equal = strcmpi(strrep(a, '/', '\'), strrep(b, '/', '\'));
end

function file = findDLL(name, paths)
file = '';
for k = 1:numel(paths)
    candidate = fullfile(paths{k}, name);
    if exist(candidate, 'file') == 2, file = candidate; return; end
end
end

function [imports, machine] = readPEImports(file)
% Read the PE import directory without loading or executing the binary.
fid = fopen(file, 'rb');
if fid < 0, error('INSPR:CUDA:PE', 'Cannot open binary: %s', file); end
closeFile = onCleanup(@() fclose(fid));
b = fread(fid, Inf, '*uint8')';
if numel(b) < 64 || ~isequal(b(1:2), uint8('MZ'))
    error('INSPR:CUDA:PE', 'Not a Windows PE file: %s', file);
end
pe = uintLE(b, 60, 4);
if ~isequal(b(pe+(1:4)), uint8([80 69 0 0]))
    error('INSPR:CUDA:PE', 'Invalid PE signature: %s', file);
end
machineCode = uintLE(b, pe+4, 2);
machine = sprintf('0x%04X', machineCode);
if machineCode == 34404, machine = 'AMD64'; end
numSections = uintLE(b, pe+6, 2);
optionalSize = uintLE(b, pe+20, 2);
optional = pe+24;
magic = uintLE(b, optional, 2);
if magic == 523
    directories = optional+112;
elseif magic == 267
    directories = optional+96;
else
    error('INSPR:CUDA:PE', 'Unknown PE optional header.');
end
sections = zeros(numSections, 4);
for k = 1:numSections
    at = optional+optionalSize+(k-1)*40;
    sections(k,:) = [uintLE(b,at+12,4), max(uintLE(b,at+8,4),uintLE(b,at+16,4)), ...
        uintLE(b,at+20,4), uintLE(b,at+16,4)];
end
imports = {};
rva = uintLE(b, directories+8, 4);
if rva == 0, return; end
offset = rvaOffset(rva, sections);
while any(b(offset+(1:20)))
    nameOffset = rvaOffset(uintLE(b, offset+12, 4), sections);
    tail = b(nameOffset+1:end);
    stop = find(tail == 0, 1);
    if isempty(stop), error('INSPR:CUDA:PE', 'Unterminated import name.'); end
    imports{end+1} = char(tail(1:stop-1)); %#ok<AGROW>
    offset = offset+20;
end
end

function n = uintLE(b, offset, count)
n = double(b(offset+(1:count))) * (256.^(0:count-1))';
end

function offset = rvaOffset(rva, sections)
index = find(rva >= sections(:,1) & rva < sections(:,1)+sections(:,2), 1);
if isempty(index) || rva-sections(index,1) >= sections(index,4)
    error('INSPR:CUDA:PE', 'Import RVA is outside the file-backed sections.');
end
offset = rva-sections(index,1)+sections(index,3);
end
