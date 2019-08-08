function [p] = plotboxmaudsbw(sampledata, f, dw, dd, hmfast, hmslow, FSL,FSN,XL,YL,medias,detectiontime,labels,XTick,YTick, pureonline, startdata, enddata, axisx1, axisx2)
% Black and White Boxed version: up states are showed inside a grey box


% sampledata : sample data
% f          : sample frecuency
% FSL   :  font size for letters
% FSN   :  font size for numbers
% minMP :  lowest membrane potential
% maxMP :  highest membrane potential
% XL    :  do not print X label if variable exists
% YL    :  do not print Y label if variable exists
% medias:  do print moving averages
% labels:  1 = do not print X labels, 2 = print only extreme values, 3 = print all values / -X prints all values but starting with X
% XTick :  vector of numbers for X axis (e.g. [ 0 10 30])
% YTick :  vector of numbers for Y axis (e.g. [-100 -90 -80])


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


%p1 = 0.9;            % tanto por uno del minimo para determinar inicio del up state
%p2 = 0.5;            % tanto por uno del minimo para determinar final del up state

colorUp=[207 35 35]/255;
colorDown=[32 215 28]/255;


%Color
colorSignal =[0.2 0.2 0.2];
colorEmaSlow=[0 31 244]/255;
colorEmaFast=[244 6 0]/255;
colorBox=[0.91 0.91 0.91];

% B&W
colorSignal =[0.6 0.6 0.6];
colorEmaFast=[0 0 0];
colorEmaSlow=[0.2 0.2 0.2];
colorBox=[0.95 0.95 0.95];



boxbottom = min(sampledata);
boxhight = max(sampledata) - boxbottom;

if(~exist('startdata'))
    startdata = 0;
end

if(~exist('enddata'))
    enddata = length(sampledata)/f;
end

if(~exist('pureonline'))
    pureonline = 0;
end

t = linspace(startdata, enddata, length(sampledata));

newplot
hold on

if(pureonline)
    dw = dd;
end

h=plot(t(1:dw(1,1)),sampledata(1:dw(1,1)));
set(h,'Color', colorUp)
if(dw(1,1) ~= 1)
    rectangle('Position', [t(1) boxbottom t(dw(1,1))-t(1) boxhight], 'LineStyle', 'none', 'FaceColor', colorBox);
end
for i = 1:size(dw,1)-1
    rectangle('Position', [t(dw(i,2)) boxbottom t(dw(i+1,1))-t(dw(i,2)) boxhight], 'LineStyle', 'none', 'FaceColor', colorBox);
    %h=plot(t(dw(i,1):dw(i,2)),sampledata(dw(i,1):dw(i,2)),'c');   % down state
    %set(h,'Color',colorDown)
    %h=plot(t(dw(i,2):dw(i+1,1)),sampledata(dw(i,2):dw(i+1,1)));
    %set(h,'Color',colorUp)
end

% last piece
i = i + 1;
if(size(dw,1) >= i)
    if(dw(i,2) ~= 0)
        rectangle('Position', [t(dw(i,2)) boxbottom enddata-t(dw(i,2))+1 boxhight], 'LineStyle', 'none', 'FaceColor', colorBox);
        %h=plot(t(dw(i,1):dw(i,2)),sampledata(dw(i,1):dw(i,2)),'c');   % down state
        %set(h,'Color',colorDown)
        %h=plot(t(dw(i,2):end),sampledata(dw(i,2):end),'c');
        %set(h,'Color',colorUp)
    else
        %h=plot(t(dw(i,1):end),sampledata(dw(i,1):end),'c');   % down state
        %set(h,'Color',colorDown)
    end
end
p = h;

plot(t,sampledata, 'Color', colorSignal);

if (medias)
    h=plot(t,hmfast);
    set(h,'Color',colorEmaFast)
    h=plot(t,hmslow, '--');
    set(h,'Color',colorEmaSlow)
end


minMP = min(sampledata)-10;
maxMP = max(sampledata)+10;

if(~exist('axisx1'))
    axisx1 = 0;
end
if(~exist('axisx2'))
    axisx2 = t(end) + 1/f;
end

set(gca,'layer','top');

axis([axisx1 axisx2 minMP maxMP])
set(get(h,'Parent'),'FontSize',FSN)
set(get(h,'Parent'),'FontName','Times New Roman');
%set(get(h,'Parent'),'XTick',XTick)

set(gca, 'YTick', -100:40:100);

if (labels<=0)
    shft = XTick(1)+labels;
    labels=3;
else
    shft = 0;
end
switch (labels)
    case 1
        clear XTickLabel
        for i=1:length(XTick)
            XTickLabel{i}=' ';
        end
        set(get(h,'Parent'),'XTickLabel',XTickLabel)
    case 2
        clear XTickLabel
        XTickLabel{1}=num2str(XTick(1)-shft);
        for i=2:length(XTick)-1
            XTickLabel{i}=' ';
            i
        end
        XTickLabel{length(XTick)}=num2str(XTick(length(XTick))-shft);
        set(get(h,'Parent'),'XTickLabel',XTickLabel)
    case 3
        clear XTickLabel
        for i=1:length(XTick)
            XTickLabel{i}=num2str(XTick(i)-shft);
        end
        set(get(h,'Parent'),'XTickLabel',XTickLabel)
end
%set(get(h,'Parent'),'YTick',YTick)




%detection time marks
if (detectiontime)
    for i = 1:prod(size(dd)-1)
        px = dd(i)/f;
        py = sampledata(dd(i));
        plot([px px], [py-10 -1000], 'black');
    end
end

if (XL)
    h = xlabel('time (s)','FontSize',FSL);
    set(h,'FontName','Times New Roman');
    if (labels<3)
        set(h,'VerticalAlignment','bottom') % bottom baseline middle cap top
    else
        set(h,'VerticalAlignment','middle') % bottom baseline middle cap top
    end
end
if (YL)
    h = ylabel('membrane potential (mV)', 'FontSize',FSL);
    set(h,'FontName','Times New Roman');
end

hold off
