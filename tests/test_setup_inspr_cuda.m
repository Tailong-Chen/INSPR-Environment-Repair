function test_setup_inspr_cuda
% Integration checks for the portable diagnostic, without installing runtimes.
root = fileparts(fileparts(mfilename('fullpath')));
oldPath = path;
oldEnv = getenv('PATH');
oldFolder = pwd;
cleanup = onCleanup(@() restoreSession(oldPath, oldEnv, oldFolder));
addpath(root);
assert(exist('setup_inspr_cuda', 'file') == 2, ...
    'INSPR:Test:MissingSetup', 'The portable setup entry point is missing.');
logFile = [tempname '.txt'];
logCleanup = onCleanup(@() deleteLog(logFile));
cd(tempdir);
folderBefore = pwd;
evalc('r = setup_inspr_cuda(''TestGPU'', false, ''ReportFile'', logFile);');
assert(strcmp(pwd, folderBefore), 'Setup unexpectedly changed the current folder.');
assert(strcmp(r.gpuCheck.status, 'NOT_RUN'));
assert(~r.localizationVerified, 'Enumeration must not certify localization.');
idx = find(strcmp({r.binaries.name}, 'cuda_ast_model'), 1);
assert(~isempty(idx));
assert(any(strcmpi(r.binaries(idx).imports, 'cudart64_75.dll')), ...
    'The report missed the actual CUDA 7.5 dependency.');
assert(any(strcmpi(r.binaries(idx).imports, 'MSVCR120.dll')), ...
    'The report missed the independent VC++ 2013 dependency.');
assert(strcmpi(r.binaries(idx).machine, 'AMD64'));
assert(exist(logFile, 'file') == 2);
assert(~isempty(strfind(fileread(logFile), 'cudart64_75.dll'))); %#ok<STREMP>
assert(~isempty(which('INSPR_ast_GUI')) && ~isempty(which('loc_ast_model')));
envAfter = getenv('PATH');
pathAfter = path;
evalc('setup_inspr_cuda(''TestGPU'', false, ''ReportFile'', '''');');
assert(strcmp(getenv('PATH'), envAfter), 'Repeated setup duplicates DLL paths.');
assert(strcmp(path, pathAfter), 'Repeated setup duplicates MATLAB paths.');
try
    setup_inspr_cuda('RuntimeDirectory', fullfile(tempdir, 'inspr-no-such-folder-705'), ...
        'TestGPU', false, 'ReportFile', '');
    error('INSPR:Test:ExpectedError', 'Missing runtime directory was accepted.');
catch ME
    assert(strcmp(ME.identifier, 'INSPR:CUDA:RuntimeDirectory'));
end
assert(strcmp(getenv('PATH'), envAfter));
assert(strcmp(path, pathAfter));
% A non-executable PE metadata fixture exercises the repair branch without
% installing CUDA. TestGPU=false is essential: this is not a runtime DLL.
dep = find(strcmpi({r.dependencies.name}, 'cudart64_75.dll'), 1);
if isempty(r.dependencies(dep).file)
    fixtureFolder = tempname;
    mkdir(fixtureFolder);
    fixtureCleanup = onCleanup(@() removeFixture(fixtureFolder, envAfter));
    bytes = zeros(1, 512, 'uint8');
    bytes(1:2) = uint8('MZ');
    bytes(61) = 128;
    bytes(129:132) = uint8([80 69 0 0]);
    bytes(133:134) = uint8([100 134]); % AMD64
    bytes(149) = 240;
    bytes(153:154) = uint8([11 2]); % PE32+, empty import table
    fid = fopen(fullfile(fixtureFolder, 'cudart64_75.dll'), 'wb');
    fwrite(fid, bytes, 'uint8'); fclose(fid);
    evalc('fixed = setup_inspr_cuda(''RuntimeDirectory'', fixtureFolder, ''TestGPU'', false, ''ReportFile'', '''');');
    assert(strcmp(fixed.gpuCheck.status, 'NOT_RUN'));
    assert(any(strcmp(fixed.addedRuntimePaths, fixtureFolder)));
    fixedEnv = getenv('PATH');
    evalc('setup_inspr_cuda(''RuntimeDirectory'', fixtureFolder, ''TestGPU'', false, ''ReportFile'', '''');');
    assert(strcmp(getenv('PATH'), fixedEnv));
    clear fixtureCleanup; % Remove fixture and restore PATH before any MEX call.
end
% Exercise the real MEX boundary. Pass and fail are environment-dependent;
% either way, the report must retain the evidence and never claim kernel QA.
evalc('r = setup_inspr_cuda(''ReportFile'', '''');');
assert(~r.localizationVerified);
assert(any(strcmp(r.gpuCheck.status, {'ENUMERATION_RETURNED', 'FAILED', 'SHADOWED'})));
if strcmp(r.gpuCheck.status, 'FAILED')
    assert(~isempty(r.gpuCheck.errorMessage));
    assert(~isempty(r.gpuCheck.errorIdentifier));
end
disp('PASS: portable setup integration checks');
end

function restoreSession(p, e, folder)
path(p);
setenv('PATH', e);
cd(folder);
end

function deleteLog(file)
if exist(file, 'file'), delete(file); end
end

function removeFixture(folder, oldEnv)
setenv('PATH', oldEnv);
delete(fullfile(folder, 'cudart64_75.dll'));
rmdir(folder);
end
