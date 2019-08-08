function [] = spike2mat( filename, unit )
% Convert a Spike2 txt export file to a mat file in order to use plotMaudsFromMat straight and speed up the signal process.

% filename: name of the export txt file from Spike2 that contains the recorded signal
% unit: unit of the channels exported 

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


if(exist('unit', 'var'))
    [datacells f title] = loadspike2file(filename, unit);
else
    [datacells f title] = loadspike2file(filename);
end


data = datacells{1};
save([filename '_intra.mat'], 'data', 'f');

data = datacells{2};
save([filename '_extra.mat'], 'data', 'f');


