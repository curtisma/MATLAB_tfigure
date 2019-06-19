classdef tfigure_legacy < handle % < matlab.mixin.SetGet
    %% TFIGURE 
    % A figure for holding tabbed groups of plots.
    % Creates a tabbed plot figure.  This allows the user to setup tabs
    % to group plots.  Each tab contains a list of plots that can be
    % selected using buttons on the left of the figure.
    %    
    % Example
    %  h = tfigure;
    %  h = tfigure('Tab_title');
    %
    % tfigure Properties:
    %  fig - Handle to the figure that displays tfigure.
    %  tabs - Handles to each of the tfigure's tabs
    %  figureSize - Current size of the figure containing tfigure
    %  gct - get current tab.  Set gct to select the current tab.
    %   gct can be set using the tab number, title, or object
    %  gcp - get current panel Set gcp to select the current panel.
    %   gcp can be set using the panel number, title, or object
    %
    % tfigure Methods:
    %  tfigure - Constructs a new tabbed figure
    %  addTab - Adds a new tab
    %  addPlot - Adds a new plot to the given tab
    %  addTable - Adds a table to the plot list
    %  addLabel - Adds a label to the plot list
    %  addCtrl - Adds a control panel to the plot list
    %  addPanel - Adds a panel to the plot list
    %  savePPT - Saves all plots to a Power Point presentation.
    %  exportToFigure - Copies a panel to a seperate figure
    %  exportToClipboard - Exports a picture of the panel to the clipboard
    %
    % Examples:
    %  tFigExample - tfigure example
    %
    % SETUP:
    %  Files that can be downloaded from the MATLAB file exchange
    %  exportToPPTX - Required to export to a pptx presentation
    %   <https://www.mathworks.com/matlabcentral/fileexchange/40277-exporttopptx>
    %
    % See issues in Github:
    % <https://github.com/curtisma/MATLAB_tfigure/issues>
    %    
    % Author: Curtis Mayberry
    % Curtisma3@gmail.com
    % Curtisma.org
    %
    % See Also: tFigExample, tfigure.tfigure
    
    %% *Properties*
    % Class properties
    properties
        fig % Handle to the figure that displays tfigure.
%         tabs % Handles to each of the tfigure's tabs
        menu % Tfigure menu
        addTabEnable
        buttonSize = 20;
        buttonSpacing = 10;
    end
    properties (Dependent)
        tabs % Handles to each of the tfigure's tabs
        figureSize % Current size of the figure containing tfigure
        gct % Get Current Tab.  You can also set this property to select a new current tab.
        gcp % Get Current Panel
    end
    properties (Access = private)
        tabGroup
    end
    %% 
    events
        tabSelectionChanged
%         plotListSelectionChanged
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
        %  h = tfigure;
        %   Creates a tfigure object without any tabs
        %  h2 = tfigure('Data Tab #1',...);
        %   Creates a tfigure object with a tab titled "Data Tab #1"
        %   Tab Parameter-Value pairs can be included for the first tab.
        %
        % INPUTS
        %  title_tab1 - (optional) The title of the first tab to be added.
        % PARAMETERS
        %  TabLocation - The location of the tabs 
        %   Options: 'top' (default),'left','bottom','right'
        %  AddTabEnable - Includes the '+' button in the button group to
        %   add a new tab.  [logical] (default: true)
        %  menuOptions - A structure that specifies the options for menus
        %   Fields:
        %    * File - Adds the file menu to the menu bar [logical]
        %    * Export - Adds the export menu to the menu bar [logical]
        % FIGURE PARAMETERS
        %  FigName - Figure name, specified as a character vector. 
        %   By default, the figure name is 'Figure n', where n is an integer. 
        %   When you specify the FigName property, the figure title becomes 
        %   'Figure n: name'. If you want only the FigName value to appear, 
        %   set FigNumberTitle to 'off'.
        %  FigNumberTitle - Figure window title number, specified as
        %   'on' or 'off'. The FigNumberTitle property determines whether 
        %   MATLAB includes the label Figure n in the title bar, where n is
        %   the figure Number property value.
        %  FigType - Base figure type, specified as 'figure' (default) or
        %   'uifigure'
        %  Position - Sets the position of the figure. See the definition
        %  of the 'Position' property of a figure
        % OUTPUTS
        %  h - a tfigure object
        % 
        % see also: tFigExample
            p = inputParser;
            p.KeepUnmatched = true;
            p.addOptional('TabName','',@ischar);
            p.addParameter('TabLocation','top',@(x) any(validatestring(x,{'top','left','bottom','right'})));
            p.addParameter('AddTabEnable',true,@islogical);
            p.addParameter('FigName','',@ischar);
            p.addParameter('FigNumberTitle','on',@(x) any(validatestring(x,{'on','off'})));
            p.addParameter('FigType','figure',@(x) any(validatestring(x,{'figure','uifigure'})));
            p.addParameter('Position',[],@(x) validateattributes(x,{'numeric'},{'numel',4,'vector'}));
            p.addParameter('buttonSize',obj.buttonSize,@(x) validateattributes(x,{'numeric'},{'scalar'}));
            p.addParameter('menuOptions',[])
            p.parse(varargin{:});
            obj.buttonSize = p.Results.buttonSize;
            
            if(strcmp(p.Results.FigType,'figure') && isempty(p.Results.Position))
                obj.fig = figure('Visible','off',...
                                 ... % 'SizeChangedFcn',@obj.figResize,...
                                 'Interruptible','off','Name',p.Results.FigName,...
                                 'NumberTitle',p.Results.FigNumberTitle); 
            elseif(strcmp(p.Results.FigType,'figure'))
                obj.fig = figure('Visible','off',...
                                 ... % 'SizeChangedFcn',@obj.figResize,...
                                 'Position',p.Results.Position,...
                                 'Interruptible','off','Name',p.Results.FigName,...
                                 'NumberTitle',p.Results.FigNumberTitle); 
            elseif(strcmp(p.Results.FigType,'uifigure'))
                obj.fig = uifigure('Visible','off',...
                                 ... % 'SizeChangedFcn',@obj.figResize,...
                                 'Interruptible','off','Name',p.Results.FigName,...
                                 'NumberTitle',p.Results.FigNumberTitle); 
            end
            obj.fig.UserData = obj;
            obj.tabGroup = uitabgroup('Parent', obj.fig,'SelectionChangedFcn',@obj.tabSelectionChangedCB,'TabLocation',p.Results.TabLocation);
            if(nargin>0 && ~isempty(varargin{1}))
                obj.addTab(varargin{:});
            end
