function matrix = inf2nan(matrix)
matrix(isinf(matrix)) = NaN;
end