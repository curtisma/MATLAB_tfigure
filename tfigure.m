classdef tfigure < hgsetget
    %% TFIGURE 
    % A figure for holding tabbed groups of plots.
    % Creates a tabbed plot figure.  This allows the user to setup tabs
    % to group plots.  Each tab contains a list of plots that can be
    % selected using buttons on the left of the figure.
    %    
    %   Example
    %    h = tfigure;
    %    h = tfigure('Tab_title');
    %
    % tfigure Properties:
    %  fig - Handle to the figure that displays tfigure.
    %  tabs - Handles to each of the tfigure's tabs
    %  figureSize - Current size of the figure containing tfigure
    %
    % tfigure Methods:
    %  tfigure - Constructs a new tabbed figure
    %  addTab - Adds a new tab
    %  addPlot - Adds a new plot to the given tab
    %  addLabel - Adds a label to the plot list
    %  savePPT - Saves all plots to a Power Point presentation.
    %
    % Examples:
    %  tFigExample - tfigure example
    %
    % TO DO:
    %
    % See issues in Github:
    % <https://github.com/curtisma/MATLAB_tfigure/issues>
    %    
    % Author: Curtis Mayberry
    % Curtisma3@gmail.com
    % Curtisma.org
    %
    % See Also: tFigExample
    
    %% *Properties*
    % Class properties
    properties
        fig % Handle to the figure that displays tfigure.
%         tabs % Handles to each of the tfigure's tabs
        menu % Tfigure menu
    end
    properties (Dependent)
        tabs % Handles to each of the tfigure's tabs
        figureSize % Current size of the figure containing tfigure
        gct % Get Current Tab
        gcp % Get Current Panel
    end
    properties (Access = private)
        tabGroup
    end
    %% *Methods*
    % Class methods
    methods
        function obj = tfigure(varargin)
        %% TFIGURE([title_tab1]) Creates a new tabbed figure.
        %  Additional tabs can be added to the figure using the addTab
        %  function.  Plots can be added to each tab by using the addPlot
        %  function.
        %
        % INPUTS
        %  title_tab1 - The title of the first tab to be added. (optional)
        %
        % see also: tFigExample
        %
        	obj.fig = figure('Visible','off',...
                             'SizeChangedFcn',@obj.figResize,...
                             'Interruptible','off'); 
            obj.tabGroup = uitabgroup('Parent', obj.fig);
            if(nargin>0)
                obj.addTab(varargin{:});
            else
                obj.addTab;
            end
%             obj.menu = uimenu(obj.fig,'Label','Tfigure');
            obj.menu = uimenu(obj.fig,'Label','Export');
            uimenu(obj.menu,'Label','Export PPT','Callback',@obj.exportMenu)
            uimenu(obj.menu,'Label','Copy Panel to Clipboard','Callback',@obj.exportToClipboard);
            obj.fig.Visible = 'on';
%             h_add = obj.addTab('+');
%             h_add.ButtonDownFcn = @(x) obj.addTab([],'order',length(obj.tabs)-1);
        end
        function out = get.figureSize(obj)
            out = get(obj.fig,'position');
        end
        function set.figureSize(obj,val)
            set(obj.fig,'position',val);
        end
        function h = addTab(obj,varargin)
        %% addTab([title]) 
        % Adds a new tab with the given title.
        %
        % USAGE:
        %  tfig.addTab(title);
        %

            if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
                p = inputParser;
                addOptional(p,'titleIn',...
                        ['dataset ' num2str(length(obj.tabs)+1)],@isstr);
                p.addParameter('order',[], ...
                             @(x) isnumeric(x) && (x >= 1) && ... 
                             (x <= (length(obj.tabs)+1)))
                p.addParameter('listName','Plots', @ischar)
                parse(p,varargin{:});
            else
                % When called from the menu there is automatically 2
                % inputs, the menu and the eventData
                p.Results.titleIn = ['dataset ' num2str(length(obj.tabs)+1)];
                p.Results.order = [];
                p.Results.listName = 'Plots';
                
            end
            
            order = p.Results.order;
            
            % Setup tab
            h = uitab('Parent', obj.tabGroup,...
                      'Title', p.Results.titleIn,'ButtonDownFcn',@obj.selectTab);
            
            % Setup tab order
            if(isempty(order))
