codeunit 101500 "Create Sales Status Icons"
{
    trigger OnRun()
    var
        i: Integer;
    begin
        for i := 0 to 5 do // skip existing entries
            CreateData(i);
    end;

    var
        IconNotFoundErr: Label 'Could not find the icon %1 at %2.', Comment = '%1 = icon name, %2 = file path to icon';

    local procedure CreateData(IconType: Option)
    var
        SalesDocumentIcon: Record "Sales Document Icon";
        Language: Codeunit Language;
        Path: Text;
        OldLanguageId: Integer;
    begin
        if SalesDocumentIcon.Get(IconType) then
            exit;

        SalesDocumentIcon.Init();
        SalesDocumentIcon.Type := IconType;

        OldLanguageId := GlobalLanguage;
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        Path := 'SalesStatusIcons\' + Format(SalesDocumentIcon.Type) + '.png';
        GlobalLanguage(OldLanguageId);

        if not FILE.Exists(Path) then
            Error(IconNotFoundErr, Format(SalesDocumentIcon.Type), Path);

        SalesDocumentIcon.Insert();
        SalesDocumentIcon.SetIconFromFile(Format(SalesDocumentIcon.Type), Path);
    end;
}

