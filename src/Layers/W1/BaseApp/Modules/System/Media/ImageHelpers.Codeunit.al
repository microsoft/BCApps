namespace System.Media;

using System.Utilities;

codeunit 4112 "Image Helpers"
{

    trigger OnRun()
    begin
    end;

    var
        NoContentErr: Label 'The stream is empty.';
        UnknownImageTypeErr: Label 'Unknown image type.';
        HTMLImgSrcTok: Label 'data:image/%1;base64,%2', Locked = true;

    procedure GetHTMLImgSrc(InStream: InStream): Text
    var
        Image: Codeunit Image;
    begin
        if InStream.EOS() then
            exit('');

        if not TryGetImage(InStream, Image) then
            exit('');

        exit(StrSubstNo(HTMLImgSrcTok, Image.GetFormatAsText(), Image.ToBase64()));
    end;

    procedure GetImageType(InStream: InStream): Text
    var
        Image: Codeunit Image;
    begin
        if InStream.EOS() then
            Error(NoContentErr);

        if not TryGetImage(InStream, Image) then
            Error(UnknownImageTypeErr);

        exit(Image.GetFormatAsText());
    end;

    [TryFunction]
    local procedure TryGetImage(InStream: InStream; var Image: Codeunit Image)
    begin
        Image.FromStream(InStream);
    end;
}
