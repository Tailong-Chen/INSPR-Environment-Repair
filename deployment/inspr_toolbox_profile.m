function profile = inspr_toolbox_profile(root, id)
% Resolve an entry point without changing the MATLAB path or loading a MEX.
if nargin < 2 || isempty(id), id = 'auto'; end
ids = {'astigmatism','biplane'};
bases = {'INSPR for astigmatism-based setup','INSPR for biplane setup'};
folders = {'INSPR astigmatism toolbox','INSPR toolbox'};
guis = {'INSPR_ast_GUI','INSPR_GUI'};
mexes = {'cuda_ast_model','cuda_channel_specific_model'};
present = false(1,2);
for k = 1:2
    present(k) = exist(fullfile(root,bases{k},folders{k},'main.m'),'file') == 2;
end
if strcmpi(id,'auto')
    selected = find(present);
    if numel(selected) > 1
        inside = false(1,2);
        for k = 1:2
            base = fullfile(root,bases{k});
            inside(k) = strcmpi(pwd,base) || strncmpi(pwd,[base filesep],numel(base)+1);
        end
        selected = find(present & inside);
    end
    if numel(selected) ~= 1
        error('INSPR:Runtime:SelectToolbox', ...
            'Specify Toolbox as astigmatism or biplane. Keep the repair in the existing project root.');
    end
else
    selected = find(strcmpi(id,ids),1);
    if isempty(selected) || ~present(selected)
        error('INSPR:Runtime:MissingToolbox','Requested INSPR toolbox is missing or unknown: %s',id);
    end
end
k = selected;
profile.id = ids{k};
profile.base = fullfile(root,bases{k});
profile.directory = fullfile(profile.base,folders{k});
profile.main = fullfile(profile.directory,'main.m');
profile.gui = guis{k};
profile.localizationMex = mexes{k};
profile.otherBase = fullfile(root,bases{3-k});
profile.helpers = fullfile(profile.base,'Support','Helpers');
profile.paths = {profile.directory, fullfile(profile.directory,'Segmentation'), ...
    fullfile(profile.directory,'INSPR_model_generation'), fullfile(profile.directory,'3D_localization'), ...
    fullfile(profile.base,'Support','PSF Toolbox'), fullfile(profile.base,'Support','SRsCMOS'), profile.helpers};
if strcmp(profile.id,'astigmatism')
    profile.paths{end+1} = fullfile(profile.directory,'2D_localization');
else
    profile.paths{end+1} = fullfile(profile.directory,'Biplane_registration');
end
end