%             obj.menu = uimenu(obj.fig,'Label','Tfigure');
            if(~isempty(p.Results.menuOptions) && ...
            isfield(p.Results.menuOptions,'File') && ...
            p.Results.menuOptions.File == true)
                obj.menu = uimenu(obj.fig,'Label','File');
            end
            if(isempty(p.Results.menuOptions) || ...
                isfield(p.Results.menuOptions,'Export')&& p.Results.menuOptions.Export == true)
                obj.menu(end+1) = uimenu(obj.fig,'Label','Export');
                uimenu(obj.menu(end),'Label','Export PPT','Callback',@obj.exportMenuCB)
                uimenu(obj.menu(end),'Label','Copy Panel to Clipboard','Callback',@obj.exportToClipboard);
            end
            % Add '+' addTab button
            if(p.Results.AddTabEnable)
                uitab('Parent', obj.tabGroup,'Title','+',...
                      'ButtonDownFcn',@obj.addTab,'TooltipString','Add Tab');
            end
            obj.addTabEnable = p.Results.AddTabEnable;
            obj.fig.Visible = 'on';
        end
        function h = addTab(obj,varargin)
        %% addTab
        % Adds a new tab with the given title.
        %
        %  ht = h.addTab([title],'Param','ParamValue',...);
        %
        % INPUTS
        %  title - (optional) name of the tab
        % PARAMETERS
        %  order - Specifies the tab position after which the tab is placed
        %  listName - The plot list title listed at the top
        %   Defaults to 'Plots'
        % OUTPUTS
        %  ht - uitab handle of the added tab
        %
        % See also: tfigure, tfigure.tfigure, tfigure.addPlot,
        % tfigure.addTable
            if(~isempty(varargin) && (isa(varargin{1},'matlab.ui.container.Menu') || isa(varargin{1},'matlab.ui.container.Tab')))
            % Menu Call or '+' Tab call
            % When called from the menu there is automatically 2
            % inputs, the menu and the eventData
                p.Results.titleIn = ['dataset ' num2str(length(obj.tabs)+1)];
                p.Results.order = [];
                p.Results.listName = 'Plots';
                p.Results.listType = 'buttons';
            else
            % User Call
                p = inputParser;
                addOptional(p,'titleIn',...
                        ['dataset ' num2str(length(obj.tabs)+1)],@isstr);
                p.addParameter('order',[], ...
                             @(x) isnumeric(x) && (x >= 1) && ... 
                             (x <= (length(obj.tabs)+1)))
                p.addParameter('listName','Plots', @ischar)
                p.addParameter('listType','buttons', @(x) any(validatestring(x,{'buttons','tree'})))
                p.KeepUnmatched = true;
                parse(p,varargin{:});
            end
            order = p.Results.order;
            
            % Setup tab
            h = uitab('Parent', obj.tabGroup,...
                      'Title', p.Results.titleIn,'ButtonDownFcn',@obj.selectTab);
            
            % Setup tab order
            if(isempty(order) && length(obj.tabGroup.Children)>1)
                obj.tabGroup.Children = obj.tabGroup.Children([1:end-2 end end-1]);
            elseif(~isempty(order))
                if(order <= 1)
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
            uimenu(c,'Label','Add Label','Callback',@obj.addLabel);
            uimenu(c,'Label','Rename','Callback',@obj.renameDlg,'Separator','on');
            uimenu(c,'Label','Delete','Callback',@obj.deleteDlg,'UserData',h);
            
            % Setup tab layout
            hs.layout = uix.HBoxFlex('Parent',h,'Spacing',5,'Padding',5);
            
            % Setup plot list
            if(strcmp(p.Results.listType,'buttons'))
                hs.plotList = uibuttongroup('parent',hs.layout,...
                                ...%'Position',[10 10  150 figSize(4)-45],...
                                'tag','plotList',...
                                'SelectionChangedFcn',@obj.selectPlot,...
                                'SizeChangedFcn',@obj.resizePlotList);
            elseif(strcmp(p.Results.listType,'tree'))
                hs.plotList = uitree('parent',hs.layout,...
                                'tag','plotList');
            end
            set(hs.plotList,'Title',p.Results.listName);
            % Menu: Plot list context
            hs.plotList.UIContextMenu = uicontextmenu;
            hs.plotList.UIContextMenu.UserData = hs.plotList;
            uimenu(hs.plotList.UIContextMenu,'Label','Add Plot','Callback',@obj.addPlot);
            uimenu(hs.plotList.UIContextMenu,'Label','Add Table','Callback',@obj.addTable);
            uimenu(hs.plotList.UIContextMenu,'Label','Add Label','Callback',@obj.addLabel);
            uimenu(hs.plotList.UIContextMenu,'Label','Rename','Callback',@obj.renameDlg,'Separator','on');

            % Setup Card Panel
            hs.CardPanel = uix.CardPanel('Parent',hs.layout);
            
            % Shrink plot list
            set(hs.layout,'Widths',[0, -1]);

            h.UserData = hs;
            % Make the new tab current
            obj.tabGroup.SelectedTab = h;
        end
        function varargout = addPanel(obj,varargin)
        %% addPanel 
        % Adds a panel to a tab.  
        %  When the panel button is selected, the panel is selected
        %
        % h = obj.addPanel([title],'tab',[h_tab],'plotFcn',[function_handle])
        %
        % INPUTS
        %  title - (optional) Uses this string as the panel title displayed 
        %   in the plot list
        % PARAMETERS
        %  tab - Selects which tab will contain the panel.  The tab can be
        %   specified as a uitab handle or the name of the tab
        %  order - Specifies the plot list position after which the panel is 
        %   placed
        % OUTPUTS
        %  h - Handle to the panel's control button (optional)
        %  hp - Handle to the panel (optional)
        % EXAMPLE
        %  h = tfigure;
        %  h = h.addPanel('Panel Title');
        % 
        % see also: tfigure, tfigure.tfigure, tfigure.addTab,
        % tfigure.addPlot, tfigure.addTable
            if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
                p=inputParser;
                p.KeepUnmatched = true;
                p.addOptional('title','panel',@ischar)
                p.addParameter('tab',obj.tabGroup.SelectedTab,@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)));
                p.addParameter('order',[],@isnumeric);