%                 obj.tabs(end+1) = h;
            else
%                 obj.tabs((order+1):end+1) = obj.tabs(order:end);
%                 obj.tabs(order) = h;
                if(order == 1)
                    obj.tabGroup.Children = obj.tabGroup.Children([end 1:end-1]);
                elseif((order > 1) && (order < length(obj.tabGroup.Children)))
                    obj.tabGroup.Children = obj.tabGroup.Children([1:(order-1) end (order):end-1]);
                end
            end
            
            % Setup tab context menu
            c = uicontextmenu;
            c.UserData = h;
            h.UIContextMenu = c;
            uimenu(c,'Label','Add Tab','Callback',@obj.addTab);
            uimenu(c,'Label','Add Plot','Callback',@obj.addPlot);
            uimenu(c,'Label','Add Table','Callback',@obj.addTable);
            uimenu(c,'Label','Rename','Callback',@obj.renameDlg,'Separator','on');
            uimenu(c,'Label','Delete','Callback',@obj.deleteDlg);
            
            % Setup plot list
            figSize = obj.figureSize;
            plotList = uibuttongroup('parent',h,...
                            'Units','pixels',...
                            'Position',[10 10  150 figSize(4)-45],...
                            'tag','plotList',...
                            'SelectionChangedFcn',@obj.selectPlot);
            set(plotList,'Title',p.Results.listName);
            
            % Menu
            plotList.UIContextMenu = uicontextmenu;
            plotList.UIContextMenu.UserData = plotList;
            uimenu(plotList.UIContextMenu,'Label','Add Plot','Callback',@obj.addPlot);
            uimenu(plotList.UIContextMenu,'Label','Add Table','Callback',@obj.addTable);
            uimenu(plotList.UIContextMenu,'Label','Add Label','Callback',@obj.addLabel);
            uimenu(plotList.UIContextMenu,'Label','Rename','Callback',@obj.renameDlg,'Separator','on');
            h.UserData = plotList;
            if(length(plotList.Children) <= 1)
                plotList.Visible = 'off';
            end
            % Make the new tab current
            obj.tabGroup.SelectedTab = h;
        end
        function ha = addPlot(obj,varargin)
        %% addPlot([tab],'title',[title],'plotFcn',[function_handle]) 
        % Adds a plot to the given tab.  
        %  When the plot button is selected the plot is selected
        %  
        if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
            p=inputParser;
            p.addOptional('tab',obj.tabGroup.SelectedTab,@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)))
            p.addParameter('plotFcn',[],@(x) (isa(x,'function_handle') || isempty(x)));
            p.addParameter('title','plot',@ischar)
            p.addParameter('order',[],@isnumeric);
            p.parse(varargin{:})
        else
            p.Results.tab = obj.tabGroup.SelectedTab;
            p.Results.plotFcn = [];
            p.Results.title = 'plot';
            p.Results.order = [];
        end
            % Select the Tab
            tab = obj.parseTab(p.Results.tab);
            
            % Add the new analysis panel to the plot list
            plotList = get(tab,'UserData'); % The tab's UserData contains a handle to the uibuttongroup for the tab
            h = uicontrol('parent',plotList,...
                          'Style', 'togglebutton',...
                          'String', p.Results.title,'Units','pixels',...
                          'tag','plot');
                      
            % Setup Context Menu
            c = uicontextmenu;
            c.UserData = h;
            h.UIContextMenu = c;
            uimenu(c,'Label','Rename','Callback',@obj.renameDlg);
            uimenu(c,'Label','Delete','Callback',@obj.deleteDlg);
            exportMenu = uimenu('Parent',c,'Label','Export');
            uimenu(exportMenu,'Label','Copy to Clipboard','Callback',@obj.exportToClipboard);
            uimenu(exportMenu,'Label','Copy to Figure','Callback',@obj.exportToFigure);
            % Setup Panel
            h.UserData.hp = uipanel('Parent',tab,'Units','pixels',...
                                    'tag','plot','BorderType','none');
            h.UserData.hp.UserData.hc = h;

            % Setup Axes
            ha = axes(h.UserData.hp);%,...'Units','pixels',...
