function [data, f, dw] = plotMaudsFromData(data, f, fest, showemas, startsec, endsec, offsetsec, boxed, potentialoffset)
% Process and plot a data vector with Mauds algorithm

% data: data vector to process (intra or extra cellular signal)
% f: sampling frequency of data
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
	showemas = 0;
end

if(~exist('boxed', 'var'))
	boxed = 1;
end

if(~exist('potentialoffset', 'var'))
    potentialoffset = 0;
end

f = round(f);

if(exist('endsec', 'var') && endsec > 0)
    [data, dw, dd, hmfast, hmslow] = maudsStatesFest(data, f, fest, startsec, endsec);
elseif (exist('startsec', 'var'))
    [data, dw, dd, hmfast, hmslow] = maudsStatesFest(data, f, fest, startsec);
else
    [data, dw, dd, hmfast, hmslow] = maudsStatesFest(data,f, fest);
end

data = data + potentialoffset;
hmfast = hmfast + potentialoffset;
hmslow = hmslow + potentialoffset;

if(boxed)    
    plotboxmauds(data, f, dw, dd, hmfast, hmslow, 10, 7, 10, 10, showemas, 0, 1, 1, 1);
else
    plotmauds(data, f, dw, dd, hmfast, hmslow, 15, 12, 10, 10, showemas, 0, 1, 1, 1);
end

if(exist('offsetsec', 'var') && offsetsec > 0)
    a = axis;
    if(endsec > 0)
        axis([offsetsec endsec-startsec a(3:4)]);
    else
        axis([offsetsec a(2:4)]);
    end
end
