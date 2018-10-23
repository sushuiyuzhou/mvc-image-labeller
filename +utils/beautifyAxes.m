function beautifyAxes(ax)
try
    ax.XTick = [];
    ax.YTick = [];
    colormap(ax,'gray');
    ax.XAxis.Visible = 'off';
    ax.YAxis.Visible = 'off';
    ax.Color = ax.BackgroundColor;
catch
end
end