%                 p.addParameter('group',[],@ischar);
                p.parse(varargin{:})
            else
                p.Results.tab = obj.tabGroup.SelectedTab;
                p.Results.plotFcn = [];
                p.Results.title = 'panel';
                p.Results.order = [];
            end
            
            
            % Select the Tab
            tab = obj.parseTab(p.Results.tab);
            if(strcmp(tab.Title,'+') && isempty(tab.UserData))
            error('tfigure:addPanel:addTab','Need to add a tab first before adding any panels to it. Call obj.addTab first.');
            end
            
            % Add the new panel to the plot list
            hs = get(tab,'UserData'); % The tab's UserData contains a handle to the uibuttongroup for the tab
            plotList = hs.plotList;
            h = uicontrol('parent',plotList,...
                          'Style', 'togglebutton',...
                          'String', p.Results.title,'Units','pixels',...
                          ...'Position',pos,...
                          'tag','panel');
            if(length(plotList.Children) == 2 && (plotList.Position(3) == 1))
                set(plotList.Parent,'Widths',[150, -1]);
            end
            
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
            h.UserData.hp = uipanel('Parent',hs.CardPanel,'Units','pixels',...
                                    'Tag',p.Results.title,'BorderType','none');
            h.UserData.hp.UserData.hc = h;
            h.UserData.hp.UserData.h = obj;
            h.UserData.hp.UserData.cardNum = length(hs.CardPanel.Children);
            
            % Setup order using the order or panelGroup parameters          
            
            order = p.Results.order;
