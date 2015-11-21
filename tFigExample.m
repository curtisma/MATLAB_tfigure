% 
%% tFigExample
% An example showing how to use tfigure.  It makes a single tfigure with 2
% tabs and several plots per tab.
%
% Author: Curtis Mayberry
% Curtisma3@gmail.com
% Curtisma.org
%
function h = tFigExample
close all;

%% Start a new tfigure
% Creates a new tfigure and defines the first tab's plots
h = tfigure;
h.addPlot(h.tabs,@() plot(1:10,1:10),'Linear');
h.addPlot(h.tabs,@plotExample,'Random'); % The plotExample plotting routine is defined below.

%% Create the second tab
% The second tab will have the title Test Tab and contain 3 plots.
h.addTab('Test Tab');
h.addPlot(h.tabs(2),@() plot(1:5,1:5));
h.addPlot(h.tabs(2),@() plot(1:20,1:20),'Linear 10');
h.addPlot(h.tabs(2),@() plot(1:10,rand(1,10)),'Random');

%% Add a Summary tab as the first tab 
% The summary tab is still a work in progress and currently just creates a
% blank tab
h.addSummary;

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
end