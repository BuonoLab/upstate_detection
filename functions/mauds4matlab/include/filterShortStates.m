function [states] = filterShortStates(states, minStateLength, f)
% minStateLength in seconds
% f in frames/second


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


minNumFrames = minStateLength * f; % frames

i=1;
while(i <= size(states, 1))
    while(i <= size(states, 1) && states(i,2) ~= 0 && states(i,2)-states(i,1) < minNumFrames)
        states(i,:) = [];
    end
    
    if(i < size(states, 1) && states(i+1,1)-states(i,2) < minNumFrames)
        if(i == size(states, 1))
            states(i-1,2) = states(i,2);
            states(i,:) = [];
        else
            states(i+1:end-1,1) = states(i+2:end,1);
            states(i:end-1,2) = states(i+1:end,2);
            states(end,:) = [];
        end
    else
        i = i + 1;
    end
end