%             if(isempty(order) && ~isempty(p.Results.group))
%                 groupLabel = findobj(obj.gct.UserData.plotList,'Style','text','String',p.Results.group);
%                 groupLabel.UserData(end+1) = h;
%             end
            plotList.Children = tfigure.childReorder(plotList.Children,order);
            obj.resizePlotList(plotList,[]);
            
            % Setup outputs
            switch nargout
                case 0
                    varargout = {};
                case 1
                    varargout = {h};
                case 2
                    varargout = {h h.UserData.hp};
                otherwise
                    error('tfigure:addPanel:numOutputs','Unsupported number of outputs for tfigure.addPanel');
            end
        end
        function varargout = addPlot(obj,varargin)
        %% addPlot 
        % Adds a plot to the given tab.  
        %  When the plot button is selected the plot is selected
        %
        % ha = h.addPlot([title],'tab',[h_tab],'plotFcn',[function_handle])
        %
        % INPUTS
        %  title - (optional) Uses this string as the plot title displayed 
        %   in the plot list
        % PARAMETERS
        %  tab - Selects which tab will contain the table.  The tab can be
        %   specified as a uitab handle or the name of the tab
        %  plotFcn - A function handle to be evaluated when the plot is
        %   selected.
        %  order - Specifies the plot list position after which the plot is 
        %   placed
        % OUTPUTS
        %  ha - Handle to the plot axis
        % EXAMPLE
        %  h = tfigure;
        %  ha = h.addPlot('Plot Title');
        % 
        % see also: tfigure, tfigure.tfigure, tfigure.addTab,
        % tfigure.addTable
            if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
                p=inputParser;
                p.KeepUnmatched = true;
                p.addOptional('title','plot',@ischar)
                p.addParameter('plotFcn',[],@(x) (isa(x,'function_handle') || isempty(x)));
                p.addParameter('legendTable',[], @(x) isempty(x) || istable(x) || iscell(x) || x);
                p.parse(varargin{:});
                if(nargin <= 2)
                	h = obj.addPanel(p.Results.title);
                elseif(nargin>2)
                    h = obj.addPanel(p.Results.title,varargin{2:end});
                end
            else
                % Menu selection
                p.Results.plotFcn = [];
                p.Results.legendTable = [];
                h = obj.addPanel('plot');
            end
            h.Tag = 'plot';
            
            % Setup Axes and Legend Table (if applicable)
            if(~isempty(p.Results.legendTable))
                hb = uix.HBoxFlex(h,'Spacing',5,'Padding',5);
                ha = axes(hb);
                if(istable(p.Results.legendTable))
                    data = table2cell(p.Results.legendTable);
                else
                    data = p.Results.legendTable;
                end
%                 colNames = 
                uitable('Parent',hb,...
                       'Units','normalized','Position',[0 0 1 1],...
                       'Tag','legend table','Data',data,...
                       'ColumnName',colNames);
            else
                ha = axes(h.UserData.hp);%,...'Units','pixels',...