%                              'ActivePositionProperty','OuterPosition');
            ha.Visible = 'on';
            
            % Setup order
            order = p.Results.order;
            if(isempty(order) || (order == length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:end 1]);
            elseif((order > 1) && (order < length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:(order-1) 1 (order):end]);
            end
            
            if(~isempty(p.Results.plotFcn))
                h.UserData.fh = p.Results.plotFcn;
                p.Results.plotFcn();
            else
                h.UserData.fh = [];
            end
            plotList.SelectedObject = h;
            obj.selectPlot(plotList,[]);
        end
        function varargout = addTable(obj,varargin)
        %% addTable
        % Adds a table to the given tab.
        %
        % h.addTable([tab])
        %
        if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
            p=inputParser;
            p.addOptional('tab',obj.tabGroup.SelectedTab,@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)))
            p.addParameter('title','table',@ischar)
            p.addParameter('order',[],@isnumeric);
            p.parse(varargin{:})
        else
            p.Results.tab = obj.tabGroup.SelectedTab;
            p.Results.title = 'table';
            p.Results.order = [];
        end
            % Select the Tab
            tab = obj.parseTab(p.Results.tab);
            
            % Add the new plot to the plot list
            plotList = get(tab,'UserData'); % The tab's UserData contains a handle to the uibuttongroup for the tab
            h = uicontrol('parent',plotList,...
                            'Style', 'togglebutton',...
                            'String', p.Results.title,'Units','pixels',...
                            'tag','table');
%             h.UserData = p.Results.fun_handle;
            
            % Setup Context Menu
            c = uicontextmenu;
            c.UserData = h;
            h.UIContextMenu = c;
            uimenu(c,'Label','Rename','Callback',@obj.renameDlg);
            uimenu(c,'Label','Delete','Callback',@obj.deleteDlg);
            
            % Setup Panel
            h.UserData.hp = uipanel('Parent',tab,'Units','pixels',...
                                    'tag','plot','BorderType','none');
            h.UserData.hp.UserData.hc = h;
            h.UserData.fh = [];
            
            % Setup Table
%             h.UserData.fa = uitable('Parent',h.UserData.hp,'Units','pixels');
            ht = uitable('Parent',h.UserData.hp,'Units','normalized','Position',[0 0 1 1]);%,'Units','pixels');
