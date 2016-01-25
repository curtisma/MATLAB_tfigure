function h = tFigExample
%tFigExample An example showing how to use tfigure.  
% It makes a single tfigure with 2 tabs and several plots per tab.
%
% Author: Curtis Mayberry
% Curtisma3@gmail.com
% Curtisma.org
%
% see also: tfigure
close all;

%% Start a new tfigure
% Creates a new tfigure and defines the first tab's plots
h = tfigure;

%% The first tab will contain a single plot
h.addPlot(h.tabs,[],'title','Linear');
plot(1:10,1:10);
title('Linear Test Plot');
xlabel('index');
ylabel('Linear Plot');

%% Create the second tab 
% It will contain a single plot and utilize a function handle to plot
h.addTab('Exponential');
h.addPlot(h.tabs(2),@() plot(1:20,exp(1:20)),'title','Linear FH');

%% Create the Third tab
% It will contain 2 plots.  The first plot will be created using the
% plotting routine plotExample.
h.addTab('Random Tab');
h.addPlot(h.tabs(3),@plotExample,'title','Random'); % The plotExample plotting routine is defined below.
h.addPlot(h.tabs(3));
plot(1:10,rand(1,10));

%% Create the Fourth tab
% The Fourth tab will have the title Test Tab and contain 3 plots.
h.addTab('Test Tab');
h.addPlot(h.tabs(4),@() plot(1:5,1:5));
h.addPlot(h.tabs(4),@() plot(1:20,1:20),'title','Linear 10');
h.addPlot(h.tabs(4),@() plot(1:10,rand(1,10)),'title','Random');

%% Add a Control tab as the first tab 
% The summary tab is still a work in progress and currently just creates a
% blank tab
tab1 = h.addTab('ctrl','order',1);
h.addCtrl(tab1,@(x) ctrlExample(tab1));

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
%% Control functions
function ctrlExample(tab,varargin)
% ctrlExample makes a panel where inputs and options can be selected.
    figSize = tab.Parent.Parent.Position;
    ch = uicontrol('parent',tab,...
                  'Style', 'edit',...
                  'String',pwd,'Units','pixels',...
                  'Position', [100 figSize(4)-85 200 20],...
                  'tag','ctrl');
    bh = uicontrol('parent',tab,...
                  'Style', 'pushbutton',...
                  'String','Select Data','Units','pixels',...
                  'Position', [320 figSize(4)-85 40 20],...
                  'tag','ctrl');
end
end