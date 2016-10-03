classdef (Abstract) ctrlInterface < hgsetget
    %ctrlInterface An interface for a control panel
    %   An abstract interface which can be subclassed when creating a
    %   control panel for use with tfigure.
    
    properties
        guiCtrl % control Panel
    end
    properties (Abstract)
        gui
    end
    methods
        function obj = ctrlInterface(varargin)
        %ctrlInterface Constructor
        % 
        % PARAMAMETERS
        %  gui - Add a tfigure handle to the interface
        %
        % See also: ctrlInterface
            % Parse Inputs
            p=inputParser;
            p.addParameter('gui',[],@(x) isa(x,'tfigure'))
            p.parse(varargin{:});
            % Set gui
            obj.gui = p.Results.gui;
        end
    end
    methods (Abstract)
        ctrl(obj,h_panel,varargin)
    end
end

