% cudaica() - Run stand-alone binary version of runica() from the
%            Matlab command line. Saves time and memory relative
%            to runica().  If stored in a float file, data are not
%            read into Matlab, and so may be larger than Matlab
%            can handle owing to memory limitations.
% Usage:
%  >> [wts,sph] = cudaica( datavar,  'key1', arg1, 'key2', arg2 ...);
% else
%  >> [wts,sph] = cudaica('datafile', chans, frames, 'key1', arg1, ...);
%
% Inputs:
%   datavar       - (chans,frames) data matrix in the Matlab workspace
%   datafile      - quoted 'filename' of float data file multiplexed by channel
%     channels    -   number of channels in datafile (not needed for datavar)
%     frames      -   number of frames (time points) in datafile (only)
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
%   'weightsin'  - Filename string of inital weight matrix of size
%                  (comps,chans) floats, else a weight matrix variable
%                  in the current Matlab workspace (copied to a local
%                  .inwts files). You may want to reduce the starting
%                  'lrate' arg (above) when resuming training, and/or
%                  to reduce the 'stop' arg (above). By default, binary
%                  ica begins with the identity matrix after sphering.
%   'verbose'    - 'on'/'off'    {default: 'off'}
%   'filenum'    - the number to be used in the name of the output files.
%                  Otherwise chosen randomly. Will choose random number
%                  if file with that number already exists.
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

% Calls binary translation of runica() by Sigurd Enghoff

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

% 08/07/00 Added warning to update icadefs.m -sm
% 09/08/00 Added tmpint to script, weights and sphere files to avoid
%          conflicts when multiple cudaica sessions run in the same pwd -sm
% 10/07/00 Fixed bug in reading wts when 'pca' ncomps < nchans -sm
% 07/18/01 replaced var ICA with CUDAICABINARY to try to avoid Matlab6 bug -sm
% 11/06/01 add absolute path of files (lines 157-170 & 198) -ad
% 01-25-02 reformated help & license, added links -ad

function [weights,sphere,tmpint] = cudaica(data,var2,var3,var4,var5,var6,var7,var8,var9,var10,var11,var12,var13,var14,var15,var16,var17,var18,var19,var20,var21,var22,var23,var24,var25)

if nargin < 1 || nargin > 25
    more on
    help cudaica
    more off
    return
end
if size(data,3) > 1, data = reshape(data, size(data,1), size(data,2)*size(data,3) ); end
[nchans, frames] = size(data);
urchans = nchans;

icadefs % import CUDAICABINARY and SC
if ~exist('SC','var')
    fprintf('cudaica(): You need to update your icadefs file to include CUDAICABINARY and SC.\n')
    return
end
if exist(SC,'file') ~= 2
    fprintf('cudaica(): No ica source file ''%s'' is in your Matlab path, check...\n', SC);
    return
else
    SC = which(SC);
    fprintf('cudaica: using source file ''%s''\n',  SC);
end
if exist(CUDAICABINARY,'file') ~= 2
    fprintf('cudaica(): ica binary ''%s'' is not in your Matlab path, check\n', CUDAICABINARY);
    return
else
    CUDAICABINARYdir = which(CUDAICABINARY);
    if ~isempty(CUDAICABINARYdir)
        fprintf('cudaica(): using binary ica file ''%s''\n', CUDAICABINARYdir);
    else
        fprintf('cudaica(): using binary ica file ''\?/%s''\n', CUDAICABINARY);
    end
end

[flags,args] = read_sc(SC); % read flags and args in master SC file


%% Substitute the flags/args pairs in the .sc file
tmpint=[];

if ~ischar(data) % data variable given
    firstarg = 2;
else % data filename given
    firstarg = 4;
end

arg = firstarg;
if arg > nargin
    fprintf('cudaica(): no optional (flag, argument) pairs received.\n');
