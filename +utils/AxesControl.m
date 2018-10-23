classdef AxesControl < handle
    properties(Access=private)
        ax
        lx
        ly
        image
        % label image stack
        childStack = {}
        % max/min ratio
        ratio = 1
        % handle to base image
        hb
        %
        minValue
        maxValue
        range
        %
        area
        %
        labels
    end
    
    methods(Access=public)
        function this = AxesControl(ax, n)
            this.ax = ax;
            colormap(this.ax,gray.^(n));
        end
        
        function changeColorMap(this,n)
            colormap(this.ax,gray.^(n));
        end
        
        function addBaseImage(this, image)
            this.image = image;
            this.lx = [0,size(this.image,1)];
            this.ly = [0,size(this.image,2)];
            this.ax.XLim = this.lx;
            this.ax.YLim = this.ly;
            % add base image
            hIm = imagesc(this.ax,'CData',this.image);
            this.childStack{end+1} = hIm;
            this.hb = hIm;
            % colormap(this.childStack{end},'gray'); => invalid
            this.calibrateRange();
        end
        
        function changeBaseImage(this, image)
            this.image = image;
            this.hb.CData = image;
            this.calibrateRange();
        end
        
        function calibrateRange(this)
            this.minValue = min(min(this.childStack{1}.CData));
            this.maxValue = max(max(this.childStack{1}.CData));
            this.range = this.maxValue - this.minValue;
        end
        
        function addImage(this)
            %h = imagesc(this.ax,'CData',[]);
            hold(this.ax,'on');
            h = plot(this.ax,0,0);
            h.Color = 'm';
            h.LineStyle = '-';
            h.LineWidth = 0.7;
            this.childStack{end+1} = h;
            %this.childStack{end}.AlphaData = 0.4;
            this.area = [];
            % label
            this.labels{end+1} = struct();
            this.labels{end}.cate = '不确定';
            this.labels{end}.color = 'm';
        end
        
        function renderLastImageWithSquare(this,startPos,endPos)
            h = this.childStack{end};
            x1 = startPos(1);
            y1 = startPos(2);
            x2 = endPos(1);
            y2 = endPos(2);
            %h.CData = double((this.maxValue + this.minValue)/2).*ones(abs(x2-x1),abs(y2-y1))';
            %h.XData = min(x1,x2);
            %h.YData = min(y1,y2);
            try
                h.XData = [x1,x2,x2,x1,x1];
                h.YData = [y1,y1,y2,y2,y1];
            catch
            end
            % label
            this.labels{end}.pos = [mean(h.XData),mean(h.YData)];
            this.labels{end}.x = h.XData;
            this.labels{end}.y = h.YData;
        end
        
        function renderLastImageWithArea(this,startPos,endPos)
            this.area = [this.area; endPos];
            tmp = [this.area; startPos];
            h = this.childStack{end};
            try
                h.XData = tmp(:,1);
                h.YData = tmp(:,2);
            catch
            end
            % label
            this.labels{end}.pos = [mean(h.XData),mean(h.YData)];
            this.labels{end}.x = h.XData;
            this.labels{end}.y = h.YData;
        end
        
        function clearAllLabels(this)
            for ind = 2:numel(this.childStack)
                try
                    this.childStack{ind}.XData = 0;
                    this.childStack{ind}.YData = 0;
                    this.childStack(ind) = [];
                    % label
                    this.labels(ind-1) = [];
                catch
                end
            end
        end
        
        function deleteLastLabelImage(this)
            if numel(this.childStack) > 1
                try
                    this.childStack{end}.XData = 0;
                    this.childStack{end}.YData = 0;
                catch
                end
                this.childStack(end) = [];
                %label
                this.labels(end) = [];
            end
        end
        
        function processBaseImage1(this)
            tmp = int16(this.image);
            M=stretchlim(tmp);
            J=imadjust(tmp,M,[]);
            this.hb.CData = mat2gray(J);
        end
        
        function processBaseImage2(this)
            tmp = int16(this.image);
            J=histeq(tmp);
            this.hb.CData = mat2gray(J);
        end
        
        function showOriginalImage(this)
            this.hb.CData = this.image;
        end
        
        function renderNewImage(this,image,labelData)
            % TODO : clean up.
            while numel(this.childStack) > 1
            this.clearAllLabels();
            end
            this.changeBaseImage(image);
            if ~isempty(labelData)
                % label
                this.labels = labelData;
                for ind = 1:numel(this.labels)
                    hold(this.ax,'on');
                    h = plot(this.ax,0,0);
                    h.LineStyle = '-';
                    h.LineWidth = 0.7;
                    this.childStack{end+1} = h;
                    try
                    this.childStack{end}.XData = this.labels{ind}.x;
                    this.childStack{end}.YData = this.labels{ind}.y;
                    catch
                    end
                    this.childStack{end}.Color = this.labels{ind}.color;
                end
            end
        end
        
        function changeLastLabelWithToColor(this, value)
            switch value
                %case 1
                    %this.childStack{end}.Color = 'y';
                    %this.labels{end}.cate = '无骨折';
                    %this.labels{end}.color = 'y';
                case 1
                    this.childStack{end}.Color = 'c';
                    this.labels{end}.cate = '不全骨折';
                    this.labels{end}.color = 'c';
                case 2
                    this.childStack{end}.Color = 'r';
                    this.labels{end}.cate = '完全骨折';
                    this.labels{end}.color = 'r';
                case 3
                    this.childStack{end}.Color = 'g';
                    this.labels{end}.cate = '陈旧骨折';
                    this.labels{end}.color = 'g';
                case 4
                    this.childStack{end}.Color = 'b';
                    this.labels{end}.cate = '病理性骨折';
                    this.labels{end}.color = 'b';
                case 5
                    this.childStack{end}.Color = 'm';
                    this.labels{end}.cate = '不确定';
                    this.labels{end}.color = 'm';
            end
        end
        
        function text = presentText(this)
            numLabel = numel(this.childStack)-1;
            text = sprintf(['当前图像有%d个标定区域\n'],numLabel);
            for ind = 1:numLabel
                text = [text, sprintf('第%d个标签:\n位置:[%d, %d]\n类别：%s\n',...
                    ind, ...
                    round(this.labels{ind}.pos(1)), round(this.labels{ind}.pos(2)),...
                    this.labels{ind}.cate)];
            end
        end
        
        function data = getLabels(this)
            numLabel = numel(this.childStack)-1;
            if numLabel > 0
                data = this.labels;
            else
                data = {};
            end
        end
    end
end