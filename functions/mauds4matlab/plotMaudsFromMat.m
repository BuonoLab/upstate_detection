function [data, f, dw] = plotMaudsFromMat(filename, fest, showemas, startsec, endsec, offsetsec, boxed, potentialoffset)
% Process and plot a data vector from a mat file with Mauds algorithm

% filename: file that contains the data vector to process and the sampling frequency of data
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

s = load(filename);

[data, f, dw] = plotMaudsFromData(s.data, s.f, fest, showemas, startsec, endsec, offsetsec, boxed, potentialoffset);


