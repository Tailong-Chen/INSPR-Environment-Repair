function inspr_prepare_runtime(projectRoot)
% Add this project's private CUDA DLL to the current MATLAB process.
% Called automatically by main.m after the one-time repair. No installers,
% GPU resets, savepath, startup.m edits, or changes to GUI state happen here.
if nargin < 1
    projectRoot = fileparts(fileparts(mfilename('fullpath')));
end
if ~ispc || ~strcmp(computer('arch'), 'win64')
    error('INSPR:Runtime:Platform', 'The bundled INSPR MEX files require 64-bit Windows MATLAB.');
end
runtime = fullfile(projectRoot, 'runtime', 'win64');
if exist(fullfile(runtime, 'cudart64_75.dll'), 'file') ~= 2
    warning('INSPR:Runtime:Missing', ...
        'Private CUDA runtime is missing. Extract the full repair ZIP and run Start-INSPR.cmd once.');
    return;
end
entries = regexp(getenv('PATH'), ';', 'split');
entries(strcmpi(entries, runtime)) = [];
setenv('PATH', strjoin([{runtime} entries], ';'));
end
