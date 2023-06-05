tableextension 11290 "SE Company Information" extends "Company Information"
{
    var
        BoardOfDirectorsLocCaptionLbl: Label 'Board Of Directors Location (registered office)';

    procedure GetLegalOfficeLabel(): Text
    begin
        exit(BoardOfDirectorsLocCaptionLbl);
    end;
}