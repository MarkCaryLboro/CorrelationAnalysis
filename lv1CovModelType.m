classdef lv1CovModelType < int8
    % Define supported level-1 model covariance models
    
    enumeration
        OLS     (0)
        Power   (1)
        TwoComp (2)
    end
end % classdef