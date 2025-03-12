function y = quantize_dither(y, bit_depth, varargin)
% quantize_dither: quantize signal re bit depth and optionally add dither.
%   y = quantize_dither(y, bit_depth, varargin)
%           
%       INPUT:
%           y, --> signal
%           bit_depth --> desired bit depth (USB-6229 supports 16-bit)
%           varargin, --> boolean => whether or not to dither the signal.
%

switch nargin
    case 2
        dither = true;
    case 3
        dither = varargin{1};
end

% quantization 
% Determine signal range for proper quantization
signal_max = max(abs(y));
quantization_levels = 2^bit_depth;
max_integer_value = (quantization_levels/2) - 1; %number of values available for +/- signal
scaling_factor = max_integer_value / signal_max;

if dither
    dither_amplitude = signal_max / max_integer_value; %one quantization step
    dither = dither_amplitude * (rand(size(y)) - 0.5);
    y = y + dither;
end
y = round(y * scaling_factor) / scaling_factor;