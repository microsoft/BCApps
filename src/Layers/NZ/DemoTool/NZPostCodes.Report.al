report 166601 "NZ Post Codes"
{
    Caption = 'NZ Post Codes';
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
            // import code
            ImportCode := CopyStr(Text, 1, StrPos(Text, ',') - 1);
            Text := DelStr(Text, 1, StrPos(Text, ','));
            // import city
            ImportCity := CopyStr(Text, 1);
            InsertRecord();
        end;
        TxtFile.Close();
    end;

    trigger OnPreReport()
    begin
        FileName := 'localfiles\NZPostCodes.txt';
        Clear(TxtFile);
        TxtFile.TextMode := true;
        TxtFile.Open(FileName);
    end;

    var
        TxtFile: File;
        FileName: Text[250];
        Text: Text[1024];
        ImportCode: Code[20];
        ImportCity: Text[30];
        PostCode: Record "Post Code";
        PostCode2: Record "Post Code";

    procedure InsertRecord()
    begin
        PostCode.Code := ImportCode;
        PostCode.City := ImportCity;
        PostCode."Search City" := UpperCase(PostCode.City);
        if not PostCode2.Get(PostCode.Code, PostCode.City) then
            PostCode.Insert();
    end;
}

