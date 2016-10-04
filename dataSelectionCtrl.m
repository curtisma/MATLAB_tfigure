classdef dataSelectionCtrl < ctrlInterface
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gui
    end
    
    methods
        function obj = dataSelectionCtrl(varargin)
        end
        function ctrl(obj,h_panel,varargin)
        % Defines a data selection interface
            p = inputParser;
            p.KeepUnmatched = true;
            p.addParameter('fileTable',false,@islogical);
            p.parse(varargin{:});
            obj.guiCtrl.fileTable = p.Results.fileTable;
            
            % Setup Layout
            h.OuterBox = uix.VBox('Parent',h_panel);
                h.ctrlTitle = uicontrol(h.OuterBox,'Style','text','String','Data Selection','FontSize',15);
                h.dataTitle = uicontrol('Parent',h.OuterBox,'Style','text','String','Selected Data Files','FontSize',13);
                h.dataBox = uix.HBox('Parent',h.OuterBox);
                    h.dataButtonsBox = uix.VButtonBox('Parent',h.dataBox,'VerticalAlignment','top');
                        h.buttonFolder = uicontrol(h.dataButtonsBox,'Style','pushbutton','String','F','Callback',@obj.loadFolder,'TooltipString','Load all MAT datafiles in a folder');
                        h.buttonAddData = uicontrol(h.dataButtonsBox,'Style','pushbutton','String','+','FontSize',12,'Callback',@obj.loadFile,'TooltipString','Load specific MAT datafile(s)');
                        h.buttonDelData = uicontrol(h.dataButtonsBox,'Style','pushbutton','String','-','FontSize',12,'Callback',@obj.removeFile,'TooltipString','Remove specific MAT datafile(s)');
                        h.buttonReloadData = uicontrol(h.dataButtonsBox,'Style','pushbutton','String','R','FontSize',12);
                        set(h.dataButtonsBox,'Spacing',5,'ButtonSize',[75 30]);
                    if(obj.guiCtrl.fileTable)
                        h.fileList = uitable(h.dataBox,'FontSize',11);
                    else
                        h.fileList = uicontrol(h.dataBox,'Style','listbox','String','Select data folder or add data files','FontSize',11,'Max',10,'Min',0);
                    end
                    set(h.dataBox,'Spacing',5,'Widths',[60 -1]);
                h.emptySpace = uix.Empty('Parent',h.OuterBox);
            set(h.OuterBox,'Heights',[25,25,-2,-1],'Spacing',5);
            obj.guiCtrl.layout = h;
        end
        function loadFolder(obj,varargin)
            %loadFolder Loads all the .mat files in a directory
            % Loads all the .mat files in a folder
            %
            %
            if(nargin == 3 && isa(varargin{1},'matlab.ui.control.UIControl'))
                p.Results.dirName = [];
            else
                p = inputParser;
                p.KeepUnmatched = true;
                p.addOptional('dirName',[],@ischar);
                p.parse(varargin{:});
            end
            if(isempty(p.Results.dirName))
                if(isfield(obj.guiCtrl,'lastLoadFolderDir'))
                    startDir = obj.guiCtrl.lastLoadFolderDir;
                else
                    startDir = pwd;
                end
                dirName = uigetdir(startDir,'Select the dataset directory');
                if(dirName == 0)
                    return;
                end
            end
            obj.guiCtrl.lastLoadFolderDir = dirName;
            D = dir(dirName);
            names = {D.name};
            [~,~,ext] = cellfun(@fileparts,names,'UniformOutput',false);
            dataPaths = cellfun(@(x) [dirName filesep x],names(strcmp(ext,'.mat')),'UniformOutput',false);
            if(isfield('obj.guiCtrl','dataPaths'))
            % Add to existing dataPaths
                dataPaths = setdiff(dataPaths, obj.guiCtrl.dataPaths);
                obj.guiCtrl.dataPaths = [obj.guiCtrl.dataPaths dataPaths];
            else
                obj.guiCtrl.dataPaths = dataPaths;
            end
            % Setup data selection display
            if(~isempty(obj.guiCtrl) && ~obj.guiCtrl.fileTable && ~isempty(dataPaths))
                [~, fileNames, ~] = cellfun(@fileparts,obj.guiCtrl.dataPaths,'UniformOutput',false);
                obj.guiCtrl.layout.fileList.String = cellfun(@(x,y) [x '  (' y ')'],fileNames,obj.guiCtrl.dataPaths,'UniformOutput',false);
            elseif(~isempty(obj.guiCtrl) && obj.guiCtrl.fileTable)
                
            end
            
%             obj.loadDatasets;
        end
        function loadFile(obj,varargin)
        %loadFile Ass a .mat file
        % Loads a .mat file
        %
            if(nargin == 3 && isa(varargin{1},'matlab.ui.control.UIControl'))
                p.Results.file = [];
            else
                p = inputParser;
                p.KeepUnmatched = true;
                p.addOptional('file',[],@ischar);
                p.parse(varargin{:});
            end
            if(isempty(p.Results.file))
                if(isfield(obj.guiCtrl,'lastLoadFileDir'))
                    startDir = obj.guiCtrl.lastLoadFileDir;
                else
                    startDir = pwd;
                end
                [fileName,pathName] = uigetfile({'*.mat','MAT-files (*.mat)'; ...
                    '*.*',  'All Files (*.*)'},'Select the dataset(s)',...
                    startDir,'MultiSelect', 'on');
                if(isnumeric(fileName) && fileName == 0)
                    return;
                end
            end
            obj.guiCtrl.lastLoadFileDir = pathName;
            if(~iscell(fileName))
                fileName = {fileName};
            end
            dataPaths = cellfun(@(x) fullfile(pathName, x),fileName,'UniformOutput',false);
            if(isfield(obj.guiCtrl,'dataPaths'))
            % Add to existing dataPaths
                dataPaths = setdiff(dataPaths, obj.guiCtrl.dataPaths);
                obj.guiCtrl.dataPaths = [obj.guiCtrl.dataPaths dataPaths];
            else
                obj.guiCtrl.dataPaths = dataPaths;
            end
            % Setup data selection display
            if(~isempty(obj.guiCtrl) && ~obj.guiCtrl.fileTable && ~isempty(dataPaths))
                [~, fileNames, ~] = cellfun(@fileparts,obj.guiCtrl.dataPaths,'UniformOutput',false);
                obj.guiCtrl.layout.fileList.String = cellfun(@(x,y) [x '  (' y ')'],fileNames,obj.guiCtrl.dataPaths,'UniformOutput',false);
            elseif(~isempty(obj.guiCtrl) && obj.guiCtrl.fileTable)
                
            end
        end
        function removeFile(varargin)
            if(nargin == 3 && isa(varargin{1},'matlab.ui.control.UIControl'))
                p.Results.file = [];
            else
                p = inputParser;
                p.KeepUnmatched = true;
                p.addOptional('file',[],@ischar);
                p.parse(varargin{:});
            end
            
        end
        function data = loadDatasets(obj,varargin)
            for dNum = 1:length(obj.datasetPaths)
                data = load(obj.guiCtrl.datasetPaths{dNum});
                obj.datasets(dNum) = data.MAT;
            end
        end
    end
end

