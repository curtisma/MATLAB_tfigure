%% *Package tfigure Toolbox*

%% Publish Documentation 
% Publish the tfigure toolbox documentation.
options = struct('evalCode',false);
publish('tfigure.m',options);
publish('tFigExample.m',options);

%% Package Toolbox
% Packages the toolbox into an installable file.
% execin(
% toolbox\matlab\toolbox_packaging\+matlab\+tbxpkg\+internal