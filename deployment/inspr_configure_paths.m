function inspr_configure_paths(profile)
% Both distributions contain same-named functions/classes and GUI globals.
% Keep one project/toolbox per MATLAB process; do not clear user state to switch.
persistent activeDirectory
if ~isempty(activeDirectory) && ~strcmpi(activeDirectory,profile.directory)
    error('INSPR:Runtime:ToolboxConflict', ...
        'This MATLAB session already uses another INSPR toolbox. Open a new MATLAB window for %s.',profile.id);
end
if strcmpi(pwd,profile.otherBase) || strncmpi(pwd,[profile.otherBase filesep],numel(profile.otherBase)+1)
    error('INSPR:Runtime:ToolboxConflict','Current Folder is inside the other toolbox. Start a new MATLAB window in the selected toolbox directory.');
end
for k = 1:numel(profile.paths)
    if exist(profile.paths{k},'dir') ~= 7
        error('INSPR:Runtime:IncompleteProject','Required INSPR directory is missing: %s',profile.paths{k});
    end
end
% Refuse already-loaded code from the other tree, including pre-repair GUIs.
[loaded,mexLoaded] = inmem('-completenames');
loaded = [loaded(:);mexLoaded(:)];
if any(strncmpi(loaded,[profile.otherBase filesep],numel(profile.otherBase)+1))
    error('INSPR:Runtime:ToolboxConflict','The other INSPR toolbox has already loaded code. Use a fresh MATLAB process.');
end
entries = regexp(path,pathsep,'split');
for k = 1:numel(entries)
    if strcmpi(entries{k},profile.otherBase) || strncmpi(entries{k},[profile.otherBase filesep],numel(profile.otherBase)+1)
        rmpath(entries{k});
    end
end
for k = numel(profile.paths):-1:1, addpath(profile.paths{k}); end
activeDirectory = profile.directory;
end