%             h.UserData.fa.Visible = 'on';   
            
            % Setup order
            order = p.Results.order;
            if(isempty(order) || (order == length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:end 1]);
            elseif((order > 1) && (order < length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:(order-1) 1 (order):end]);
            end
            
            plotList.SelectedObject = h;
            obj.selectPlot(plotList,[]);
            
            % Setup outputs
            if(nargout == 0)
                varargout = {};
            elseif(nargout == 1)
                varargout = {ht};
            elseif(nargout == 2)
                varargout = {ht h};
            else
                error('tfigure:addTable:nargoutWrong','The number of outputs must be 0-2');
            end
        end
        function h = addLabel(obj,varargin)
        %% addLabel Adds a label to the plot list
        %
        % USAGE:
        %  h.addLabel(title,[tab],...)
        %  
            if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
                p=inputParser;
                p.addRequired('title',@ischar);
                p.addOptional('tab',obj.tabGroup.SelectedTab,@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)))
                p.addParameter('plotFcn',[],@(x) (isa(x,'function_handle') || isempty(x)));
                p.addParameter('order',[],@isnumeric);
                p.parse(varargin{:})
            else
                p.Results.title = inputdlg('Label:','Label',1,{''});
                p.Results.tab = obj.tabGroup.SelectedTab;
                p.Results.plotFcn = [];
                p.Results.order = [];
            end
            
            % Select the Tab
            tab = obj.parseTab(p.Results.tab);
            
            % Add the new label to the plot list
            plotList = get(tab,'UserData'); % The tab's UserData contains a handle to the uibuttongroup for the tab
            h = uicontrol('parent',plotList,...
                          'Style', 'text',...
                          'String', p.Results.title,'Units','pixels',...
                          'tag','label');
            
            % Setup Context Menu
            c = uicontextmenu;
            c.UserData = h;
            h.UIContextMenu = c;
            uimenu(c,'Label','Rename','Callback',@obj.renameDlg);
            uimenu(c,'Label','Delete','Callback',@obj.deleteDlg);
            
            % Setup order
            order = p.Results.order;
            if(isempty(order) || (order == length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:end 1]);
            elseif((order > 1) && (order < length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:(order-1) 1 (order):end]);
            end
            
            obj.selectPlot(plotList,[]);
        end
        function h = addCtrl(obj,varargin)
        %% addCtrl([tab],[fun_handle(h_panel)],'title',[title]) 
        % Adds a control item to the given tab.  
        % When the button is selected the control panel given by
        % fun_handle is displayed.
        % 
        % fun_handle has a single input that is a handle to the panel that
        % will contain the control panel.
        %  
            p=inputParser;
            p.addOptional('tab',obj.tabGroup.SelectedTab,@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)))
            p.addOptional('fun_handle',[],@(x) isa(x,'function_handle'));
            p.addParameter('title','Options',@ischar)
            p.addParameter('order',[],@isnumeric);
            p.parse(varargin{:})
            
            % Select the Tab
            tab = obj.parseTab(p.Results.tab);
            
            % Add the new control panel to the plot list
            figSize = obj.figureSize;
            plotList = get(tab,'UserData'); % The tab's UserData contains a handle to the uibuttongroup for the tab
            h = uicontrol('parent',plotList,...
                          'Style', 'togglebutton',...
                          'String', p.Results.title,'Units','pixels',...
                          'tag','ctrl');
            % Setup Control Panel
            h_panel = uipanel('Parent',tab,...
                              'Units','pixels',...
                              'Position',[30 30  figSize(3)-30 figSize(4)-30],...
                              'tag','ctrl',...
                              'Title',p.Results.title);
            h.UserData.hp = h_panel;
            
            % Setup Context Menu
            c = uicontextmenu;
            c.UserData = h;
            h.UIContextMenu = c;
            uimenu(c,'Label','Rename','Callback',@obj.renameDlg);
            uimenu(c,'Label','Delete','Callback',@obj.deleteDlg);
