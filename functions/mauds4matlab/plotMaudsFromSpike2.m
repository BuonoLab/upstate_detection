function [data, f, dw] = plotMaudsFromSpike2(filename, nchannel, fest, showemas, startsec, endsec, offsetsec, boxed, potentialoffset)
% Process and plot a data vector from a spike2 export txt file with Mauds algorithm

% filename: name of the export txt file from Spike2 that contains the recorded signal
% nchannel: num channel in the export file to process 
% fest: estimated frequency of the signal (a parameter of mauds algorithm)
% showemas: include the emas in the plot
% startsec: start second to process
% endsec: end second to process (0 = end)
% offsetsec: start second to plot
% boxed: plot characterization with boxes (1) or changing signal color (0)
% potentialoffset: potential offset to aply to data vector

%    Copyright (C) 2007 Daniel Lobo - Universidad de Malaga (dlobo@geb.uma.es)

%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.



if(~exist('nchannel', 'var'))
	nchannel = 1;
end

if(~exist('fest', 'var'))
	fest = 1;
end

if(~exist('showemas', 'var'))
	showemas = 1;
end

if(~exist('startsec', 'var'))
	startsec = 0;
end

if(~exist('endsec', 'var'))
	endsec = 0;
end

if(~exist('offsetsec', 'var'))
	offsetsec = 0;
end

if(~exist('boxed', 'var'))
	boxed = 1;
end

if(~exist('potentialoffset', 'var'))
    potentialoffset = 0;
end

if(~exist('unit', 'var'))
    unit = 'mV';
end


[datacells f title] = loadSpike2File(filename, unit);

[data, f, dw] = plotMaudsFromData(datacells{nchannel}, f, fest, showemas, startsec, endsec, offsetsec, boxed, potentialoffset);


