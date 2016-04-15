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
    % * Export Menu
    %  * ppt, pictures, figures, copy image to clipboard
    %  * Add support for using a ppt template
    % * Control View
    %   * Ability to add a button to the plot list to select a control
    %    panel view in that tab.
    % * Plot List
    %    * Be able to add text Labels to group plots
    %    * Be able to move plots up or down using mouse or a keyboard
    %    shortcut
    %    * Function to add a "Add Plot" button to the plot list GUI
    % * Plot Context Menu
    %    * uicontextmenu
    %    * delete plot
    %    * Reorder plot
    % * Tab Bar
    %    * "Add Tab" tab with a "+" label to create a new tab
    % * Tab Context Menu
    %    * change tab name using inputdlg function
    %    * delete tab
    %    * Reorder tab
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
        tabs % Handles to each of the tfigure's tabs
        menu % Tfigure menu
    end
    properties (Dependent)
        figureSize % Current size of the figure containing tfigure
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
                obj.tabs(end+1) = h;
            else
                obj.tabs((order+1):end+1) = obj.tabs(order:end);
                obj.tabs(order) = h;
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
        function h = addPlot(obj,varargin)
        %% addPlot([tab],'title',[title],'plotFcn',[function_handle]) 
        % Adds a plot to the given tab.  
        %  When the button is selected the plotting routine given by
        %  plotFcn is ran.
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
            
            % Add the new plot to the plot list
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
            
            % Setup Axes
            h.UserData.fa = axes('Parent',tab,'Units','pixels',...
...%                              'position',axesSize,...
                             'ActivePositionProperty','OuterPosition');
            h.UserData.fa.Visible = 'on';
            
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
            
            % Setup Table
            h.UserData.fa = uitable('Parent',tab,'Units','pixels');
            h.UserData.fa.Visible = 'on';   
            
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
                varargout = {h.UserData.fa};
            elseif(nargout == 2)
                varargout = {h.UserData.fa h};
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
            h.UserData.fa = h_panel;
            
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
        function savePPT(obj,varargin)
        %% savePPT 
        % Saves all the plots in tfigure to a powerpoint presentation.  
        % 
        % h.savePPT
        %
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
                fileName = fullfile(pathname,fileName);
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
            numTabs = length(obj.tabs);
            summary = findobj(obj.tabs,'Title','Summary');
            if(~isempty(summary))
                startTab = 2;
            else
                startTab = 1;
            end
            for tabNum = startTab:numTabs
                ht = get(obj.tabs(tabNum));
                hp = findobj(ht.Children,'tag','plot');
                exportToPPTX('addslide');
                exportToPPTX('addtext',ht.Title,...
                             'HorizontalAlignment','center',...
                             'VerticalAlignment','middle','FontSize',48);
                for plotNum = 1:length(hp)
                    if(isa(hp(plotNum).UserData,'function_handle'))
                    h = figure('Position',obj.fig.Position,...
                               'Color',[1 1 1],'Visible','off');
                    hp(plotNum).UserData();
                    else
                        h = hp(plotNum).UserData.fa.Parent.Parent.Parent
