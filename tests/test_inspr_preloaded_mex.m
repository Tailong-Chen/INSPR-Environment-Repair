function test_inspr_preloaded_mex
% Fresh MATLAB only: a MEX may be loaded even when no other toolbox .m is.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'deployment'));
inspr_prepare_runtime(root);
other = fullfile(root,'INSPR for astigmatism-based setup','Support','Helpers');
addpath(other);
evalc('listGPUs;');
before = path;
try
    inspr_configure_paths(inspr_toolbox_profile(root,'biplane'));
    error('INSPR:Test:ExpectedError','An already loaded MEX from the other toolbox was accepted.');
catch ME
    assert(strcmp(ME.identifier,'INSPR:Runtime:ToolboxConflict'));
end
assert(strcmp(path,before),'Conflict detection changed paths.');
disp('PASS: already loaded MEX from the other toolbox is rejected without changing paths.');
end
