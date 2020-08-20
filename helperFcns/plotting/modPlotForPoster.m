function modPlotForPoster(ratioBool)
if ratioBool==1
        xl = xlim;
        plot([xl(1) xl(2)],[1 1],'k--','LineWidth',2,'HandleVisibility','off')
end
        
ax = gca;
ax.FontSize = 16;
ax.FontWeight = 'bold';
ax.LineWidth = 2;
ax.TickDir = 'out';
set(ax,'color','none')
box off