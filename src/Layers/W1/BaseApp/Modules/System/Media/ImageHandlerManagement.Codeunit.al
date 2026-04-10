namespace System.Media;

using System;
using System.Utilities;

codeunit 5080 "Image Handler Management"
{
    var
        ImageQuality: Integer;

    [TryFunction]
    procedure ScaleDown(var SourceImageInStream: InStream; var ResizedImageOutStream: OutStream; NewWidth: Integer; NewHeight: Integer)
    var
        ImageHandler: DotNet ImageHandler;
    begin
        ImageHandler := ImageHandler.ImageHandler(SourceImageInStream);

        if ImageQuality = 0 then
            ImageQuality := GetDefaultImageQuality();

        if (ImageHandler.Height <= NewHeight) and (ImageHandler.Width <= NewWidth) then begin
            CopyStream(ResizedImageOutStream, SourceImageInStream);
            exit;
        end;

        CopyStream(ResizedImageOutStream, ImageHandler.ResizeImage(NewWidth, NewHeight, ImageQuality));
    end;

    procedure ScaleDownFromBlob(var TempBlob: Codeunit "Temp Blob"; NewWidth: Integer; NewHeight: Integer): Boolean
    var
        ImageInStream: InStream;
        ImageOutStream: OutStream;
    begin
        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(ImageInStream);
        TempBlob.CreateOutStream(ImageOutStream);

        exit(ScaleDown(ImageInStream, ImageOutStream, NewWidth, NewHeight));
    end;

    procedure SetQuality(NewImageQuality: Integer)
    begin
        ImageQuality := NewImageQuality;
    end;

    local procedure GetDefaultImageQuality(): Integer
    begin
        // Default quality that produces the best quality/compression ratio
        exit(90);
    end;

    [TryFunction]
    procedure GetImageSize(ImageInStream: InStream; var Width: Integer; var Height: Integer)
    var
        ImageHandler: DotNet ImageHandler;
    begin
        ImageHandler := ImageHandler.ImageHandler(ImageInStream);

        Width := ImageHandler.Width;
        Height := ImageHandler.Height;
    end;

    [TryFunction]
    procedure GetImageSizeBlob(var TempBlob: Codeunit "Temp Blob"; var Width: Integer; var Height: Integer)
    var
        ImageInStream: InStream;
    begin
        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(ImageInStream);

        GetImageSize(ImageInStream, Width, Height);
    end;
}