%             h.UserData.fa = axes('Parent',tab,'Units','pixels',...
% ...%                              'position',axesSize,...
%                              'ActivePositionProperty','OuterPosition');
%             h.UserData.fa.Visible = 'on';           

            % Setup order
            order = p.Results.order;
            if(isempty(order) || (order == length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:end 1]);
            elseif((order > 1) && (order < length(obj.tabGroup.Children)))
                plotList.Children = plotList.Children([2:(order-1) 1 (order):end]);
            end


            if(~isempty(p.Results.fun_handle))
                h.UserData.fh = p.Results.fun_handle;
                p.Results.fun_handle(h_panel);
            end
            plotList.SelectedObject = h;
            obj.selectPlot(plotList,[]);
        end
        function export(obj,varargin)
        % export Exports an analysis panel, a tab, or an entire tfigure using
        % the specified format
        end
        function exportToClipboard(obj,varargin)
        % exportToClipboard Exports 
            if(nargin == 2)
                p = inputParser;
                p.addOptional('panel',obj.gcp,@(x) strcmp(x.Type,'uipanel'))
                p.parse(varargin{:});
            elseif(nargin == 3)
                if(~isempty(varargin{1}.Parent.UserData) && strcmp(varargin{1}.Parent.UserData.Type,'uicontrol'))
                    p.Results.panel = varargin{1}.Parent.UserData.UserData.hp;
                else
                    p.Results.panel = obj.gcp;
                end
            else
                p.Results.panel = obj.gcp;
            end

            % Copy the panel to a seperate figure and copy tp clipboard
            hf = figure('Visible','off','Color','w');
            hp = copy(p.Results.panel);
            hp.Parent = hf;
            hp.BackgroundColor = 'w';
            hp.Units = 'normalized';
            hp.Position = [0 0 1 1];
            hp.Visible = 'on';
            print(hf,'-clipboard','-dbitmap')
            close(hf);
        end
        function varargout = exportToFigure(obj,varargin)
        % exportToFigure Copies a panel to a new figure
        % 
        % USAGE:
        % hf = h.exportToFigure
        % hf = exportToFigure(h)
        %  Copies current panel (h.gcp) to a new figure with handle hf
        % hf = h.exportToFigure(panel)
        %  Copies panel (panel) to a new figure with handle hf
            if(nargin == 1)
                panel = obj.gcp;
            elseif(isa(varargin{1},'matlab.ui.container.Panel'))
                panel = varargin{1};
            elseif(nargin == 3 && isa(varargin{1},'matlab.ui.container.Menu'))
            % Callback
                panel = varargin{1}.Parent.Parent.UserData.UserData.hp;
            else
                panel = obj.gcp;
            end
            
            if(nargin>2 && ~isa(varargin{1},'matlab.ui.container.Menu'))
                h = figure(varargin{2:end});
            else
                h = figure;
            end
            hp = copy(panel);
            hp.Units = 'normalized';
            hp.Position = [0 0 1 1];
            hp.Parent = h;
            hp.Visible = 'on';
            if(nargout == 1)
                varargout{1} = h;
            elseif(nargout == 2)
                varargout = {h hp};
            end
        end
        function savePPT(obj,varargin)
        %% savePPT 
        % Saves all the plots in tfigure to a powerpoint presentation.  
        % 
        % h.savePPT(...)
        %  Brings up a file selection dialog
        % h.savePPT(fileName,...)
        %
        % PARAMETERS:
        %  title - Title of the presentation
        %  subject - subject of presentation, included in file meta data
        %  comments - comments on the presentation
            if(~(exist('exportToPPTX','file')))
               error('tfigure:NeedExportToPPTX',...
                     ['exportToPPTX must be added to the path. ',...
                     'It can be downloaded from the MATLAB file exchange']);
            end
            if(~isempty(obj.fig.Name))
                figTitle = obj.fig.Name;
            else
                figTitle = ['Figure ' num2str(obj.fig.Number) ' Data'];
            end
            p = inputParser;
            p.addOptional('fileName','',@ischar);
            p.addParameter('title',figTitle);
            p.addParameter('author','');
            p.addParameter('subject','');
            p.addParameter('comments','');
            p.parse(varargin{:});
            if(isempty(p.Results.fileName))
                [fileName,pathname] = uiputfile('.pptx','Export PPTX: select a file name');
                if(fileName ~= 0)
                    fileName = fullfile(pathname,fileName);
                else
                    return
                end
            else
                fileName = p.Results.fileName;
            end
            isOpen  = exportToPPTX();
            if ~isempty(isOpen),
                % If PowerPoint already started, then close first and then open a new one
                exportToPPTX('close');
            end
            exportToPPTX('new',... %'Dimensions',[12 6], ...
                         'Title',p.Results.title, ...
                         'Author',p.Results.author, ...
                         'Subject',p.Results.subject, ...
                         'Comments',p.Results.comments);
            exportToPPTX('addslide');
            exportToPPTX('addtext',p.Results.title,...
                         'HorizontalAlignment','center',...
                         'VerticalAlignment','middle','FontSize',48);
