classdef ImageLabeller < handle
    properties(Access = private)
        % env data
        dataDir = fullfile(pwd,'data');
        toolsDir = fullfile(pwd,'utils');
        % data file
        patientID
        % image data
        data
        imageID
        imageData
        % UI elements
        uFigure
        uAx
        uOpts
        uInfo
        uFdBk
        uSlider
        lastImageBtn
        nextImageBtn
        reverseBtn
        saveBtn
        grayUpBtn
        grayDownBtn
        origBtn
        zoomBtn
        captureBoxBtn
        captureAreaBtn
        increaseGrayBtn
        decreaseGrayBtn
    end
    
    properties(Access=private)
        textFbCtrl
        textInfoCtrl
        axesCtrl
        %
        startPos
        endPos
        %
        origImage
        maskImage
        % dynamic data loader
        dataStore
        % gray scale
        gScale = 3.6
    end
    
    methods(Access = public)
        function this = ImageLabeller(patientDataFile)
            % no warning message
            warning('off');

            this.initData(patientDataFile);
            %  runtime label store
            this.dataStore = cell(size(this.data.data,3),1);
            this.loadPreExistingData();
            % init UI elements
            this.initFigureUIElements();
            % register all callbacks
            this.registerCallbacks();
        end
    end
    
    % utils for data management
    methods(Access = private)
        function initData(this, patientDataFile)
            % init toolboxes
            addpath(genpath(fullfile(pwd,'3p')));
            % init data
            this.data = utils.loadImageSequenceFromFile(patientDataFile);
            [~,this.patientID,~] = fileparts(patientDataFile);
            try
                mkdir(fullfile(pwd,'label',this.patientID));
            catch
            end
        end
    end
    
    methods(Access = private)
        function initFigureUIElements(this)
            % create UI elements
            this.uFigure = figure;
            this.uFigure.MenuBar = 'none';
            this.uFigure.Name = '骨折病变标注';
            this.uFigure.NumberTitle = 'off';
            this.uFigure.Resize = 'off';
            % axes
            this.uAx = axes(this.uFigure);
            this.uAx.Units = 'pixels';
            this.uAx.XAxis.Visible = 'off';
            this.uAx.YAxis.Visible = 'off';
            this.uAx.Color = this.uFigure.Color;
            % options box
            this.uOpts = uicontrol(this.uFigure,'Style','listbox','string',...
                {'不全骨折(1)',...
                '完全骨折(2)','陈旧骨折(3)','病理性骨折(4)','不确定(5)'});
            this.uOpts.Units = 'pixels';
            this.uOpts.FontSize = 11;
            % image slider
            this.uSlider = uicontrol(this.uFigure,'Style','slider');
            % instruction panel
            this.uInfo = uicontrol(this.uFigure,'Style','text');
            this.uInfo.Units = 'pixels';
            % feedback panel
            this.uFdBk = uicontrol(this.uFigure,'Style','text');
            this.uFdBk.Units = 'pixels';
            this.uFdBk.FontSize = 11;
            % init slider value
            this.uSlider.Min = 1;
            this.uSlider.Max = size(this.data.data,3);
            % first image
            this.imageID = 1;
            this.imageData = flip(mat2gray(this.data.data(:,:,1)'),2);
            % add content to feedback panel
            this.textFbCtrl = utils.TextAreaControl(this.uFdBk);
            this.textFbCtrl.changeText('初始化完毕。请使用鼠标/键盘标定病变。');
            % add content to info panel
            this.textInfoCtrl = utils.TextAreaControl(this.uInfo);
            this.textInfoCtrl.changeText('标定信息总结');
            % orig image
            this.axesCtrl = utils.AxesControl(this.uAx, this.gScale);
            this.axesCtrl.addBaseImage(this.imageData);
            this.renderByImageID();
            % add last image button
            this.lastImageBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '上一张(P)');
            this.nextImageBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '下一张(N)');
            this.reverseBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '取消(C)');
            this.saveBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '保存(S)');
            this.grayUpBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '增强(J)');
            this.grayDownBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '尖锐(K)');
            this.origBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '原图(O)');
            this.zoomBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '细部查看(Z)');
            this.captureBoxBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '标定Box(B)');
            this.captureAreaBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '标定区域(A)');
            this.increaseGrayBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '灰度大(T)');
            this.decreaseGrayBtn = uicontrol(this.uFigure,...
                'Style', 'pushbutton', 'String', '灰度小(R)');
            % positions
            screenSize = get(0,'ScreenSize');
            posF = utils.LayoutManager(screenSize(3), screenSize(4));
            % this.uFigure.Position = posF.getPos(1/8, 1/10, 3/4, 4/5);
            % or full screen
            this.uFigure.Position = posF.getPos(0, 0, 1, 1);
            posUI = utils.LayoutManager(this.uFigure.Position(3), this.uFigure.Position(4));
            % ax
            this.uAx.Position = posUI.getPos(9/40,6/30,22/40,22/30);
            %this.uSlider.Position = posUI.getPos(9/40,4/30,22/40,2/30);
            this.uSlider.Position = posUI.getPos(31/40,6/30,1/40,22/30);
            % text left
            this.uInfo.Position = posUI.getPos(2/40,2/30,6/40,22/30);
            this.uFdBk.Position = posUI.getPos(2/40,25/30,6/40,3/30);
            % btn - below ax
            this.lastImageBtn.Position = posUI.getPos(9/40,2/30,4/40,2/30);
            this.nextImageBtn.Position = posUI.getPos(13/40,2/30,4/40,2/30);
            this.grayUpBtn.Position = posUI.getPos(19/40,2/30,4/40,2/30);
            this.grayDownBtn.Position = posUI.getPos(23/40,2/30,4/40,2/30);
            this.origBtn.Position = posUI.getPos(27/40,2/30,4/40,2/30);
            % btn - right
            this.uOpts.Position = posUI.getPos(33/40,23.5/30,6/40,4.5/30);
            this.reverseBtn.Position = posUI.getPos(33/40,21/30,4/40,2/30);
            this.saveBtn.Position = posUI.getPos(33/40,19/30,4/40,2/30);
            this.increaseGrayBtn.Position = posUI.getPos(33/40,16/30,4/40,2/30);
            this.decreaseGrayBtn.Position = posUI.getPos(33/40,14/30,4/40,2/30);
            this.captureBoxBtn.Position = posUI.getPos(33/40,10/30,4/40,2/30);
            this.captureAreaBtn.Position = posUI.getPos(33/40,8/30,4/40,2/30);
            this.zoomBtn.Position = posUI.getPos(33/40,5/30,4/40,2/30);
        end
        
        function registerCallbacks(this)
            % user slider to decide which image to present
            addlistener(this.uSlider, 'Value', 'PostSet', @this.slider_Callback);
            addlistener(this.uOpts, 'Value', 'PostSet', @this.opts_Callback);
            this.reverseBtn.Callback = @this.deleteLastLabel;
            this.lastImageBtn.Callback = @this.selectLastImage;
            this.nextImageBtn.Callback = @this.selectNextImage;
            this.zoomBtn.Callback = @this.showSeparateImage;
            % keyboard input
            this.uFigure.WindowKeyPressFcn = @this.captureKeyPress;
            % capture mode
            this.captureBoxBtn.Callback = @this.changeModeToBox;
            this.captureAreaBtn.Callback = @this.changeModeToArea;
            % image processing
            this.grayUpBtn.Callback =  @this.processBaseImage1;
            this.grayDownBtn.Callback =  @this.processBaseImage2;
            this.origBtn.Callback = @this.showOriginalImage;
            % default - bounding box
            set(this.uFigure, 'WindowButtonDownFcn', @(~,~)this.startDragBoxFcn);
            set(this.uFigure, 'WindowButtonUpFcn', @(~,~)this.stopDragBoxFcn);
            % data management
            this.saveBtn.Callback = @this.saveCurrentImageLabels;
            % gray scale
            this.increaseGrayBtn.Callback = @this.increaseGrayScale;
            this.decreaseGrayBtn.Callback = @this.decreaseGrayScale;
        end
    end
    
    methods(Access = private)
        function slider_Callback(this, ~, ~)
            % change image
            this.imageID = round(this.uSlider.Value);
            this.renderByImageID();
            % feedback
            this.uFdBk.String = sprintf('图像切换至第%d张', this.imageID);
            this.textInfoCtrl.changeText(this.axesCtrl.presentText());
        end
        
        function opts_Callback(this, ~, ~)
            tmp = this.uOpts.String{this.uOpts.Value};
            this.uFdBk.String = sprintf('病变识别变化：%s', tmp);
            this.axesCtrl.changeLastLabelWithToColor(this.uOpts.Value);
            this.textInfoCtrl.changeText(this.axesCtrl.presentText());
        end
        
        function changeModeToBox(this,~,~)
            set(this.uFigure, 'WindowButtonDownFcn', @(~,~)this.startDragBoxFcn);
            set(this.uFigure, 'WindowButtonUpFcn', @(~,~)this.stopDragBoxFcn);
            this.textFbCtrl.changeText('选择Box模式');
        end
        
        function changeModeToArea(this,~,~)
            set(this.uFigure, 'WindowButtonDownFcn', @(~,~)this.startDragAreaFcn);
            set(this.uFigure, 'WindowButtonUpFcn', @(~,~)this.stopDragAreaFcn);
            this.textFbCtrl.changeText('选择区域模式');
        end
        
        function saveCurrentImageLabels(this,~,~)
            this.dataStore{this.imageID} = this.axesCtrl.getLabels();
            res = this.dataStore{this.imageID};
            save(fullfile(pwd,'label',this.patientID,int2str(this.imageID)),'res');
            this.textFbCtrl.changeText('当前断面标签已保存');
        end
        
        function startDragBoxFcn(this,varargin)
            set(this.uFigure, 'WindowButtonMotionFcn', @(~,~)this.draggingBoxFcn);
            this.textFbCtrl.changeText('Mouse start moving.');
            tmp = round(this.uAx.CurrentPoint);
            this.startPos = [tmp(1,1), tmp(1,2)];
            this.endPos = [tmp(1,1), tmp(1,2)];
            this.axesCtrl.addImage();
            this.axesCtrl.renderLastImageWithSquare(this.startPos,this.startPos);
        end
        
        function draggingBoxFcn(this,varargin)
            this.textFbCtrl.changeText('鼠标移动');
            tmp = round(this.uAx.CurrentPoint);
            this.endPos = [tmp(1,1), tmp(1,2)];
            this.uFdBk.String = sprintf('当前鼠标位点: [%d, %d]', tmp(1,1), tmp(1,2));
            this.axesCtrl.renderLastImageWithSquare(this.startPos,this.endPos);
        end
        
        function stopDragBoxFcn(this, varargin)
            set(this.uFigure, 'WindowButtonMotionFcn', '');
            this.textFbCtrl.changeText('Box选画完成');
            tmp = round(this.uAx.CurrentPoint);
            this.endPos = [tmp(1,1), tmp(1,2)];
            this.axesCtrl.renderLastImageWithSquare(this.startPos,this.endPos);
            this.textInfoCtrl.changeText(this.axesCtrl.presentText());
            % show as 不确定 by defualt
            this.uOpts.Value = 5;
        end
        
        function startDragAreaFcn(this,varargin)
            set(this.uFigure, 'WindowButtonMotionFcn', @(~,~)this.draggingAreaFcn);
            this.textFbCtrl.changeText('鼠标开始捕捉');
            tmp = round(this.uAx.CurrentPoint);
            this.startPos = [tmp(1,1), tmp(1,2)];
            this.endPos = [tmp(1,1), tmp(1,2)];
            this.axesCtrl.addImage();
            this.axesCtrl.renderLastImageWithArea(this.startPos,this.startPos);
        end
        
        function draggingAreaFcn(this,varargin)
            this.textFbCtrl.changeText('鼠标移动中');
            tmp = round(this.uAx.CurrentPoint);
            this.endPos = [tmp(1,1), tmp(1,2)];
            this.uFdBk.String = sprintf('当前鼠标位点: [%d, %d]', tmp(1,1), tmp(1,2));
            this.axesCtrl.renderLastImageWithArea(this.startPos,this.endPos);
        end
        
        function stopDragAreaFcn(this, varargin)
            set(this.uFigure, 'WindowButtonMotionFcn', '');
            this.textFbCtrl.changeText('区域选画完成');
            tmp = round(this.uAx.CurrentPoint);
            this.endPos = [tmp(1,1), tmp(1,2)];
            this.axesCtrl.renderLastImageWithArea(this.startPos,this.endPos);
            this.textInfoCtrl.changeText(this.axesCtrl.presentText());
            % show as 不确定 by defualt
            this.uOpts.Value = 5;
        end
        
        function captureKeyPress(this,~,event)
            switch event.Key
                case 'n'
                    this.selectNextImage();
                case 'p'
                    this.selectLastImage();
                case 'c'
                    this.deleteLastLabel();
                case '1'
                    this.uOpts.Value = 1;
                case '2'
                    this.uOpts.Value = 2;
                case '3'
                    this.uOpts.Value = 3;
                case '4'
                    this.uOpts.Value = 4;
                case '5'
                    this.uOpts.Value = 5;
                %case '6'
                    %this.uOpts.Value = 6;
                case 'z'
                    this.showSeparateImage();
                case 'b'
                    this.changeModeToBox();
                case 'a'
                    this.changeModeToArea();
                case 'j'
                    this.processBaseImage1();
                case 'k'
                    this.processBaseImage2();
                case 'o'
                    this.showOriginalImage();
                case 's'
                    this.saveCurrentImageLabels();
                case 't'
                    this.increaseGrayScale();
                case 'r'
                    this.decreaseGrayScale();
            end
        end
    end
    
    methods(Access = private)
        % axes-related utils
        function deleteLastLabel(this,~,~)
            this.axesCtrl.deleteLastLabelImage();
            this.textFbCtrl.changeText('删除上一个标签');
            this.textInfoCtrl.changeText(this.axesCtrl.presentText());
        end
        
        function selectLastImage(this,~,~)
            if this.imageID > 1
                this.imageID = this.imageID - 1;
                this.renderByImageID();
                this.textFbCtrl.changeText(sprintf('当前显示第%d张', this.imageID));
            end
        end
        
        function selectNextImage(this,~,~)
            if this.imageID < this.uSlider.Max
                this.imageID = this.imageID + 1;
                this.renderByImageID();
                this.textFbCtrl.changeText(sprintf('当前显示第%d张', this.imageID));
            end
        end
        
        function renderByImageID(this)
            try
            this.uSlider.Value = this.imageID;
            catch
            end
            
            this.imageData = mat2gray(flip(this.data.data(:,:,this.imageID)',2));
            this.axesCtrl.renderNewImage(this.imageData, this.dataStore{this.imageID});
            this.textInfoCtrl.changeText(this.axesCtrl.presentText());
        end
        
        function showSeparateImage(this,~,~)
            newFigure = figure;
            newAx = axes(newFigure);
            newFigure.Name = int2str(this.uSlider.Value);
            newFigure.NumberTitle = 'off';
            colormap(newAx, this.grayColorMap(this.gScale));
            imagesc(newAx, flipud(this.imageData));
        end
        
        function processBaseImage1(this,~,~)
            this.axesCtrl.processBaseImage1();
            this.textFbCtrl.changeText('增强模式');
        end
        
        function processBaseImage2(this,~,~)
            this.axesCtrl.processBaseImage2();
            this.textFbCtrl.changeText('尖锐模式');
        end
        
        function showOriginalImage(this,~,~)
            this.axesCtrl.showOriginalImage();
            this.textFbCtrl.changeText('显示原图');
        end
        
        function increaseGrayScale(this,~,~)
            this.gScale = this.gScale + 0.5;
            this.axesCtrl.changeColorMap(this.gScale);
            this.textFbCtrl.changeText('显示原图');
        end
        
        function decreaseGrayScale(this,~,~)
            this.gScale = max(this.gScale - 0.5 ,0.5);
            this.axesCtrl.changeColorMap(this.gScale);
            this.textFbCtrl.changeText('显示原图');
        end
        
        function loadPreExistingData(this)
            f = waitbar(0,'载入数据...');
            total = size(this.data.data,3);
            for i = 1:total
                try
                load(fullfile(pwd,'label',this.patientID,[int2str(i),'.mat']),'-mat','res');
                this.dataStore{i} = res;
                catch
                end
                waitbar(i/total, f, '载入中...');
            end
            close(f);
        end
    end
    
    methods (Access = private)
        function map = grayColorMap(this, n)
            map = gray.^(n);
        end
    end
end