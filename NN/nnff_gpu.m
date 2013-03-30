function nn = nnff_gpu(nn, x, y)
%NNFF performs a feedforward pass
% nn = nnff(nn, x, y) returns an neural network structure with updated
% layer activations, error and loss (nn.a, nn.e and nn.L)

    n = nn.n;
    m = size(x, 1);
    nn.a{1} = x;

    %feedforward pass
    for i = 2 : n-1
        inp = nn.a{i - 1} * nn.W{i - 1}' + repmat(nn.b{i-1}',m,1);
        switch nn.activation_function 
            case 'sigm'
                % Calculate the unit's outputs (including the bias term)
                nn.a{i} = arrayfun(@sigm,inp);
            case 'tanh_opt'
                nn.a{i} = arrayfun(@tanh_opt,inp);
            case 'ReLU'  % linear rectified units max(0,x) 
                nn.a{i} = arrayfun(@ReLU,inp);
        end
        clear inp
        
        %dropout
        if(nn.dropoutFraction > 0)
            if(nn.testing)
                nn.a{i} = nn.a{i}.*(1 - nn.dropoutFraction);
            else
                nn.dropOutMask{i} = (gpuArray.rand(size(nn.a{i}))>nn.dropoutFraction);
                nn.a{i} = nn.a{i}.*nn.dropOutMask{i};
            end
        end
        
        %calculate running exponential activations for use with sparsity
        if(nn.nonSparsityPenalty>0)
            nn.p{i} = 0.99 * nn.p{i} + 0.01 * mean(nn.a{i}, 1);
        end
    end
    
    inp = nn.a{n - 1} * nn.W{n - 1}' + repmat(nn.b{n-1}',m,1);
    switch nn.output 
        case 'sigm'
            nn.a{n} = arrayfun(@sigm, inp);
        case 'linear'
            nn.a{n} = inp;
        case 'softmax'
            nn.a{n} = inp;
            nn.a{n} = exp(bsxfun(@minus, nn.a{n}, max(nn.a{n},[],2)));
            nn.a{n} = bsxfun(@rdivide, nn.a{n}, sum(nn.a{n}, 2)); 
    end
    clear inp
    
    %error and loss
    nn.e = y - nn.a{n};
    
    switch nn.output
        case {'sigm', 'linear'}
            nn.L = 1/2 * sum(sum(nn.e .^ 2)) / m; 
        case 'softmax'
            nn.L = -sum(sum(y .* log(nn.a{n}))) / m;
    end
end