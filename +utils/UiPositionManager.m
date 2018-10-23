classdef UiPositionManager < handle
    properties(Access=private)
        r1 = 3/4
        r2 = 3/4
        % screen size
        scX
        scY
    end
    
    properties(Access=public)
        % important positions
        pA
        pB
        pC
        pD
        pE
        pF
    end
    
    methods(Access=public)
        function this = UiPositionManager()
            % based on the ratio * ratio desing
            screenSize = get(0,'ScreenSize');
            this.scX = screenSize(3);
            this.scY = screenSize(4);
            wth = this.r1 * this.scY;
            % important pts
            this.pA = [(this.scX - wth)/2, (this.scY - wth)/2];
            this.pB = [this.scX - this.pA(1), this.pA(2)];
            this.pC = [this.pB(1), this.scY - this.pB(2)];
            this.pD = [this.pA(1), this.pC(2)];
            this.pE = [(1 - this.r2) * this.pA(1) + this.r2 * this.pB(1),...
                (1-this.r2) * this.pC(2) + this.r2 * this.pB(2)];
            this.pF = [this.pE(1), this.scY - this.pE(2)];
        end
    end
    
    methods(Access=private)
    end
end