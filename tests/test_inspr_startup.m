function test_inspr_startup
% Run only in a fresh, isolated MATLAB: the smoke test resets its GPU context.
% Catches loss of the main.m bootstrap: no launcher PATH is available here.
root = fileparts(fileparts(mfilename('fullpath')));
toolbox = fullfile(root, 'INSPR for astigmatism-based setup', 'INSPR astigmatism toolbox');
runtime = fullfile(root, 'runtime', 'win64');
originalPath = getenv('PATH');
originalFolder = pwd;
originalVisibility = get(0, 'DefaultFigureVisible');
cleanup = onCleanup(@() restoreSession(originalPath, originalFolder, originalVisibility));
entries = regexp(originalPath, ';', 'split');
entries(strcmpi(entries, runtime)) = [];
setenv('PATH', strjoin(entries, ';'));
set(0, 'DefaultFigureVisible', 'off');
run(fullfile(toolbox, 'main.m'));
assert(~isempty(findall(0, 'Type', 'figure', 'Name', 'INSPR_ast_GUI')));
try
    evalc('listGPUs;');
catch ME
    error('INSPR:Test:Startup', 'Direct main.m did not make the GPU MEX loadable: %s', ME.message);
end
assert(any(strcmpi(regexp(getenv('PATH'), ';', 'split'), runtime)));
configuredPath = getenv('PATH');
global data_empupil;
savedState = data_empupil;
inspr_prepare_runtime(root);
assert(strcmp(getenv('PATH'), configuredPath), 'Repeated setup duplicated the DLL path.');
assert(isequaln(data_empupil, savedState), 'Runtime setup changed GUI state.');
addpath(root);
evalc('setup_inspr_cuda(''Toolbox'', ''astigmatism'', ''TestGPU'', false, ''ReportFile'', '''');');
result = inspr_gpu_smoketest;
assert(result.passed);
fprintf('PASS: direct main.m loaded the GUI and ran GPU localization without the launcher.\n');
end

function restoreSession(originalPath, originalFolder, originalVisibility)
close(findall(0, 'Type', 'figure', 'Name', 'INSPR_ast_GUI'));
setenv('PATH', originalPath);
cd(originalFolder);
set(0, 'DefaultFigureVisible', originalVisibility);
end
