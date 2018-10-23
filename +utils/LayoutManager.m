classdef LayoutManager < handle
    properties(Access=private)
       width
       height
    end
    
    methods(Access=public)
        function this=LayoutManager(w,h)
            this.width = w;
            this.height = h;
        end
        
        function pos = getPos(this,rl,rb,rw,rh)
            l = this.width * rl;
            b = this.height * rb;
            w = this.width * rw;
            h = this.height * rh;
            pos = [l,b,w,h];
        end
    end
    
    methods(Access=private)
    end
end