%                              'ActivePositionProperty','OuterPosition');
            end
            
            ha.Visible = 'on';
            
            % Setup Plot Function
            if(~isempty(p.Results.plotFcn))
                h.UserData.fh = p.Results.plotFcn;
                p.Results.plotFcn();
            else
                h.UserData.fh = [];
            end
            h.Parent.SelectedObject = h;
            obj.selectPlot(h.Parent,[]);
            switch nargout
                case {0, 1}
                    varargout = {ha};
                case 2
                    varargout = {ha h};
            end
        end
        function varargout = addTable(obj,varargin)
        %% addTable
        % Adds a table to the given tab.
        %
        % ht = h.addTable([title],'Param','ParamValue',...)
        %
        % INPUTS
        %  title - (optional) The table title to displayed on the selection
        %   button
        % PARAMETERS
        %  tab - Selects which tab will contain the table.  The tab can be
        %   specified as a uitab handle or the name of the tab
        %  order - Specifies the plot list position after which the table is 
        %   placed
        %  style - Selects between the default MATLAB table and a Java
        %   table. uitable: 'uitable or 'ui'  Java Table: 'Java' or
        %   'JavaTable'
        % OUTPUTS
        %  ht - handle to the table
        %
        % See also: tfigure.addPlot tfigure.addLabel tfigure.addCtrl
            if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
                p=inputParser;
                p.KeepUnmatched = true;
                p.addOptional('title','table',@ischar)
                p.addParameter('style','uitable',...
                    @(x) any(validatestring(x,{'uitable','ui','JavaTable','Java'})))
                p.parse(varargin{:})
                if(nargin <= 2)
                	h = obj.addPanel(p.Results.title);
                elseif(nargin>2)
                    h = obj.addPanel(p.Results.title,varargin{2:end});
                end
            else
                p.Results.style = 'uitable';
                h = obj.addPanel('table');
            end
            h.Tag = 'table';
            
            % Setup Table
            if(strcmpi(p.Results.style,'uitable') || strcmpi(p.Results.style,'ui'))
                ht = uitable('Parent',h.UserData.hp,'Units','normalized','Position',[0 0 1 1]);%,'Units','pixels');
            elseif(strcmpi(p.Results.style,'JavaTable') || strcmpi(p.Results.style,'java'))
                if(~(exist('exportToPPTX','file')))
                    error('tfigure:NeedExportToPPTX',...
                         ['createTable must be added to the path. ',...
                        'It can be downloaded from the MATLAB file exchange, search for "Java-based data table"']);
                end
                ht = uiextras.jTable.Table('Parent',h.UserData.hp);
            end
            %             h.UserData.fa.Visible = 'on';   
            h.UserData.hp.UserData.hc = ht;
            
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
        %  hl = h.addLabel(title,...)
        %  
        % INPUTS
        %  title - text to display
        % PARAMETERS
        %  title - text to display
        %  order - Specifies the plot list position after which the label is 
        %   placed
        %  tab - Selects which tab will contain the table.  The tab can be 
        %   specified as a uitab handle or the name of the tab 
        % OUTPUTS
        %  hl - label handle
        %
        % see also: tfigure, tfigure.tfigure, tfigure.addTab,
        % tfigure.addTable
            if(~isempty(varargin) && ~isa(varargin{1},'matlab.ui.container.Menu'))
                p=inputParser;
                p.KeepUnmatched = true;
                p.addRequired('title',@ischar);
                p.addParameter('tab',obj.tabGroup.SelectedTab,@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)))
                p.addParameter('order',[],@isnumeric);
                p.parse(varargin{:})
            else
                p.Results.title = inputdlg('Label:','Label',1,{''});
                p.Results.tab = obj.tabGroup.SelectedTab;
                p.Results.order = [];
            end
            
            % Select the Tab
            tab = obj.parseTab(p.Results.tab);
            
            % Add the new label to the plot list
            plotList = get(tab,'UserData'); % The tab's UserData contains a handle to the uibuttongroup for the tab
            plotList = plotList.plotList;
            h = uicontrol('parent',plotList,...
                          'Style', 'text','FontSize',11,...
                          'String', p.Results.title,'Units','pixels',...
                          'tag','label');
            
            % Setup Context Menu
            c = uicontextmenu;
            c.UserData = h;
            h.UIContextMenu = c;
            uimenu(c,'Label','Rename','Callback',@obj.renameDlg);
            uimenu(c,'Label','Delete','Callback',@obj.deleteDlg);
            
            % Setup order
            plotList.Children = tfigure.childReorder(plotList.Children,p.Results.order);
            obj.resizePlotList(plotList,[]);