%                         h = h.fa;
                    end
                    exportToPPTX('addslide');
                    exportToPPTX('addpicture',h,'Scaled','maxfixed');
                    if(isa(hp(plotNum).UserData,'function_handle'))
                        close(h);
                    end
                end
            end
            exportToPPTX('save',fileName);
            exportToPPTX('close');
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
            currTab = obj.tabGroup.SelectedTab;
            if(~isempty(currTab.UserData.SelectedObject))
                currPlot = currTab.UserData.SelectedObject;
                currAxes = currPlot.UserData.fa;
                numPlots = length(currTab.UserData.Children);
            else
                %currPlot = [];
                currAxes = [];
                numPlots = 0;
            end
            
            % Resize current axes
            leg_pos = [0 0 0 0];
            if(~isempty(currAxes) && strcmp(currAxes.Type,'axes'))
                % Legend Adjustment
                l = legend;
                if(~isempty(l))
                    l.Units = 'pixels';
                    leg_pos = l.Position;
                    set(currAxes,'ActivePositionProperty','OuterPosition');
                end
            end
            % Plot list adjustment
            if(numPlots==1)
                plotListAdj = [-160 0 150 0];
            else
                plotListAdj = [0 0 0 0];
            end

            %Resize Current "Axes"
            if(strcmp(get(currAxes,'tag'),'ctrl')) % Resize ctrl panels
                set(currAxes,'Units','pixels','Position',[180 10  figSize(3)-195 figSize(4)-45]...
                                                   - [0 0 ceil(leg_pos(3)) 0]... % Legend Adjustment
                                                   + plotListAdj); % Plot list adjustment
            else % Resize Axes
            set(currAxes,'Units','pixels','Position',[210 50  figSize(3)-240 figSize(4)-110]...
                                                   - [0 0 ceil(leg_pos(3)) 0]... % Legend Adjustment
                                                   + plotListAdj); % Plot list adjustment
            end
            % Resize the plot list
            plots = currTab.UserData.Children;
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
        function selectPlot(obj,src,~) % ~ is obj and callbackdata          
        % selectPlot Runs whenever a plot is selected from the plot list
            if(length(src.Children) > 1)
                visible_plot = findobj(src.Parent.Children,'Visible','on');
                for i = 1:length(visible_plot)
                    visible_plot(i).Visible = 'off';
                end
                src.SelectedObject.UserData.fa.Visible = 'on';
                % Turn on plotted material 
                material = src.SelectedObject.UserData.fa.Children;
                if(~isempty(material))
                    for i = 1:length(material)
                        material(i).Visible = 'on';
                    end
                end
                set(src.Children,'Visible','on');
                src.Visible = 'on';
%                 for i = 1:length(src.Children)
%                       src.Children.
%                     src.Children(i).UserData.fa.Visible = 'off';
%                 end
            else
%                 axesSize = [50 50 obj.figureSize(3)-90 obj.figureSize(4)-110];
%                 src.SelectedObject.UserData.fa.Position = axesSize;
            end
%             if isa(src.SelectedObject.UserData, 'function_handle')
%                 axes(findobj(src.Parent,'Type','Axes'));
%                 src.SelectedObject.UserData(); % contains the plot function handle
%             elseif(isa(src.SelectedObject.UserData,'matlab.graphics.axis.Axes'))
%                 % Turn off current axes
%                 h_current = axes(findobj(src.Parent,'Type','Axes','-and',...
%                                          'Visible','on'));
%                 h_current.Visible = 'off';
%                 h_current.children.Visible = 'off';
%                 % Turn on new axes
% %                 h_new = 
%             end
            obj.figResize(obj.fig);
        end
        function selectTab(obj,~,~)
            obj.figResize(obj.fig);
        end
        function tab_out = parseTab(obj,tab)
        % parseTab - parses a tab input, creating a new tab if the tab
        %  input is a tab name that doesn't exist.
            if(ischar(tab))
                tab_obj = findobj(tab,'Type','tab');
                if(isempty(tab_obj))
                    obj.addTab(tab)
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
                menu.Parent.UserData.String = newName{1};
            elseif(strcmpi(type, 'uitab'))
                prevName = {menu.Parent.UserData.Title};
                % Get new name from the user
                newName = inputdlg('New Name:','Rename',1,prevName);
                menu.Parent.UserData.Title = newName{1};
            elseif(strcmpi(type, 'uibuttongroup'))
                prevName = {menu.Parent.UserData.Title};
                % Get new name from the user
                newName = inputdlg('New Name:','Rename',1,prevName);
                menu.Parent.UserData.Title = newName{1};
            else
                error('tfigure:renameDlg:unknownSelectionType',...
                      'unknown selection type, need to add ui type to be renamed to the callback function');
            end
        end
        function deleteDlg(~,menu,~)
        % deleteDlg function for deleting tabs and plots.  Double checks
        % with the user if a plot already exists.
        %  menu
%         delete();
%             type = get(menu.Parent.UserData,'Type');
%             if(strcmpi(type,'uicontrol'))
%                 
%             else
%                 
%             end
        end
    end
end

