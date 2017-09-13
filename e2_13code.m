clc; clear all; close all;
load('snow.mat');
load('JpegCoeff.mat');
hall_gray=snow;
hall_gray = double(hall_gray)-128;
% hall_gray = hall_gray-128;
[xLen,yLen] = size(hall_gray);  %x����y����
zigzag = zeros(64,(xLen/8)*(yLen/8));
cntBlock = 1;
for x = 1:xLen/8
    for y = 1:yLen/8
        D = dct2(hall_gray(8*x-7:8*x,8*y-7:8*y));
        D = round(D./QTAB);
        zigzag(:,cntBlock) = ZigZag(D);
        cntBlock=cntBlock+1;
    end
end
cntBlock = cntBlock-1;
% DC
CD = zigzag(1,:);
CD(2:cntBlock)= CD(1:(cntBlock-1))-CD(2:cntBlock);
DC=[];
for i=1:cntBlock
    ctg=Category(CD(i));
    len=DCTAB(ctg+1,1);
    % code=bitget(abs(CD(i)),max(ctg,1):-1:1);
    code=fliplr(bitget(abs(CD(i)),1:max(ctg,1)));
    if(CD(i)<0)
        code=1-code;
    end
    DC=[DC,DCTAB(ctg+1,2:1+len),code];
end
%AC
AC=[];
EOB=[1,0,1,0];
ZRL=[1,1,1,1,1,1,1,1,0,0,1];
for i=1:cntBlock
    cnt0=0;
    for j=2:64
        if(zigzag(j,i)==0)
            if(j==64)
 %               AC=[AC,EOB];
                continue;
            end
            cnt0=cnt0+1;
        else  %zigzag(j,i)~=0
            %Run=cnt0, Size=Category, Amp=xxx
            Size=Category(zigzag(j,i));
            if(cnt0>15)
                while(cnt0>15)
                    AC=[AC,ZRL];
                    cnt0=cnt0-16;
                end
            end
            codeLen=ACTAB(10*cnt0+Size,3);
            % code=fliplr(bitget(abs(zigzag(j,i)),1:Size));
            code=bitget(abs(zigzag(j,i)),Size:-1:1);
            if(zigzag(j,i)<0)
                code=1-code;
            end
            AC=[AC,ACTAB(10*cnt0+Size,4:(3+codeLen)),code];
            cnt0=0;
        end        
    end
    AC=[AC,EOB];
end
save('jpegcodes3.mat','DC','AC','xLen','yLen');
% Compression ratio
output = length(DC) + length(AC);
input = length(dec2bin(255)) * xLen * yLen;
compressRatio = input/output