function [weights,sphere,rndint] = cudaica(data,varargin)
% cudaica() - Run stand-alone binary version of runica() from the Matlab command line. Saves time 
%             and memory relative to runica(). If stored in a float file, data are not read into 
%             Matlab, and so may be larger than Matlab can handle owing to memory limitations.
% Usage:
%  >> [wts,sph] = cudaica( datavar,  'key1', arg1, 'key2', arg2 ...);
% or
%  >> [wts,sph] = cudaica('datafile', chans, frames, 'key1', arg1, ...);
%
% Inputs:
%   datavar      - (chans,frames) data matrix in the Matlab workspace
%   datafile     - quoted 'filename' of float data file multiplexed by channel
%     channels   -   number of channels in datafile (not needed for datavar)
%     frames     -   number of frames (time points) in datafile (only)
%
% Optional flag,argument pairs:
%   'extended'   - int>=0        [0 default: assume no subgaussian comps]
%                  Search for subgaussian comps: 'extended',1 is recommended
%   'pca'        - int>=0        [0 default: don't reduce data dimension]
%                    NB: 'pca' reduction not recommended unless necessary
%   'sphering'   - 'on'/'off'    first 'sphere' the data {default: 'on'}
%   'lrate'      - (0<float<<1) starting learning rate {default: 1e-4}
%   'blocksize'  - int>=0        [0 default: heuristic, from data size]
%   'maxsteps'   - int>0         {default: 512}
%   'stop'       - (0<float<<<1) stopping learning rate {default: 1e-7}
%                    NB: 'stop' <= 1e-7 recommended
%   'verbose'    - 'on'/'off'    {default: 'off'}
%   'filenum'    - the number to be used in the name of the output files. Otherwise chosen randomly. 
%                  Will choose random number if file with that number already exists.
%
% Less frequently used input flags:
%   'posact'     - ('on'/'off') Make maximum value for each comp positive.
%                    NB: 'off' recommended. {default: 'off'}
%   'annealstep' - (0<float<1)   {default: 0.90}
%   'annealdeg'  - (0<n<360)     {default: 60}
%   'bias'       - 'on'/'off'    {default: 'on'}
%   'momentum'   - (0<float<1)   {default: 0 = off]
%
% Outputs:
%   wts          - output weights matrix, size (ncomps,nchans)
%   sph          - output sphere matrix, size (nchans,nchans)
%                  Both files are read from float files left on disk
%   stem         - random integer used in the names of the .sc, .wts,
%                  .sph, and if requested, .intwts files
%
% Author: Scott Makeig, SCCN/INC/UCSD, La Jolla, 2000
%
% See also: runica()
%
% Calls binary translation of runica() by Sigurd Enghoff
%
% Copyright (C) 2000 Scott Makeig, SCCN/INC/UCSD, scott@sccn.ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% 08/07/00 Added warning to update icadefs.m -sm
% 09/08/00 Added tmpint to script, weights and sphere files to avoid
%          conflicts when multiple cudaica sessions run in the same pwd -sm
% 10/07/00 Fixed bug in reading wts when 'pca' ncomps < nchans -sm
% 07/18/01 replaced var ICA with CUDAICABINARY to try to avoid Matlab6 bug -sm
% 11/06/01 add absolute path of files (lines 157-170 & 198) -ad
% 01-25-02 reformated help & license, added links -ad
% 2020-02-16 Re-written for better readability.

% The current path should not have spaces
if contains(pwd,' ')
    error('cudaica(): CUDAICA cannot run when the current directory have space character!');
end

% import SC
icadefs;
clearvars -except data varargin SC

%% Check input arguments
if nargin < 1
    error('cudaica(): Not enough input arguments!');
end

if ischar(data)
    % Data array in file.
    if ~exist(data,'file')
        error('cudaica(): File "%s" not found!',data);
    end
    if nargin < 3
        error('cudaica(): Not enough input arguments! Data file name must be followed by nchans, nframes.');
    end
    nchans = varargin{1};
    nframes = varargin{2};
    varargin(1:2) = [];
    if ischar(nchans) || ischar(nframes)
        error('cudaica(): "nchans", "nframes" arguments must be given as numbers\n');
    end
else
    % Data array provided.
    if size(data,3) > 1
        data = reshape(data, size(data,1), size(data,2)*size(data,3));
    end
    [nchans,nframes] = size(data);
    urchans = nchans;
end

%% Check script file template and existence of cudaica binary
if ~exist('SC','var')
    error('cudaica(): You need to update your icadefs file to include SC.');
end
if exist(SC,'file') ~= 2 %#ok<NODEF>
    error('cudaica(): No ica source file ''%s'' is found in your Matlab path!',SC);
else
    SC = which(SC);
    fprintf('Using source file ''%s''\n',SC);
end

% Check the existance of CUDAICA binary file
cudaica_p = fileparts(which('cudaica.m'));
if ispc
    syspath = getenv('PATH');
    if contains(syspath, 'oneAPI')
        CUDAICABINARY = fullfile(cudaica_p, 'cudaica_win_oneapi.exe');
    elseif contains(syspath, 'IntelSWTools')
        CUDAICABINARY = fullfile(cudaica_p, 'cudaica_win_mkl2020.exe');
    else
        error('cudaica(): Cannot find the location of Intel MKL library in Windows system path!');
    end
else
    CUDAICABINARY = fullfile(cudaica_p, 'cudaica');
end
if ~exist(CUDAICABINARY,'file')
    error('cudaica(): cudaica binary ''%s'' is not found in your Matlab path!', CUDAICABINARY);
else
    fprintf('Using binary file ''%s''\n', CUDAICABINARY);
end

%% Substitute the flags/args pairs in the .sc file
% Read flags and args in SC file template
[DefaultFlag,DefaultArgs] = read_sc(SC);
DefaultFlag = DefaultFlag(~cellfun('isempty',DefaultFlag));
DefaultArgs = DefaultArgs(~cellfun('isempty',DefaultArgs));

% Parse parameters
p = inputParser;
for i = 1:length(DefaultFlag)
    addParameter(p,DefaultFlag{i},DefaultArgs{i});
end
parse(p,varargin{:},'chans',nchans,'frames',nframes);
Args = p.Results;

% Change snnealstep according to using extended ICA or not (see runica.m).
if Args.extended == 1
    Args.annealstep = num2str(0.98);
else
    Args.annealstep = num2str(0.90);
end

%% Perform PCA if requsted
if ischar(Args.pca)
    Args.pca = str2double(Args.pca);
end

if Args.pca > 0
    if Args.pca <= nchans
        fprintf('Reducing the data to %d principal dimensions...\n',Args.pca);
        pcaflag = 1;
        [data,PCAweight] = runPCA(data,Args.pca);
        ncomps = Args.pca;
        nchans = Args.pca;
        Args.chans = Args.pca;
    else
        warning('The number of PCA components must be within [1,nchans]. We will not perform PCA in this dataset.');
        Args.pca = 0;
        ncomps = nchans;
        pcaflag = 0;
    end
else
    ncomps = nchans;
    pcaflag = 0;
end

%% Generate cudaica script and data file names
% Generate script file name
rndint = [];
scriptfile = fullfile(pwd,'cudaica.sc');
while exist(scriptfile,'file')
    rndint = int2str(round(rand*10000));
    scriptfile = fullfile(pwd,['cudaica',rndint,'.sc']);
end

% Generate data file name
if ~ischar(data)  
    datafile = fullfile(pwd,['cudaica',rndint,'.fdt']);  % data variable given
else             
    datafile = data;  % data filename given
end

% Insert name of data files, chans and frames to arguments
Args.DataFile = datafile;
Args.WeightsOutFile = fullfile(pwd,['cudaica',rndint,'.wts']);
Args.SphereFile = fullfile(pwd,['cudaica',rndint,'.sph']);

%% Write data and input arguments to files
% Write input arguments
Flags = fieldnames(Args);
fid = fopen(scriptfile,'w');
for i = 1:length(Flags)
    if ischar(Args.(Flags{i}))
        fprintf(fid,'%s %s\n',Flags{i},Args.(Flags{i}));
    else
        fprintf(fid,'%s %s\n',Flags{i},num2str(Args.(Flags{i})));
    end
end
fclose(fid);
if ~exist(scriptfile,'file')
    error('cudaica(): ICA script file "%s" not written.\n',scriptfile);
end

% Write data file
if ~ischar(data)
    if strcmpi(computer, 'MAC')
        myfloatwrite(data,datafile,'ieee-be',false,'double');
    else
        myfloatwrite(data,datafile,'native',false,'double');
    end
end
if ~exist(datafile,'file')
    error('cudaica(): ICA data file "%s" not written.\n',datafile);
end

%% Run CUDAICA
fprintf('\nRunning ica from script file %s\n',scriptfile);
fprintf('   Finding %d components.\n',ncomps);

eval(sprintf('!%s -f "%s"',CUDAICABINARY,scriptfile));

% Delete temporary data and script file.
delete(scriptfile);
if ~ischar(data)
    delete(datafile);
end

%% Read in wts and sph results.
try
    if strcmpi(computer, 'MAC')
        weights = myfloatread(Args.WeightsOutFile,[ncomps,Inf],'ieee-be',0,'double');
        sphere = myfloatread(Args.SphereFile,[nchans,Inf],'ieee-be',0,'double');
    else
        weights = myfloatread(Args.WeightsOutFile,[ncomps,Inf],'native',0,'double');
        sphere = myfloatread(Args.SphereFile,[nchans,Inf],'native',0,'double');
    end
catch
    error('Cannot read the result file. Please make sure you have installed NVIDIA CUDA and Intel MKL (or oneAPI), correctly set the environment variables, and have sufficient GPU memory.');
end
if isempty(weights)
    error('Cannot read weight matrix!');
end
if isempty(sphere)
    error('Cannot read sphere matrix!');
end

% If created by cudaica(), remove temporary data file
delete(Args.WeightsOutFile,Args.SphereFile);

%% Post-Processing
fprintf('\n====================================\n');
fprintf(' Post processing\n');
fprintf('====================================\n\n');

% runica.m sphere the data before ICA training, we do it after the training. They behave the same.
data = sphere * data;

% Multiply PCA weights back to ICA weights
if pcaflag
    fprintf('Composing the eigenvector, weights, and sphere matrices into a single rectangular weights matrix; sphere=eye(%d)\n',nchans);
    weights= weights * sphere * PCAweight;
    sphere = eye(urchans);
end

% Sorting components
fprintf('Sorting components in descending order of mean projected variance ...\n');
if ncomps == urchans % if weights are square . . .
    winv = inv(weights*sphere);
else
    fprintf('Using pseudo-inverse of weight matrix to rank order component projections.\n');
    winv = pinv(weights*sphere);
end
meanvar = sum(winv.^2).*sum((data').^2)/((nchans*nframes)-1);
[~, windex] = sort(meanvar);
windex = windex(ncomps:-1:1); % order from large to small
weights = weights(windex,:);% reorder the weight matrix

fprintf('Done post-processing!\n\n');

end

%% Functions to read ICA configuration file
function [flags,args] = read_sc(master_sc)
% Open the master ica script file SC
fid = fopen(master_sc,'r');
if fid < 0
    error('Cannot read template .sc file "%s"!',master_sc);
end

% read SC file info into flags and args lists
flags = cell(0);
args  = cell(0);
s = fgetl(fid);
f = 0; % flag number in file
while ischar(s)
    s = rmcomment(s,'#');   % Remove comment in line
    s = rmspace(s);         % Remove leading space in line
    
    if ~isempty(s)
        [w,s] = firstword(s);
        if ~isempty(s)
            f = f + 1;
            flags{f} = w;
            s = rmspace(s);
            [w,~] = firstword(s);
            args{f} = w;
        end
    end
    
    % Read the next line
    s = fgetl(fid);
end
end

function sout = rmcomment(s,symb)
% Remove comments in a char array
idx = strfind(s,symb);
if isempty(idx)
    sout = s;
else
    sout = s(1:(idx-1));
end
end

function sout = rmspace(s)
% discard leading whitespace
n = 1;          
while n<length(s) && isspace(s(n))
    n = n+1;
end
if n<length(s)
    sout = s(n:end);
else
    sout = '';
end
end

function [word,sout] = firstword(s)
n=1;
while n<=length(s) && ~isspace(s(n))
    n = n+1;
end
if n>length(s)
    word = '';
    sout = s;
else
    word = s(1:n-1);
    sout = s(n:end);
end
end

%% Function to .fdt write data to disk
function A = myfloatwrite(A, fname, fform, transp, precision)
% Check input arguments
if nargin < 2
    error('Data or file name to write not provided!');
end
if ~exist('fform','var') || isempty(fform)
    fform = 'native';
end
if ~exist('transp','var') || isempty(transp)
    transp = false;  % save transposed data or not
end
if ~exist('precision','var') || isempty(precision)
    precision = 'double';
end

fid = fopen(fname,'wb',fform);
if fid == -1
    error('Cannot write output file, check permission and space'); 
end
if ~transp
    fwrite(fid,A,precision);
else
    fwrite(fid,A',precision);
end
fclose(fid);

end

%% Function to read weight and sphere file
function A = myfloatread(fname,Asize,fform,offset,precision)
% Check input arguments
if ~exist('fname','var') || isempty(fname)
    error('File to read not provided!');
end
if ~exist('Asize','var') || isempty(Asize)
    error('Size of the array to read not provided!');
end
if ~exist('fform','var') || isempty(fform)
    fform = 'native';
end
if ~exist('offset','var') || isempty(offset)
    offset = 0;
end
if ~exist('precision','var') || isempty(precision)
    precision = 'double';
end

fid = fopen(fname,'rb',fform);
if fid>0
    % Move to specified position in file according of "offset".
    stts = fseek(fid,sizeOf(precision)*offset,'bof');
    if stts ~= 0
        error('File read offset (%d) larger than file length!',offset);
    end
    
    % Read the data file.
    A = fread(fid,prod(Asize),precision);
    fclose(fid);
    
    % Reshape readed data
    if Asize(end) == Inf
        Asize = Asize(1:end-1);
        A = reshape(A,[Asize length(A)/prod(Asize)]);
    else
        A = reshape(A,Asize);
    end
else
    error('Error reading file "%s"!',fname);
end
end

function out = sizeOf(in)
numclass = {'double'; 'single'; 'int8'; 'int16'; 'int32'; 'int64'; 'uint8'; 'uint16'; 'uint32'; 'uint64'};
numbytes = [NaN;8;4;1;2;4;8;1;2;4;8];

[~,loc]  = ismember(in,numclass);
out   = numbytes(loc+1);
end
