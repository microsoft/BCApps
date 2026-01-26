report 166500 "Import AU Industry Groups"
{
    Caption = 'Import AU Industry Groups';
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
    var
        Text: Text[1024];
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
    var
        DemoDataSetup: Record "Demo Data Setup";
        FileName: Text[1024];
    begin
        DemoDataSetup.Get();
        FileName := 'localfiles\TradeCodes.txt';
        Clear(TxtFile);
        TxtFile.TextMode := true;
        TxtFile.Open(FileName);
    end;

    var
        TxtFile: File;
        ImportCode: Code[20];
        ImportDescription: Text[200];

    procedure InsertRecord()
    var
        IndustryGroup: Record "Industry Group";
        IndustryGroup2: Record "Industry Group";
    begin
        IndustryGroup.Code := ImportCode;
        IndustryGroup.Description := ImportDescription;

        if not IndustryGroup2.Get(IndustryGroup.Code) then
            IndustryGroup.Insert();
    end;
}

