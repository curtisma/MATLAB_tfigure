classdef (Abstract) ctrlInterface < hgsetget
    %ctrlInterface An interface for a control panel
    %   An abstract interface which can be subclassed when creating a
    %   control panel for use with tfigure.
    
    properties
        gui
        guiCtrl % control Panel
    end
    properties (Abstract)
        
    end
    methods
        function obj = ctrlInterface(varargin)
        %ctrlInterface Constructor
        % See also: ctrlInterface
            % Parse Inputs
            p=inputParser;
            p.addParameter('gui',[],@(x) isa(x,'tfigure'))
            p.parse(varargin{:});
            % Set gui
            obj.gui = p.Results.gui;
        end
        function set.gui(obj,gui) % Setting GUI adds the simulation control to the first tab.
            if(~isa(gui,'tfigure') && ~isempty(gui))
                    error('The GUI needs to be a tfigure')
            end
            obj.gui = gui;
            % GUI setup
            if(~isempty(obj.gui))
                if(length(obj.gui.tabs) == 1)
                    h = obj.gui.addCtrl('Simulation',@(x) obj.ctrl(x),'tab',obj.gui.tabs);
                else
                    h = obj.gui.addCtrl('Simulation',@(x) obj.ctrl(x),'tab',obj.gui.tabs(1));
                end
                obj.guiCtrl = h.UserData.hp;
            end
        end
    end
    methods (Abstract)
        ctrl(obj,h_panel,varargin)
    end
end

