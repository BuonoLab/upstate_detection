function [ data, frecuency, title ] = loadspike2file( filename, unit)
%LOADSPIKE2SAMPLE Summary of this function goes here
%  Detailed explanation goes here


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


if(~exist('unit', 'var'))
    unit = 'mV';
end

fid = fopen(filename);

fgetl(fid); % information line
title = fgetl(fid); 
title = title(2:end-1);

datastarts = [];
tline = fgetl(fid);
linen = 3;

ffound = 0;
while (~ffound && (isempty(tline) ||  tline(1) ~= -1)) % eof
    if findstr(tline, unit)
        [s e] = regexp(tline, '\S+');
        frecuency = str2num(tline(s(6):e(6)));
        ffound = 1;
    end
    tline = fgetl(fid);
    linen = linen + 1;
end


while (isempty(tline) ||  tline(1) ~= -1) % eof
    if findstr(tline, 'START')
        datastarts(end+1) = linen;
    end
    tline = fgetl(fid);
    linen = linen + 1;
end
datastarts(end+1) = linen; % eof

data = {};
fseek(fid,0,'bof');
advancefile(fid,datastarts(1)+1);
for(i=1:length(datastarts)-1)
    l = datastarts(i+1)-datastarts(i)-8;
    d = fscanf(fid,'%g',[l, 1]);
    data{i} = d';
    advancefile(fid,8);
end


fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = advancefile(fid, nlines)

for(i=1:nlines)
    fgetl(fid);
end