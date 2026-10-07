function inspr_start_gui
% Configure this MATLAB session, then launch the existing toolbox unchanged.
projectRoot = getenv('INSPR_PROJECT_ROOT');
toolbox = getenv('INSPR_TOOLBOX');
if isempty(toolbox) || strcmpi(toolbox,'auto')
    ids = {'astigmatism','biplane'};
    available = {};
    for k = 1:2
        try
            inspr_toolbox_profile(projectRoot,ids{k});
            available{end+1} = ids{k}; %#ok<AGROW>
        catch ME
            if ~strcmp(ME.identifier,'INSPR:Runtime:MissingToolbox'), rethrow(ME); end
        end
    end
    if numel(available) > 1
        [choice,ok] = listdlg('Name','INSPR toolbox','PromptString','Choose the toolbox for this MATLAB window:', ...
            'ListString',available,'SelectionMode','single','ListSize',[320 100]);
        if ~ok, return; end
        toolbox = available{choice};
    elseif numel(available) == 1
        toolbox = available{1};
    else
        error('INSPR:Runtime:MissingToolbox','No INSPR toolbox found.');
    end
end
addpath(projectRoot);
report = setup_inspr_cuda('Toolbox', toolbox, 'RuntimeDirectory', fullfile(projectRoot,'runtime','win64'), ...
    'TestGPU', false, 'ReportFile', '');
cd(report.toolboxDirectory);
main;
end