%             summary = findobj(obj.tabs,'Title','Summary');
%             if(~isempty(summary))
%                 startTab = 2;
%             else
%                 startTab = 1;
%             end
            for tabNum = 1:length(obj.tabs)
                ht = obj.tabs(tabNum);
%                 hp = findobj(ht.Children,'tag','plot');
                exportToPPTX('addslide');
                exportToPPTX('addtext',ht.Title,...
                             'HorizontalAlignment','center',...
                             'VerticalAlignment','middle','FontSize',48);
                panels = [ht.UserData.Children.UserData];
                panels = [panels.hp];
                for panelNum = 1:length(panels)
                    [h hp] = obj.exportToFigure(panels(panelNum),'Visible','off');
                    hp.BackgroundColor = 'w';
                    exportToPPTX('addslide');
                    exportToPPTX('addpicture',h,'Scaled','maxfixed');
                    close(h);
                end
            end
            exportToPPTX('save',fileName);
            exportToPPTX('close');
        end
        function h = get.gct(obj)
        % gct Get Current Tab
        %  Returns the handle to the current tab
        h = obj.tabGroup.SelectedTab;
        end
        function h = get.gcp(obj)
        % gcp Get Current Panel
        %  Returns the handle to the current tab
            if(~isempty(obj.gct.UserData.SelectedObject))
                h = obj.gct.UserData.SelectedObject.UserData.hp;
            else
                h = [];
            end
        end
        function t = get.tabs(obj)
            t = obj.tabGroup.Children;
        end
    end
    methods (Access = private)
        function figResize(obj,src,~) % callbackdata is unused 3rd arg.
        % figResize Resizes the gui elements in each tab whenever the 
        %  figure is resized. 
            figSize = obj.figureSize;
            
            % Set minimum figure size
%             if(figSize(3)<560)
%                 figSize(3) = 560;
%             end
%             if(figSize(4)<420)
%                 figSize(4) = 420;
%             end
%             obj.figureSize = figSize;
            
            % Find selected tab and plot
%             currTab = obj.tabGroup.SelectedTab;
            if(~isempty(obj.gct.UserData.SelectedObject))
                numPlots = length(obj.gct.UserData.Children);
            else
                numPlots = 0;
            end
            
            % Plot list adjustment
            if(numPlots==1)
                plotListAdj = [-160 0 150 0];
            else
                plotListAdj = [0 0 0 0];
            end

            %Resize Current "Axes"
            if(strcmp(get(obj.gcp,'tag'),'ctrl')) % Resize ctrl panels
                set(obj.gcp,'Units','pixels','Position',[170 10  figSize(3)-185 figSize(4)-45]...
                                                   ...%- [0 0 ceil(leg_pos(3)) 0]... % Legend Adjustment
                                                   + plotListAdj); % Plot list adjustment
            else % Resize Axes
            set(obj.gcp,'Units','pixels','Position',[170 10  figSize(3)-185 figSize(4)-45]...
                                                   ...%- [0 0 ceil(leg_pos(3)) 0]... % Legend Adjustment
                                                   + plotListAdj); % Plot list adjustment
            end
            % Resize the plot list
            plots = obj.gct.UserData.Children;
            for n = 1:length(plots)
                set(plots(n),'Position',[10 figSize(4)-85-30*(n-1) 120 20]);
            end

            % Resize each list of plots
            plotLists = findobj(src,'tag','plotList','-and',...
                                'Type','uibuttongroup');
            set(plotLists,'Units','pixels','Position',[10 10  150 figSize(4)-45])