%             obj.selectPlot(plotList,[]);
        end
        function h = addCtrl(obj,title,fun_handle,varargin)
        %% addCtrl
        % Adds a control panel to a tab
        %  Requires a fun_handle which points to the control panel function
        %  which defines its contents
        %
        %  hp = h.addCtrl([title],[fun_handle(h_panel)],'Param','value') 
        % INPUTS
        %  title - (optional) text of the control's plot list button
        %  fun_handle - (optional) A function that defines the control panel.  It has 
        %   a single input that is a handle to the panel that will contain 
        %   the control panel.
        % PARAMETERS
        %  order - Specifies the plot list position after which the ctrl is 
        %   placed
        %  tab - Selects which tab will contain the table.  The tab can be 
        %   specified as a uitab handle or the name of the tab 
        % OUTPUTS
        %   hp - handle for the control panel's plot list button
        %
        % See also: tfigure, tfigure.tfigure
            p=inputParser;
            p.KeepUnmatched = true;
            p.addOptional('title','ctrl',@ischar)
            p.addOptional('fun_handle',[],@(x) isa(x,'function_handle'));
            p.parse(title,fun_handle,varargin{:});
            
            [h, hp] = obj.addPanel(title,varargin{:});
            h.Tag = 'ctrl';
            if(~isempty(p.Results.fun_handle))
                h.UserData.fh = p.Results.fun_handle;
                p.Results.fun_handle(hp);
            end
            h.Parent.SelectedObject = h;
            obj.selectPlot(h.Parent,[]);
        end
        function h = addButton(obj,varargin)
        %% addButton
        % Adds a button to the plot list which calls a callback when it is
        % pressed but does not change the panel.
        %
        %  ht = h.addButton([title],'Param','ParamValue',...);
        %
        % INPUTS
        %  title - (optional) Uses this string as the button title displayed 
        %   in the plot list
        % PARAMETERS
        %  callback - A callback function handle that is called when the
        %   button is pressed.  The callback must have 3 inputs 
        %   e.g. callback(obj,src,callbackdata)
        %  tab - Selects which tab will contain the panel.  The tab can be
        %   specified as a uitab handle or the name of the tab
        %  order - Specifies the plot list position after which the button is 
        %   placed
        % See Also: tfigure
            p=inputParser;
            p.KeepUnmatched = true;
            p.addOptional('title','Button',@ischar);
            p.addParameter('tab',obj.tabGroup.SelectedTab,@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)))
            p.addParameter('order',[],@isnumeric);
            p.addParameter('callback',function_handle.empty,@(x) isa(x,'function_handle'));
            p.addParameter('ToolTipString','',@ischar);
            p.parse(varargin{:})
            
            % Select the Tab
            tab = obj.parseTab(p.Results.tab);
            
            % Add the new label to the plot list
            plotList = get(tab,'UserData'); % The tab's UserData contains a handle to the uibuttongroup for the tab
            plotList = plotList.plotList;
            h = uicontrol('parent',plotList,...
                          'Style', 'togglebutton','FontSize',11,...
                          'String', p.Results.title,'Units','pixels',...
                          'tag','button','ToolTipString',p.Results.ToolTipString);
            if(~isempty(p.Results.callback))
                set(h,'Callback',p.Results.callback)
            end
            if(length(plotList.Children) == 2 && (plotList.Position(3) == 1))
                set(plotList.Parent,'Widths',[150, -1]);
            end
            % Setup order
            CurrentPanelSelection = h.Parent.SelectedObject;
            plotList.Children = tfigure.childReorder(plotList.Children,p.Results.order);
            obj.resizePlotList(plotList,[]);
            h.Parent.SelectedObject = CurrentPanelSelection; 
        end
%         function groups = getPanelGroups(obj)
%         % Get the groups of the current tab
%             groups = findobj(obj.gct.UserData.plotList,'Style','text','String',p.Results.group);
%         end
%         function h = addGroup(obj,varargin)
%         %addGroup A group consists of a title (label) and the panels grouped
%         % under that label.  The panel group's position is always defined
%         % relative to other groups by the position of the title (label)
%         %
%         % INPUTS
%         %  title - The title that will be the text of the label
%         %  panels - Optionally add panels to this panel group
%         %
%         % See also: tfigure
%             p = inputParser;
%             p.KeepUnmatched = true;
%             p.addOptional('title','Group1',@ischar)
%             p.addOptional('panels',[])
% %             p.addParameter('order',length(obj.gct.UserData.plotList.Children),@isnumeric);
%             p.parse(varargin{:});
% %             if(~any(strcmp(varargin,'order')))
% %                 varargin = [varargin 'order' p.Results.order];
% %             end
%             h = obj.addLabel(p.Results.title,varargin{:});
%             h.UserData = p.Results.panels;      
%         end
        %function export(obj,varargin)
        % export Exports an analysis panel, a tab, or an entire tfigure using
        % the specified format
        %
        % Not currently implemented
        %end
        function exportToClipboard(obj,varargin)
        %% exportToClipboard 
        % Exports a panel to the clipboard as if it it were in its own 
        % figure
        %
        % obj.exportToClipboard([panel])
        %
        % INPUTS
        %  panel - (optional) a panel handle to be exported
        %   Uses the current panel (obj.gcp) by default
        %
        % See also: tfigure, tfigure.tfigure
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
        %  hf = h.exportToFigure
        %  hf = exportToFigure(h)
        %   Copies current panel (h.gcp) to a new figure with handle hf
        %  hf = h.exportToFigure(panel)
        %   Copies panel (panel) to a new figure with handle hf
        %
        % INPUTS
        %  panel - (optional) a panel handle to be exported
        %   Uses the current panel (obj.gcp) by default
        % OUTPUTS
        %  hf - a handle to the newly created figure
        %
        % See also: tfigure, tfigure.tfigure
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
        % FILENAME
        %  fileName - file name of the file to save the plots
        % PARAMETERS:
        %  title - Title of the presentation
        %  subject - subject of presentation, included in file meta data
        %  comments - comments on the presentation
        %  author - Author's name
        %
        % See also: tfigure, tfigure.tfigure
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
            if ~isempty(isOpen)
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
                    [h, hp] = obj.exportToFigure(panels(panelNum),'Visible','off');
                    hp.BackgroundColor = 'w';
                    exportToPPTX('addslide');
                    exportToPPTX('addpicture',h,'Scaled','maxfixed');
                    close(h);
                end
            end
            exportToPPTX('save',fileName);
            exportToPPTX('close');
        end
        function out = get.figureSize(obj)
            out = get(obj.fig,'position');
        end
        function set.figureSize(obj,val)
            set(obj.fig,'position',val);
        end
        function h = get.gct(obj)
        % gct Get Current Tab
        %  Returns the handle to the current tab
        h = obj.tabGroup.SelectedTab;
        end
        function h = get.gcp(obj)
        % gcp Get Current Panel
        %  Returns the handle to the current panel
