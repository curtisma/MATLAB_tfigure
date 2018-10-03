function h = tFigExample
%%tFigExample An example showing how to use tfigure.  
% It makes a single tfigure with 2 tabs and several plots per tab.
%
% Author: Curtis Mayberry
% Curtisma3@gmail.com
% Curtisma.org
%
% see also: tfigure, tfigure.tfigure
close all;

%% Start a new tfigure
% Creates a new tfigure and defines the first tab's plots
h = tfigure;

%% The first tab will contain a single plot
h.addTab
h.addPlot('Normal');
y = -10:0.5:10;
x = -10:0.5:10;
[X, Y] = meshgrid(x, y);
Z = sin(sqrt(X.^2+Y.^2)) ./ sqrt(X.^2+Y.^2); % Create the function values for Z = f(X,Y)
surfc(X, Y, Z);
view(-38, 18) % Adjust the view angle
title('Normal Response');
xlabel('x');
ylabel('y');
zlabel('z');

%% Create the second "Exponential" tab 
% It will contain a single plot and utilize a function handle to plot
h_tab = h.addTab;
h_tab.Title = 'Exponential';
h.addPlot('Linear FH','tab',h.gct);
plot(1:20,exp(1:20));

%% Create the Third "Random" tab
% It will contain 2 plots.  The first plot will be created using the
% plotting routine plotExample.
h.addTab('Random Tab');
h.addPlot('Random','plotFcn',@plotExample,'title','Random'); % The plotExample plotting routine is defined below.

h.addPlot('Heart');
x=(-2:.001:2); y=real((sqrt(cos(x)).*cos(200*x)+sqrt(abs(x))-0.7).*(4-x.*x).^0.01); plot(x,y);
title('Love');
xlabel('time (yrs)');
ylabel('Feeling');

h.addPlot('Wolf','tab',h.gct);
spy;
 
% Add a Label
h.addLabel('Tables');

ht = h.addTable('Table');
ht.ColumnName = {'X-Data', 'Y-Data', 'Z-Data'};
ht.Data = rand(3);

%% Add a Control tab as the first tab 
tab1 = h.addTab('Control','order',1);
dataSel = dataSelectionCtrl;
h.addCtrl('Data Selection',@dataSel.ctrl,'tab',tab1);
h.addCtrl('Scripts',@(x) ctrlExample(tab1,x),'tab',tab1);


%% Create the fifth tab
% Tests subplots and addButton
h.addTab('Test Subplot');
h.addPlot('subplot 2x1');
subplot(2,1,1);
plot(1:5);
subplot(2,1,2);
plot(2:6);

h.addPlot('subplot 2x2');
subplotExample;
h.addButton('Hello World','callback',@(~,~,~) disp('Hello World'));

%% Create a tfigure with the tabs on the left instead of the top
h(2) = tfigure('','TabPosition','left');
h(2).addTab;
h(2).addPlot('testSingle');
% % h(2).addGroup;
% h(2).addPlot('group1_plot1','group','group1');
% h(2).addGroup('Group2');
% h(2).addPlot('group2_plot1','group','group2');
% h(2).addPlot('group2_plot2','group','group2');
% h(2).addPlot('group1_plot2','group','group1');

%% Create a tfigure using uifigure instead of figure
% Supports a different set of functions
h(3) = tfigure('','TabPosition','left');

%% Plotting functions
% Plotting routines called when a graph with its function handle is
% selected
% Using a plotting function allows the plot to include formatting functions
% such as titles and labels.
function plotExample()
% plotExample Plots a series of 10 random numbers.  Also includes a
%  title and labels the x and y axis.
    plot(1:10,rand(1,10));
    title('Random Plot');
    xlabel('Arbitrary Index');
    ylabel('Random Number');
end
function subplotExample
% subplotExample An example of a subplot from the MATLAB Plot Gallery
% Download on the File Exchange:
% http://www.mathworks.com/matlabcentral/fileexchange/35298-matlab-plot-gallery-subplot--2-/content/html/Subplot_2.html

    % Create the data to be plotted
    TBdata = [1990 4889 16.4; 1991 5273 17.4; 1992 5382 17.4; 1993 5173 16.5;
              1994 4860 15.4; 1995 4675 14.7; 1996 4313 13.5; 1997 4059 12.5;
              1998 3855 11.7; 1999 3608 10.8; 2000 3297  9.7; 2001 3332  9.6;
              2002 3169  9.0; 2003 3227  9.0; 2004 2989  8.2; 2005 2903  7.9;
              2006 2779  7.4; 2007 2725  7.2];

    measles = [38556 24472 14556 18060 19549 8122 28541 7880 3283 4135 7953 1884]';
    mumps = [20178 23536 34561 37395 36072 32237 18597 9408 6005 6268 8963 13882]';
    chickenPox = [37140 32169 37533 39103 33244 23269 16737 5411 3435 6052 12825 23332]';
    years = TBdata(:, 1);
    cases = TBdata(:, 2);
    rate  = TBdata(:, 3);

    % Create the pie chart in position 1 of a 2x2 grid
    subplot(2, 2, 1)
    pie([sum(measles) sum(mumps) sum(chickenPox)], {'Measles', 'Mumps', 'Chicken Pox'})
    title('Childhood Diseases')

    % Create the bar chart in position 2 of a 2x2 grid
    subplot(2, 2, 2)
    bar(1:12, [measles/1000 mumps/1000 chickenPox/1000], 0.5, 'stack')
    xlabel('Month')
    ylabel('Cases (in thousands)')
    title('Childhood Diseases')
    axis([0 13 0 100])
    set(gca, 'XTick', 1:12)

    % Create the stem chart in position 3 of a 2x2 grid
    subplot(2, 2, 3)
    stem(years, cases)
    xlabel('Years')
    ylabel('Cases')
    title('Tuberculosis Cases')
    axis([1988 2009 0 6000])

    % Create the line plot in position 4 of a 2x2 grid
    subplot(2, 2, 4)
    plot(years, rate)
    xlabel('Years')
    ylabel('Infection Rate')
    title('Tuberculosis Cases')
    axis([1988 2009 5 20])
end
%% Control functions
function ctrlExample(tab,h_panel,varargin)
%% ctrlExample 
% Makes a panel where inputs and options can be selected.
% 
% Simple expample of an input control panel.
%
% See also: uicontrol, tfigure, tFigExample
    panSize = h_panel.Position;
    
    % Add Path text box
    ch = uicontrol('Parent',h_panel,...
                  'Style', 'edit',...
                  'String',pwd,'Units','normalized',...
                  'Position', [0.05 0.8 0.65 0.1],...
                  'tag','ctrl');
    % Add file selection button
    bh = uicontrol('Parent',h_panel,...
                  'Style', 'pushbutton',...
                  'String','DATA','Units','normalized',...
                  'Position',[0.75 0.8 0.2 0.1],...[230 figSize(4)-85 40 20],...
                  'tag','ctrl',...
                  'Callback',@(x,y) uigetfile('.csv','Choose a data file',ch.String));
end
end