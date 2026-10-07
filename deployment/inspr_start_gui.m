function inspr_start_gui
% Configure this MATLAB session, then launch the existing toolbox unchanged.
projectRoot = getenv('INSPR_PROJECT_ROOT');
addpath(projectRoot);
report = setup_inspr_cuda('RuntimeDirectory', fullfile(projectRoot,'runtime','win64'), ...
    'TestGPU', false, 'ReportFile', '');
cd(report.toolboxDirectory);
main;
end
