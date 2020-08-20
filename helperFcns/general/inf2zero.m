function matrix = inf2zero(matrix)
matrix(isinf(matrix)) = 0;
end