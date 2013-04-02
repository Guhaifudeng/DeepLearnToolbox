function nn = nnapplygrads_gpu(nn)
%NNAPPLYGRADS updates weights and biases with calculated gradients
% nn = nnapplygrads(nn) returns an neural network structure with updated
% weights and biases

for i = 1 : (nn.n - 1)
    if(nn.weightPenaltyL2>0)
        dW = nn.learningRate * (nn.dW{i} + nn.weightPenaltyL2 * nn.W{i});
        db = nn.learningRate * nn.db{i};
    else
        dW = nn.learningRate * nn.dW{i};
        db = nn.learningRate * nn.db{i};
    end
    
    if(nn.momentum>0)  %apply momentum
        nn.vW{i} = nn.momentum*nn.vW{i} + dW;
        dW = nn.vW{i};
        
        nn.vb{i} = nn.momentum*nn.vb{i} + db;
        db = nn.vb{i};
        
    end
    
    %apply gradients
    nn.W{i} = nn.W{i} - dW;
    nn.b{i} = nn.b{i} - db;
    
    
    %Max L2 norm of incoming weights to individual neurons
    
    if nn.weightMaxL2norm > 0;
        l2 = gpuArray(nn.weightMaxL2norm);
        %Get the L2 norm indput to the individual Neurons
        normalizer  = sum(nn.W{i}.^2,2) / l2;
        idx = normalizer < l2;
        normalizer(idx) = 1;
        nn.W{i} = bsxfun(@rdivide, nn.W{i},sqrt(normalizer) );
        end
    end
end
end