function [data, dw, dd, hmfast, hmslow] = maudsStatesFest(data,f,fest,startsec,endsec)


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



%slowwindowsize = max(ceil(f/10),round((-5* fest + 17)/2 * f)); %250000; 
slowwindowsize = max(ceil(f/10),round((8 - (2/fest)) * f)); %250000; 

fastwindowsize = ceil(slowwindowsize/60); %2500;        % window size of the fast moving average


minStateLength = 0.04; % seconds

timebackslopeD2U = 30; %ms
slopesegD2U = 5; % mV/s

timebackslopeU2D = 10; %ms
slopesegU2D = 100; % mV/s

slopeU2D = slopesegU2D/1000;
slopeD2U = slopesegD2U/1000;
samplesbackslopeU2D = round(timebackslopeU2D * f/1000);
samplesbackslopeD2U = round(timebackslopeD2U * f/1000);

if(~exist('startsec', 'var'))
    startsample = 1;
else
    startsample = f * startsec + 1;
end

if(~exist('endsec', 'var'))
    endsample = length(data);
else
    endsample = f * endsec + 1;
end

data = data(startsample:endsample);
lastsample = length(data);

%period = 1/f;

% EMA vars
n = fastwindowsize;% * 4;
rofast = n/(n+1);
coefast = (1-rofast);

n = slowwindowsize;% * 4;
roslow = n/(n+1);
coefslow = (1-roslow);

lastsignDataSEMA=1;
lastsignEMAs=1;
cdw=1;

% The first second is to adjust the start mean values
startvalue = mean(data(1:f));
hmslow(1:lastsample) = startvalue;
hmfast(1:lastsample) = startvalue;

mslow = startvalue;
mfast = startvalue;
dw = [];
dd = [];
%tic
for(i= (f+1):lastsample)
    input = data(i);
    
    mfast = rofast*mfast+coefast*input;
    mslow = roslow*mslow+coefslow*input;
    
    hmfast(i)=mfast;
    hmslow(i)=mslow;
    
    % Data and slow EMA cut
    sign = input>mslow;
    if(lastsignDataSEMA ~= sign)
        lastsignDataSEMA = sign;
    end
        
    % EMAs cut
    sign = mfast>mslow;
    if(lastsignEMAs ~= sign)
        c = i;
        
        if(sign) % down -> up
            if(c > samplesbackslopeD2U)
                slope = calcslope(data, c, samplesbackslopeD2U, timebackslopeD2U);
                
                if(slope > slopeD2U) % looking backward                
                    while(c-1 > samplesbackslopeD2U &&  slope > slopeD2U)
                        c = c - 1;
                        slope = calcslope(data, c, samplesbackslopeD2U, timebackslopeD2U);
                    end
                else % looking forward
                    while(c < lastsample && slope < slopeD2U)
                        c = c + 1;
                        slope = calcslope(data, c, samplesbackslopeD2U, timebackslopeD2U);
                    end
                end
            end
        else % up 2 down
            if(c > samplesbackslopeU2D)
                slope = calcslope(data, c, samplesbackslopeU2D, timebackslopeU2D);
                
                if(slope < slopeU2D) % looking backward                
                    while(c-1 > samplesbackslopeU2D &&  slope < slopeU2D)
                        c = c - 1;
                        slope = calcslope(data, c, samplesbackslopeU2D, timebackslopeU2D);
                    end
                else % looking forward
                    while(c < lastsample && slope > slopeU2D)
                        c = c + 1;
                        slope = calcslope(data, c, samplesbackslopeU2D, timebackslopeU2D);
                    end
                end
                c = c-samplesbackslopeU2D;
            end
        end
        
            
        
        dw(ceil(cdw/2),sign+1) = c;
        dd(ceil(cdw/2),sign+1) = max(i,c);
        cdw = cdw + 1;
        lastsignEMAs = sign;
    end
end


% short states filtering:

dw = filterShortStates(dw, minStateLength, f);

%toc


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [slope] = calcslope(data, c, samplesbackslope, timebackslope)

slope = abs((data(c)-data(c-samplesbackslope)) / timebackslope);