%         tabLayoutChildren = get(obj.gct.Children,'Children')
            if(~isempty(obj.gct.UserData.plotList.SelectedObject))
                h = obj.gct.UserData.plotList.SelectedObject.UserData.hp;
            else
                h = [];
            end
        end
        function set.gct(obj,value)
            if(ischar(value))
                value = strcmp({obj.tabGroup.Children.Title}, value);
                if(~isempty(value))
                    obj.tabGroup.SelectedTab = obj.tabGroup.Children(value);
                else
                	error('could not find %s panel',value)
                end
            elseif(isa(value,'matlab.ui.container.Tab') && any(value == obj.tabGroup.Children))
                obj.tabGroup.SelectedTab = value;
            elseif(isnumeric(value))
                obj.tabGroup.Selected = Tabobj.tabGroup.Children(value);
            else
                error('The current tab can be set to a tab object in this tabGroup, the Title (char) of a tab in this tab group, or the tab number');
            end
        end
        function set.gcp(obj,value)
            tabLayoutChildren = get(obj.tabGroup.SelectedTab.Children,'Children');
            tabPanels = get(tabLayoutChildren(1),'Children');
            tabPanels(get(tabLayoutChildren(1),'Selection'));
            if(ischar(value))
                tabLayoutChildren(2).Children.String
                obj.tabGroup.SelectedTab = obj.tabGroup.Children(strcmp({obj.tabGroup.Children.Title}, 'Design'));
                value = find(strcmp({tabLayoutChildren(2).Children.String},value));
                if(~isempty(value))
                    set(tabLayoutChildren(1),'Selection',value)
                else
                    error('could not find %s panel',value)
                end
            elseif(isa(value,'matlab.ui.container.Tab'))
                set(tabLayoutChildren(1),'Selection',value)
            else
                error('The current tab can be set to a tab object in this tabGroup or to the Title (char) of a tab in this tab group.');
            end
        end
        function t = get.tabs(obj)
            if(obj.addTabEnable)
                t = obj.tabGroup.Children(1:end-1);
            else
                t=get(get(obj,'tabGroup'),'Children');
%                 t = obj.tabGroup.Children;
            end
        end
%         function set.tabs(obj,in)
%             obj.tabs = [in obj.tabs(end)]
%         end
    end
    methods (Access = private)
        function resizePlotList(obj,src,~)
            if(~isempty(src.Children))
                for pNum = 1:length(src.Children)
                    pos = [5 src.Position(4)-(obj.buttonSize+5)*pNum-15 src.Position(3)-10 obj.buttonSize];
                    if(pos(3) <0)
                        pos(3) = 1;
                    end
                    if(strcmp(src.Children(pNum).Tag,'label'))
                        pos(2) = pos(2)-5;
                    end
                    src.Children(pNum).Position = pos;
                end
            end
        end
        function selectPlot(~,src,callbackdata) % ~ is callbackdata          
        % selectPlot Runs whenever a plot is selected from the plot list
            if(length(src.Children) > 1)
%                 h_panels = [src.Children.UserData];
%                 h_panels = [h_panels.hp];
                if(~strcmp(src.SelectedObject.Tag,'button'))
                    src.Parent.Parent.UserData.CardPanel.Selection = find(src.Parent.Parent.UserData.CardPanel.Contents == src.SelectedObject.UserData.hp);
                else
                    src.SelectedObject = callbackdata.OldValue;
                end
                if(~isempty(findobj(src.SelectedObject.UserData.hp.Children,'Type','axes')))
                    axes(findobj(src.SelectedObject.UserData.hp.Children,'Type','axes'));
                end
            else
                set(src.Parent,'Widths',[0, -1]);
            end
%             obj.figResize(obj.fig);
        end
        function selectTab(obj,~,~)
