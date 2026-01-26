report 166600 "NZ Industry Groups"
{
    Caption = 'NZ Industry Groups';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        while (TxtFile.Pos < TxtFile.Len) do begin
            TxtFile.Read(Text);
            ImportCode := CopyStr(Text, 2, StrPos(Text, ',') - 3);
            Text := DelStr(Text, 1, StrPos(Text, ','));
            Text := DelChr(Text, '=', '"');
            ImportDescription := CopyStr(Text, 1);
            if StrLen(ImportDescription) <= 30 then
                InsertRecord();
        end;
        TxtFile.Close();
    end;

    trigger OnPreReport()
    begin
        FileName := 'localfiles\TradeCodes.txt';
        Clear(TxtFile);
        TxtFile.TextMode := true;
        TxtFile.Open(FileName);
    end;

    var
        IndustryGroup: Record "Industry Group";
        IndustryGroup2: Record "Industry Group";
        TxtFile: File;
        FileName: Text[250];
        Text: Text[1024];
        ImportCode: Code[20];
        ImportDescription: Text[200];

    procedure InsertRecord()
    begin
        IndustryGroup.Code := ImportCode;
        IndustryGroup.Description := ImportDescription;

        if not IndustryGroup2.Get(IndustryGroup.Code) then
            IndustryGroup.Insert();
    end;
}

