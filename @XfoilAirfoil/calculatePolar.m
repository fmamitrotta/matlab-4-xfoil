function calculatePolar(obj)
%calculatePolar Calculates the polar of the airfoil
%   calculatePolar(obj)
% Calculate polar only if both ncrit and Reynolds number are
% available, or if inviscid calculation is desired
if (~isempty(obj.Ncrit) && ~isempty(obj.Re)) || ~obj.ViscousFlag
    % Check validity of airfoil
    if any(obj.Ycu < obj.Ycl)
        warning(['Invalid airfoil, top and bottom side ',...
            'intersect. Polar calculation aborted.'])
        return
    end
    % Display information to command window
    if obj.ViscousFlag
        fprintf(['Calculating polar of airfoil ',obj.Name,...
            ' at Re = %.2e.\n'],obj.Re)
    else
        fprintf(['Calculating polar of airfoil ',obj.Name,...
            '. Inviscid calculation.\n'])
    end
    % Calculate polar through Xfoil
    [alpha,cl,cdrag,cdp,cm,topXtr,botXtr] = obj.oper('polar');
    % Retrieve sort index vector to order the polar with
    % ascending angle of attack
    [~,I] = sort(alpha);
    % Assemble polar structure array
    obj.PolarProxy = struct('alpha',num2cell(alpha(I)),...
        'cl',num2cell(cl(I)),'cd',num2cell(cdrag(I)),...
        'cdp',num2cell(cdp(I)),'cm',num2cell(cm(I)),...
        'topXtr',num2cell(topXtr(I)),...
        'botXtr',num2cell(botXtr(I)));
end
end
