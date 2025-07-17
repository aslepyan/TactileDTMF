function finger_matrix = get_finger_matrix(rows, cols, vals)
    % Helper function to calculate the 3x3 matrix for finger data.
    % rows: The row frequencies for the finger
    % cols: The column indices for the finger
    % vals: The sensor data values
    
    finger_matrix = zeros(3, 3); % Initialize 3x3 matrix
    for r = 1:3
        for c = 1:3
            row_value = vals(rows(r));
            col_value = vals(cols(c)); 
            finger_matrix(r, c) = row_value * col_value;
        end
    end
end
