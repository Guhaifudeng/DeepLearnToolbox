
addpath('../data');
addpath('../util');
addpath('../NN');
load mnist_uint8;
close all
cast = @double;

train_x = cast(train_x) / 255;
test_x  = cast(test_x)  / 255;
train_y = cast(train_y);
test_y  = cast(test_y);

% normalize
[train_x, mu, sigma] = zscore(train_x);
test_x = normalize(test_x, mu, sigma);

%% ex1 vanilla neural net
rng(0);
nn = nnsetup([784 1200 1200 1200 10]);
nn.output = 'softmax';
nn.activation_function = 'sigm';
nn.normalize_input = 0;

nn.dropoutFraction = 0.5;
nn.inputZeroMaskedFraction = 0.2;
%nn.weightPenaltyL2 = 1e-6;
nn.weightMaxL2norm = 15;
nn.cast = @double;
nn.caststr = 'double';
nn.momentum_variable = [linspace(0.5,0.99,500) linspace(0.99,0.99,opts.numepochs-500)];
nn.learningRate_variable =  10.*(linspace(0.998,0.998,opts.numepochs).^linspace(1,opts.numepochs,opts.numepochs));
nn.learningRate_variable = opts.learningRate_variable.*opts.momentum_variable;

opts.numepochs =  1000;   %  Number of full sweeps through data

opts.plot           = 1;
opts.batchsize      = 100;  %  Take a mean gradient step over this many samples
opts.ntrainforeval  = 5000; % number of training samples that are copied to the gpu and used to 
                           % evalute training performance
                           % if you have a small dataset set this to number
                           % of samples in your training data

opts.nbathesToLoad  = 50;   % GPU only. To minimize GPU host transfer bathces are loaded
                            % onto the gpu in groups of opts.nbathesToLoad.
                            % If you experice memory errors / use large  (above 5000)
                            % batch size the performance penalty for
                            % lowering opts.nbathesToLoad is low
                           
tt = tic;
                           [nn_gpu,L,loss] = nntrain_gpu(nn, train_x, train_y, opts);
toc(tt);
                           %[nn_cpu,L,loss] = nntrain(nn, train_x, train_y, opts);
[er_gpu, bad] = nntest(nn_gpu, test_x, test_y);
%[er_cpu, bad] = nntest(nn_cpu, test_x, test_y);
fprintf('Error GPU (single): %f \n',er_gpu);
%fprintf('Error GPU (single); %f \n',er_cpu);

% 
% load mnist_uint8;
% cast = @double;
% 
% train_x = cast(train_x) / 255;
% test_x  = cast(test_x)  / 255;
% train_y = cast(train_y);
% test_y  = cast(test_y);
% 
% % normalize
% [train_x, mu, sigma] = zscore(train_x);
% test_x = normalize(test_x, mu, sigma);
% 
% %% ex1 vanilla neural net
% rng(0);
% nn = nnsetup([784 200 10]);
% 
% fprintf('DOUBLE PRECISION PERFORMANCE \n')
% %[nn_gpu,L,loss] = nntrain_gpu(nn, train_x, train_y, opts);
% [nn_cpu,L,loss] = nntrain(nn, train_x, train_y, opts);
% %[er_gpu, bad] = nntest(nn_gpu, test_x, test_y);
% [er_cpu, bad] = nntest(nn_cpu, test_x, test_y);
% fprintf('Error GPU (double): %f \n',er_gpu);
% fprintf('Error GPU (double); %f \n',er_cpu);
