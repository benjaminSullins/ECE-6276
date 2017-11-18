% ------------------------------------------------------
%  Company: Georgia Tech
%  Engineer: Zachary Boe
% 
%  Create Date: 11/18/2017
%  Design Name: video_transpose (MATLAB model)
%  Project Name: VGA Image Transpose and Edge Detection
% ------------------------------------------------------
function [ vga_imag_hor, vga_imag_ver, vga_imag_yoshi ] = vga_model(orig_imag_hor, orig_imag_ver, orig_imag_yoshi, wid, len, output_wid, output_len)

vga_imag_hor = vga(orig_imag_hor, wid, len, output_wid, output_len);

vga_imag_ver = vga(orig_imag_ver, wid, len, output_wid, output_len);

vga_imag_yoshi = vga(orig_imag_yoshi, wid, len, output_wid, output_len);

end

function vga_imag = vga(in_imag, wid, len, output_wid, output_len)
vga_imag = uint8(zeros(output_len,output_wid));
shift = log2(output_wid/wid);
for i = 0:output_len-1
    for j = 0:output_wid-1
        newi = bitshift(i,-shift)+1;
        newj = bitshift(j,-shift)+1;
        pixel = in_imag(newi,newj);
        newpixel = uint8(pixel / 16) * 16;
        vga_imag(i+1,j+1) = newpixel;
    end
end
end
