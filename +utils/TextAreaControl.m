classdef TextAreaControl < handle
    properties
        textUI;
    end
    
    methods(Access=public)
        function this = TextAreaControl(uitext)
            this.textUI = uitext;
        end
        
        function changeText(this, str)
            this.textUI.String = sprintf('%s',str);
        end
    end
end