else
    if (nargin-arg+1)/2 > 1
        fprintf('cudaica(): processing %d (flag, arg) pairs.\n',(nargin-arg+1)/2);
    else
        fprintf('cudaica(): processing one (flag, arg) pair.\n');
    end
    while arg <= nargin %%%%%%%%%%%% process flags & args %%%%%%%%%%%%%%%%
        
        eval(['OPTIONFLAG = var' int2str(arg) ';']);
        % NB: Found that here Matlab var 'FLAG' is (64,3) why!?!?
        
        if arg == nargin
            fprintf('\ncudaica(): Flag %s needs an argument.\n',OPTIONFLAG)
            return
        end
        eval(['Arg = var' int2str(arg+1) ';']);
        
        if strcmpi(OPTIONFLAG,'pca')
            ncomps = Arg; % get number of components out for reading wts.
            if ncomps ~=0 && ncomps <= nchans
                pcaflag = 1;
                [data, PCAweight] = runPCA(data,ncomps);
                nchans = ncomps;
            else
                warning('The number of PCA components must be >=1 and <=nchannels. We will not perform PCA in this dataset.')
                ncomps = 0;
                pcaflag = 0;
            end
        else
            pcaflag = 0;
        end
        
        if strcmpi(OPTIONFLAG,'weightsin')
            wtsin = Arg;
            if exist('wtsin','file')
                fprintf('   setting %s, %s\n','weightsin',Arg);
            elseif exist('wtsin','var')
                if size(wtsin,2) ~= nchans
                    fprintf('weightsin variable must be of width %d\n',nchans);
                    return
                end
            else
                fprintf('weightsin variable not found.\n');
                return
            end
        end
        
        if strcmpi(OPTIONFLAG,'filenum')
            tmpint = Arg; % get number for name of output files
            if ~isnumeric(tmpint)
                fprintf('\ncudaica(): FileNum argument needs to be a number.  Will use random number instead.\n')
                tmpint=[];
            end
            tmpint=int2str(tmpint);
        end
        
        if strcmpi(OPTIONFLAG,'seed')
            seed = Arg; % get number for name of output files
            if ~isnumeric(seed)
                fprintf('\ncudaica(): seed argument needs to be a number.  Will use random number instead.\n')
            end
            seed=int2str(seed);
            Arg = seed;
            flags{end+1} = 'seed';
            args{end+1} = 0;
        end
        
        
        arg = arg+2;
        
        nflags = length(flags);
        for f=1:nflags   % replace SC arg with Arg passed from commandline
            if strcmp(OPTIONFLAG,flags{f})
                args{f} = num2str(Arg);
                fprintf('   setting %s, %s\n',flags{f},args{f});
            end
        end
    end
end

% Change snnealstep according to using extended ICA or not (see runica.m).
if strcmp(args{strcmp('extended',flags)},'0')
    args{strcmp('annealstep',flags)} = num2str(0.90);
else
    args{strcmp('annealstep',flags)} = num2str(0.98);
end

%% Select random integer 1-10000 to index the cudaica data files
% To make sure no such script file already exists in the pwd

scriptfile = ['cudaica' tmpint '.sc'];
while exist(scriptfile,'file')
    tmpint = int2str(round(rand*10000));
    scriptfile = ['cudaica' tmpint '.sc'];
end
fprintf('scriptfile = %s\n',scriptfile);

% Write data to .fdt file
tmpdata = [];
if ~ischar(data) % data variable given
    if ~exist('data','var')
        fprintf('\ncudaica(): Variable name data not found.\n');
        return
    end
    nchans = size(data,1);
    nframes = size(data,2);
    tmpdata = ['cudaica' tmpint '.fdt'];
    if strcmpi(computer, 'MAC')
        floatwrite(data,tmpdata,'ieee-be',[],'double');
    else
        floatwrite(data,tmpdata,[],[],'double');
    end
    datafile = tmpdata;
    
else % data filename given
    if ~exist(data,'file')
        fprintf('\ncudaica(): File data not found.\n')
        return
    end
    datafile = data;
    if nargin<3
        fprintf('\ncudaica(): Data file name must be followed by chans, frames\n');
        return
    end
    nchans = var2;
    nframes = var3;
    if ischar(nchans) || ischar(nframes)
        fprintf('\ncudaica(): chans, frames args must be given after data file name\n');
        return
    end
end

