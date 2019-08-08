function h = scrollplot_default(x, dx)
set(gcf, 'doublebuffer', 'on');
set(gca, 'xlim', [0 dx]);
pos = get(gca, 'position');
Newpos = [pos(1) pos(2)-0.1 pos(3) 0.05];
xmax = max(x);
S = ['set(gca,''xlim'',get(gcbo,''value'')+[0 ' num2str(dx) '])'];
h = uicontrol('style', 'slider', ...
    'units', 'normalized', 'position', Newpos,...
    'callback', S, 'min', 0, 'max', xmax-dx);
end