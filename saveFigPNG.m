function saveFigPNG(path,figHandles)

for i =1:length(figHandles)
    
    fig = figHandles(i);
    fname = fullfile(path,['fig',num2str(i),'.png']);
    
    fig.Color=[1,1,1];
    
    saveas(fig,fname,'png')
    
end