% insert name of data files, chans and frames
for x=1:length(flags)
    if strcmp(flags{x},'DataFile')
        datafile = [pwd, filesep, datafile];
        args{x} = datafile;
    elseif strcmp(flags{x},'WeightsOutFile')
        weightsfile = ['cudaica' tmpint '.wts'];
        weightsfile =  [pwd, filesep, weightsfile];
        args{x} = weightsfile;
    elseif strcmp(flags{x},'WeightsTempFile')
        weightsfile = ['cudaicatmp' tmpint '.wts'];
        weightsfile =  [pwd, filesep, weightsfile];
        args{x} = weightsfile;
    elseif strcmp(flags{x},'SphereFile')
        spherefile = ['cudaica' tmpint '.sph'];
        spherefile =  [pwd, filesep, spherefile];
        args{x} = spherefile;
    elseif strcmp(flags{x},'chans')
        args{x} = int2str(nchans);
    elseif strcmp(flags{x},'frames')
        args{x} = int2str(nframes);
    end
end


%% Write the new .sc file
%
fid = fopen(scriptfile,'w');
% flags;
for x=1:length(flags)
    fprintf(fid,'%s %s\n',flags{x},args{x});
end
if exist('wtsin') % specify WeightsInfile from 'weightsin' flag, arg
    if exist('wtsin') == 1 % variable
        winfn = [pwd '/cudaica' tmpint '.inwts'];
        if strcmpi(computer, 'MAC')
            floatwrite(wtsin,winfn,'ieee-be');
        else
            floatwrite(wtsin,winfn);
        end
        fprintf('   saving input weights:\n  ');
        weightsinfile = winfn; % weights in file name
    elseif exist(wtsin) == 2 % file
        weightsinfile = wtsin;
        weightsinfile =  [pwd, filesep, weightsinfile];
    else
        fprintf('cudaica(): weightsin file|variable not found.\n');
        return
    end
    eval(['!ls -l ' weightsinfile]);
    fprintf(fid,'%s %s\n','WeightsInFile',weightsinfile);
end
fclose(fid);
if ~exist(scriptfile,'file')
    fprintf('\ncudaica(): ica script file %s not written.\n',scriptfile);
    return
end

fprintf('\ncudaica(): ica script file %s data %s pwd %s.\n',scriptfile, datafile, pwd);

%% Run CUDAICA
fprintf('\nRunning ica from script file %s\n',scriptfile);
if exist('ncomps','var')
    fprintf('   Finding %d components.\n',ncomps);
end
eval_call = ['!' CUDAICABINARY ' -f ' pwd filesep scriptfile];
eval(eval_call);

%% Read in wts and sph results.
if ~exist('ncomps','var')
    ncomps = nchans;
end

if strcmpi(computer, 'MAC')
    weights = floatread(weightsfile,[ncomps Inf],'ieee-be',0,'double');
    sphere = floatread(spherefile,[nchans Inf],'ieee-be',0,'double');
else
    weights = floatread(weightsfile,[ncomps Inf],[],0,'double');
    sphere = floatread(spherefile,[nchans Inf],[],0,'double');
end
if isempty(weights)
    fprintf('\ncudaica(): weight matrix not read.\n')
    return
end
if isempty(sphere)
    fprintf('\ncudaica():  sphere matrix not read.\n')
    return
end

% fprintf('\nbinary ica files left in pwd:\n');
% if ispc
%     eval(['!dir /B ' scriptfile ' ' weightsfile ' ' spherefile]);
% else
%     eval(['!ls -l ' scriptfile ' ' weightsfile ' ' spherefile]);
% end
% if exist('wtsin')
%     if ispc
%         eval(['!dir /B ' weightsinfile]);
%     else
%         eval(['!ls -l ' weightsinfile]);
%     end
% end
% fprintf('\n');
%
% if ischar(data)
%     whos wts sph
% else
%     whos data wts sph
% end

% If created by cudaica(), rm temporary data file
if ~isempty(tmpdata)
    if ispc
        eval(['!del ' datafile]);
        eval(['!del ' scriptfile]);
        eval(['!del ' weightsfile]);
        eval(['!del ' spherefile]);
    else
        eval(['!rm -f ' datafile]);
        eval(['!rm -f ' scriptfile]);
        eval(['!rm -f ' weightsfile]);
        eval(['!rm -f ' spherefile]);
    end
end

%% Post-Processing
fprintf('\n====================================\n');
fprintf(' Post processing\n');
fprintf('====================================\n\n');

