function [PCAdata,PCAWeight] = runPCA(data,ncomps)
% Perform PCA to reduce data dimension. Assuming the first dimenstion is channel, second dimension
% is samples.

% Calculate the covariance matrix.
COV = cov(data'); % Matlab assumes channel in column.

% Get eigenvectors (PCV) and eigenvalues (PCD) of the covariance matrix.
[PCV,PCD] = eig(COV,'vector');

% Sort eigenvalues (PCD) and the corresponding eigenvectors (PCV).
[~,PCidx] = sort(PCD,'descend');
PCV = PCV(:,PCidx);

% Project data into selected principle dimensions.
PCAdata = PCV(:,1:ncomps)' * data;
PCAWeight = PCV(:,1:ncomps)';
end