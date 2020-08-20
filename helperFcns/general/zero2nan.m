function matrix = zero2nan(matrix)
matrix(matrix==0) = NaN;
end