%             obj.figResize(obj.fig);
            % Set the current axes
            if(~isempty(obj.gcp) && ...
               ~isempty(findobj(obj.gcp.Children,'Type','axes')))
                axes(findobj(obj.gcp.Children,'Type','axes'));
            end
        end
        function tab_out = parseTab(obj,tab)
        % parseTab - parses a tab input, creating a new tab if the tab
        %  input is a tab name that doesn't exist.  Can accept a handle or
        %  a string input of the tab name.
            if(ischar(tab))
                tab_obj = findobj(obj.tabs,'Type','uitab','Title',tab);
                if(isempty(tab_obj))
                    tab_out = obj.addTab(tab);
                else
                    tab_out = tab_obj;
                end
            else
                tab_out = tab;
            end
        end
        function exportMenuCB(obj,menu,~)
        % Export menu callback
        %  Executes the requested depending on the selected export option
            if(strcmp(menu.Label,'Export PPT'))
                obj.savePPT();
            end
        end    
        function tabSelectionChangedCB(obj,~,~)
            notify(obj,'tabSelectionChanged');
        end
        function plotListSelectionChangedCB(obj,~,~)
            notify(obj,'plotListSelectionChanged');
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
        function deleteDlg(obj,menu,~)
        % deleteDlg function for deleting tabs and plots.  Double checks
        % with the user if a plot already exists.
        %  menu
%         h = warndlg(['The tab "'
%             h_dlg = warndlg({'The following tab will be deleted:'; menu.Parent.UserData.Title}, 'Delete Tab Warning','modal');
%             choice = questdlg({'The following tab will be deleted:'; menu.Parent.UserData.Title},'Delete Warning','OK','cancel','cancel')
%             switch choice
%                 case 'OK'
%             if(find(menu.UserData.Parent.Children == menu.UserData)  == length(menu.UserData.Parent.Children)-1)
%                 selectPrevTabFcn = menu.UserData.Parent.Children(end-2).ButtonDownFcn;
%             else
%                 selectPrevTabFcn = @(x)(1);
%             end
            % delete the panel and button
            deletedItemType = menu.Parent.UserData.Type; % uitab or uicontrol (button)
            if(strcmp(deletedItemType,'uicontrol'))
                delete(menu.Parent.UserData.UserData.hp)
            end
            delete(menu.Parent.UserData);

            if(strcmp(deletedItemType,'uitab') && ...
               length(obj.gct.Parent.Children)>1 && find(obj.gct == obj.gct.Parent.Children) == length(obj.gct.Parent.Children))
            	obj.gct.Parent.SelectedTab = obj.gct.Parent.Children(end-1);
            end


%             selectPrevTabFcn();
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
    methods (Access = private, Static = true)
        function children = childReorder(children,order)
        % childReorder reorders the children of tabs or plot lists
        %
        % INPUTS
        %  children - children of tabs or plot lists
        %  Order - sets the an integer between 1 and length(children)+1 that 
        %  specifies its index.  If order is empty, the first child is 
        %  moved to the last child
        %
        %
            if(isempty(order) || (order >= length(children)+1))
                children = children([2:end 1]);
            elseif((order > 1) && (order < length(children)))
                children = children([2:order 1 (order+1):end]);
            end
            
            % Reorder those panels that belong to a label group so that
            % all the panels of that label group are underneath the label
%             labels = findobj(obj.gct.UserData.plotList,'Style','text');
%             groups = labels(~(labels.UserData == []));
%             if(~isempty(groups))
%                 for groupN = 1:length(groups)
%                     panels = groups(groupN).UserData;
%                     for panelN = 1:length(panels)
%                         groupChildIdx = find(children == groups(groupN));
%                         panelChildIdx = find(children == groups(groupN));
%                         childrenIdx = 1:length(children);
%                         childrenIdx(panelChildIdx) = [];
%                         if(groupChildIdx == length(children))
%                             
%                             children = [children(childrenIdx) children(panelChildIdx)];
%                         else
%                             
% %                             childrenIdx = 
%                             children = [children(childrenIdx(1:groupChildIdx-1)) children(panelChildIdx) children(childrenIdx(groupChildIdx:end))];
% %                                 children = [children(childrenIdx(1:groupChildIdx)) children(panelChildIdx)];
% %                         elseif(groupChildIdx<panelChildIdx)
% %                             children = [children(childrenIdx(1:groupChildIdx-1)) children(panelChildIdx) children(childrenIdx(groupChildIdx:end))];
% % %                             children = [children(childrenIdx:) children(panelChildIdx)];
%                         end
% %                         
% %                         childrenIdx = 1:length(children);
% %                         childrenIdx(childrenIdx== panelChildIdx) = [];
% %                         childrenIdx = [1:groupChildIdx panelChildIdx groupChildIdx+1:length(childrenIdx)-1
%                     end
%                 end
%             end
            
        end
    end
end

