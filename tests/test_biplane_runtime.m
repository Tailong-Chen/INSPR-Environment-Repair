function test_biplane_runtime
% Fresh isolated MATLAB only. Never share the legacy CUDA reset with a GUI.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root, fullfile(root,'deployment'));
% Remove unused paths from the other distribution before choosing helpers.
other = fullfile(root,'INSPR for astigmatism-based setup','Support','Helpers');
addpath(other);
folder = pwd;
restoreFolder = onCleanup(@() cd(folder));
cd(root);
try
    inspr_toolbox_profile(root,'auto');
    error('INSPR:Test:ExpectedError','Ambiguous root silently selected a toolbox.');
catch ME
    assert(strcmp(ME.identifier,'INSPR:Runtime:SelectToolbox'));
end
evalc('r = setup_inspr_cuda(''Toolbox'', ''biplane'', ''TestGPU'', false, ''ReportFile'', '''');');
assert(strcmp(r.toolbox, 'biplane'));
assert(~r.localizationVerified && strcmp(r.gpuCheck.status,'NOT_RUN'));
names = {r.binaries.name};
idx = find(strcmp(names,'cuda_channel_specific_model'),1);
assert(~isempty(idx) && ~any(strcmp(names,'cuda_ast_model')) && ~any(strcmp(names,'SRsCMOS_MLE')));
assert(any(strcmpi(r.binaries(idx).imports,'cudart64_75.dll')));
assert(strcmpi(which('genpsfstruct'),fullfile(r.toolboxDirectory,'3D_localization','genpsfstruct.m')));
expected = fullfile(root,'INSPR for biplane setup','Support','Helpers','listGPUs.mexw64');
assert(strcmpi(which('listGPUs'),expected));
assert(~any(strcmpi(regexp(path,pathsep,'split'),other)));
cd(r.toolboxDirectory);
automatic = inspr_toolbox_profile(root,'auto');
assert(strcmp(automatic.id,'biplane'));
cd(root);
configured = path;
evalc('setup_inspr_cuda(''Toolbox'', ''biplane'', ''TestGPU'', false, ''ReportFile'', '''');');
assert(strcmp(path,configured),'Repeated setup changed MATLAB paths.');
try
    setup_inspr_cuda('Toolbox','astigmatism','TestGPU',false,'ReportFile','');
    error('INSPR:Test:ExpectedError','Mixed toolboxes were accepted in one MATLAB session.');
catch ME
    assert(strcmp(ME.identifier,'INSPR:Runtime:ToolboxConflict'));
end
assert(strcmp(path,configured),'Rejected toolbox switch changed paths.');
result = inspr_gpu_smoketest('biplane');
assert(result.passed && strcmp(result.toolbox,'biplane') && numel(result.parameters)==7);
disp('PASS: biplane diagnostics, dependency selection, path isolation and real GPU fit.');
end