% runica.m sphere the data before ICA training, we do it after the training. They behave the same.
data = sphere*data;

% Multiply PCA weights back to ICA weights
if pcaflag
    fprintf('Composing the eigenvector, weights, and sphere matrices into a single rectangular weights matrix; sphere=eye(%d)\n',nchans);
    weights= weights*sphere*PCAweight;
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
meanvar = sum(winv.^2).*sum((data').^2)/((nchans*frames)-1);
[~, windex] = sort(meanvar);
windex = windex(ncomps:-1:1); % order from large to small
weights = weights(windex,:);% reorder the weight matrix

fprintf('Done post-processing!\n\n');

end


%% %%%%%%%%%%%%%%%%% included functions %%%%%%%%%%%%%%%%%%%%%%
%
function sout = rmcomment(s,symb)
n =1;
while n <= length(s) && s(n)~=symb % discard # comments
    n = n+1;
end
if n == 1
    sout = [];
else
    sout = s(1:n-1);
end
end

function sout = rmspace(s)
n=1;          % discard leading whitespace
while n<length(s) && isspace(s(n))
    n = n+1;
end
if n<length(s)
    sout = s(n:end);
else
    sout = [];
end
end

function [word,sout] = firstword(s)
n=1;
while n<=length(s) && ~isspace(s(n))
    n = n+1;
end
if n>length(s)
    word = [];
    sout = s;
else
    word = s(1:n-1);
    sout = s(n:end);
end
end

function [flags,args] = read_sc(master_sc)
%
% read in the master ica script file SC
%
flags = [];
args  = [];
fid = fopen(master_sc,'r');
if fid < 0
    fprintf('\ncudaica(): Master .sc file %s not read!\n',master_sc)
    return
end
%
% read SC file info into flags and args lists
%
s = [];
f = 0; % flag number in file
while isempty(s) | s ~= -1
    s = fgetl(fid);
    if s ~= -1
        if ~isempty(s)
            s = rmcomment(s,'#');
            if ~isempty(s)
                f = f+1;
                s = rmspace(s);
                [w, s]=firstword(s);
                if ~isempty(s)
                    flags{f} = w;
                    s = rmspace(s);
                    [w, s]=firstword(s);
                    args{f} = w;
                end
            end
        end
    end
end
end

%% Perform PCA to reduce data dimension
function [DataOut,PCAWeight] = runPCA(DataIn,ncomps)
fprintf('Reducing the data to %d principal dimensions...\n',ncomps);

PCdat2 = DataIn';                        % transpose data
[PCn,~]=size(PCdat2);                  % now p chans,n time points
PCdat2=PCdat2/PCn;
PCout=DataIn*PCdat2;
clear PCdat2;

[PCV,PCD] = eig(PCout);                  % get eigenvectors/eigenvalues
[~,PCindex] = sort(diag(PCD),'descend');
PCEigenVectors=PCV(:,PCindex);
DataOut = PCEigenVectors(:,1:ncomps)'*DataIn;
PCAWeight = PCEigenVectors(:,1:ncomps)';
end


%% Function to .fdt write data to disk
function A = floatwrite(A, fname, fform, transp, precision)

if ~exist('fform','var') || isempty(fform)
    fform = 'native';
end
if ~exist('transp','var') || isempty(transp)
    transp = 'normal';
end
if ~exist('precision','var') || isempty(precision)
    precision = 'double';
end

if strcmpi(transp,'normal')
    if strcmpi(class(A), 'mmo')
        A = changefile(A, fname);
        return;
    elseif strcmpi(class(A), 'memmapdata')
        % check file to overwrite
        % -----------------------
        [fpath1, fname1, ext1] = fileparts(fname);
        [fpath2, fname2, ext2] = fileparts(A.data.Filename);
        if isempty(fpath1), fpath1 = pwd; end
        
        fname1 = fullfile(fpath1, [fname1 ext1]);
        fname2 = fullfile(fpath2, [fname2 ext2]);
        if ~isempty(findstr(fname1, fname2))
            disp('Warning: raw data already saved in memory mapped file (no need to resave it)');
            return;
        end
        
        fid = fopen(fname,'wb',fform);
        if fid == -1, error('Cannot write output file, check permission and space'); end
        if size(A,3) > 1
            for ind = 1:size(A,3)
                tmpdata = A(:,:,ind);
                fwrite(fid,tmpdata,precision);
            end
        else
            blocks = 1:round(size(A,2)/10):size(A,2);
            if blocks(end) ~= size(A,2), blocks = [blocks size(A,2)]; end
            for ind = 1:length(blocks)-1
                tmpdata = A(:, blocks(ind):blocks(ind+1));
                fwrite(fid,tmpdata,precision);
            end
        end
    else
        fid = fopen(fname,'wb',fform);
        if fid == -1, error('Cannot write output file, check permission and space'); end
        fwrite(fid,A,precision);
    end
else
    % save transposed
    for ind = 1:size(A,1)
        fwrite(fid,A(ind,:),precision);
    end
end
fclose(fid);

end

%% Function to read weight and sphere file
function A = floatread(fname,Asize,fform,offset,precision)

if nargin<2
    help floatread
    return
end

if ~exist('fform','var') || isempty(fform) || fform==0
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
    if exist('offset','var')
        if iscell(offset)
            if length(offset) ~= 2
                error('offset must be a positive integer or a 2-item cell array');
            end
            datasize = offset{1};
            startpos = offset{2};
            if length(datasize) ~= length(startpos)
                error('offset must be a positive integer or a 2-item cell array');
            end
            for k=1:length(datasize)
                if startpos(k) < 1 | startpos(k) > datasize(k)
                    error('offset must be a positive integer or a 2-item cell array');
                end
            end
            if length(Asize)> length(datasize)
                error('offset must be a positive integer or a 2-item cell array');
            end
            for k=1:length(Asize)-1
                if startpos(k) ~= 1
                    error('offset must be a positive integer or a 2-item cell array');
                end
            end
            sizedim = length(Asize);
            if Asize(sizedim) + startpos(sizedim) - 1 > datasize(sizedim)
                error('offset must be a positive integer or a 2-item cell array');
            end
            for k=1:length(Asize)-1
                if Asize(k) ~= datasize(k)
                    error('offset must be a positive integer or a 2-item cell array');
                end
            end
            
            offset = 0;
            jumpfac = 1;
            for k=1:length(startpos)
                offset = offset + jumpfac * (startpos(k)-1);
                jumpfac = jumpfac * datasize(k);
            end
            
        elseif length(offset) > 1
            error('offset must be a positive integer or a 2-item cell array');
        end
        
        % perform the fseek() operation
        % -----------------------------
        stts = fseek(fid,sizeOf(precision)*offset,'bof');
            
        if stts ~= 0
            error('floatread(): fseek() error.');
        end
        
        % determine what 'square' means
        % -----------------------------
        if ischar('Asize')
            if iscell(offset)
                if length(datasize) ~= 2 | datasize(1) ~= datasize(2)
                    error('size ''square'' must refer to a square 2-D matrix');
                end
                Asize = [datsize(1) datasize(2)];
            elseif strcmp(Asize,'square')
                fseek(fid,0,'eof'); % go to end of file
                bytes = ftell(fid); % get byte position
                fseek(fid,0,'bof'); % rewind
                bytes = bytes/sizeOf(precision); % nfloats
                froot = sqrt(bytes);
                if round(froot)*round(froot) ~= bytes
                    error('floatread(): filelength is not square.')
                else
                    Asize = [round(froot) round(froot)];
                end
            end
        end
        A = fread(fid,prod(Asize),precision);
    else
        error('floatread() fopen() error.');
    end
    
    % fprintf('   %d floats read\n',prod(size(A)));
    
    % interpret last element of Asize if 'Inf'
    % ----------------------------------------
    if Asize(end) == Inf
        Asize = Asize(1:end-1);
        A = reshape(A,[Asize length(A)/prod(Asize)]);
    else
        A = reshape(A,Asize);
    end
    
    fclose(fid);
    
end
end

%%
function out = sizeOf(in)
numclass = {'double'; 'single'; 'int8'; 'int16'; 'int32'; 'int64'; 'uint8'; 'uint16'; 'uint32'; 'uint64'};
numbytes = [NaN;8;4;1;2;4;8;1;2;4;8];

[~,loc]  = ismember(in,numclass);
out   = numbytes(loc+1);
end