%             % Resize each axis
%             axesList = findobj(src,'Type','axes');
%             if(~isempty(axesList))
%                 l = legend;
%                 if(~isempty(l))
%                     l.Units = 'pixels';
%                     leg_pos = l.Position;
%                     set(axesList,'Units','pixels','Position',[210 50  figSize(3)-240 figSize(4)-110] - [0 0 ceil(leg_pos(3)) 0],'ActivePositionProperty','OuterPosition');
%                 else
%                     % TO DO: Add support for single plot tabs
%                     set(axesList,'Units','pixels','Position',[210 50  figSize(3)-240 figSize(4)-110],'ActivePositionProperty','OuterPosition');
%                 end
%             end
%             % Reposition plot buttons
%             for i_tab = 1:length(obj.tabs)
% %                 plots = findobj(obj.tabs(i_tab),'tag','plot','-and',...
% %                                 'Style','togglebutton');
%                 plots = get(get(obj.tabs(i_tab),'UserData'),'Children');
%                 for n = 1:length(plots)
%                     set(plots(n),'Position',[10 figSize(4)-85-30*(n-1) 120 20]);
%                 end
%             end
            
        end
        function selectPlot(obj,src,~) % ~ is callbackdata          
        % selectPlot Runs whenever a plot is selected from the plot list
            if(length(src.Children) > 1)
                h_panels = [src.Children.UserData];
                h_panels = [h_panels.hp];
                set(h_panels,'visible','off')
                
                src.SelectedObject.UserData.hp.Visible = 'on';
                src.Visible = 'on';
                if(~isempty(findobj(src.SelectedObject.UserData.hp.Children,'Type','axes')))
                    axes(findobj(src.SelectedObject.UserData.hp.Children,'Type','axes'));
                end
            end
            obj.figResize(obj.fig);
        end
        function selectTab(obj,b,c)
            obj.figResize(obj.fig);
            if(~isempty(obj.gcp) && ...
               ~isempty(findobj(obj.gcp.Children,'Type','axes')))
                axes(findobj(obj.gcp.Children,'Type','axes'));
            end
        end
        function tab_out = parseTab(obj,tab)
        % parseTab - parses a tab input, creating a new tab if the tab
        %  input is a tab name that doesn't exist.
            if(ischar(tab))
                tab_obj = findobj(obj.tabs,'Type','tab');
                if(isempty(tab_obj))
                    tab_out = obj.addTab(tab);
                else
                    tab_out = tab_obj;
                end
            else
                tab_out = tab;
            end
        end
        function exportMenu(obj,menu,~)
        % Export menu
            if(strcmp(menu.Label,'Export PPT'))
                obj.savePPT();
            end
        end    
        function renameDlg(~,menu,~) % ~ is obj, ActionData
        % renameDlg Diaglog box for renaming plots and tabs from a context
        %  menu
            type = get(menu.Parent.UserData,'Type');
            if(strcmpi(type,'uicontrol'))
                prevName = {menu.Parent.UserData.String};
                % Get new name from the user
                newName = inputdlg('New Name:','Rename',1,prevName);
                if(~isempty(newName))
                    menu.Parent.UserData.String = newName{1};
                end
            elseif(any(strcmpi(type, {'uitab','uibuttongroup'})))
                prevName = {menu.Parent.UserData.Title};
                % Get new name from the user
                newName = inputdlg('New Name:','Rename',1,prevName);
                if(~isempty(newName))
                    menu.Parent.UserData.Title = newName{1};
                end
            else
                error('tfigure:renameDlg:unknownSelectionType',...
                      'unknown selection type, need to add ui type to be renamed to the callback function');
            end
        end
        function deleteDlg(~,menu,~)
        % deleteDlg function for deleting tabs and plots.  Double checks
        % with the user if a plot already exists.
        %  menu
%         h = warndlg(['The tab "'
%             h_dlg = warndlg({'The following tab will be deleted:'; menu.Parent.UserData.Title}, 'Delete Tab Warning','modal');
%             choice = questdlg({'The following tab will be deleted:'; menu.Parent.UserData.Title},'Delete Warning','OK','cancel','cancel')
%             switch choice
%                 case 'OK'
            delete(menu.Parent.UserData);
%             end
            
%             x =0;
%             if(isvalid(h_dlg))
%                 delete(menu.Parent.UserData);
%             end
%             type = get(menu.Parent.UserData,'Type');
%             if(strcmpi(type,'uicontrol'))
%                 
%             else
%                 
%             end
        end
    end
end

