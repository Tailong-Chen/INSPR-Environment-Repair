function inspr_runtime_probe
% Entry point used only in the launcher's isolated MATLAB verification process.
projectRoot = getenv('INSPR_PROJECT_ROOT');
statusFile = getenv('INSPR_PROBE_STATUS');
reportFile = getenv('INSPR_PROBE_REPORT');
try
    profile = inspr_toolbox_profile(projectRoot,getenv('INSPR_TOOLBOX'));
    fprintf('INSPR toolbox: %s\n',profile.id);
    fprintf('Validating MATLAB %s (%s), %s\n', version, version('-release'), computer('arch'));
    % Prove main.m works without inheriting the launcher's private DLL path.
    % This entire probe runs in an isolated MATLAB, never in the user's GUI.
    runtime = fullfile(projectRoot, 'runtime', 'win64');
    entries = regexp(getenv('PATH'), ';', 'split');
    entries(strcmpi(entries, runtime)) = [];
    setenv('PATH', strjoin(entries, ';'));
    visibility = get(0, 'DefaultFigureVisible');
    restoreVisibility = onCleanup(@() set(0, 'DefaultFigureVisible', visibility));
    set(0, 'DefaultFigureVisible', 'off');
    run(profile.main);
    figures = findall(0, 'Type', 'figure', 'Name', profile.gui);
    assert(~isempty(figures), 'INSPR:Runtime:GUI', 'main.m did not open the INSPR GUI.');
    assert(any(strcmpi(regexp(getenv('PATH'), ';', 'split'), runtime)), ...
        'INSPR:Runtime:Startup', 'main.m did not configure the private CUDA runtime.');
    listGPUs;
    close(figures);
    clear restoreVisibility;
    fprintf('INSPR_STARTUP_OK: main.m configured this MATLAB without a launcher PATH.\n');
    addpath(projectRoot);
    setup_inspr_cuda('Toolbox', profile.id, 'RuntimeDirectory', fullfile(projectRoot,'runtime','win64'), ...
        'ReportFile', reportFile);
    result = inspr_gpu_smoketest(profile.id);
    assert(result.passed);
    writeStatus(statusFile, 'INSPR_RUNTIME_OK');
catch ME
    writeStatus(statusFile, ['FAILED: ' ME.identifier char(10) ...
        getReport(ME,'extended','hyperlinks','off')]);
    rethrow(ME);
end
end

function writeStatus(file, value)
[fid, message] = fopen(file,'w','n','UTF-8');
if fid<0, error('INSPR:Runtime:StatusWrite','%s',message); end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',value);
end
