// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using System.IO;

report 11415 "Import Post Codes Update"
{
    Caption = 'Import Post Codes Update';
    ProcessingOnly = true;
    UseRequestPage = false;

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

    trigger OnInitReport()
    begin
        PostCodeUpdateLogEntry.Reset();
        PostCodeUpdateLogEntry.SetCurrentKey(Type);
        PostCodeUpdateLogEntry.SetRange(Type, PostCodeUpdateLogEntry.Type::"Full Data Set");

        if not PostCodeUpdateLogEntry.FindFirst() then
            if not Confirm(NoFullDataSetQst, false) then
                CurrReport.Quit();
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
        ImportFile: File;
        Header: Text;
        Line: Text;
        ChangeType: Option Delete,Modify,Insert;
        Continue: Boolean;
    begin
        ImportFileName := FileMgt.UploadFile('', '*.txt');

        ImportFile.TextMode := true;
        ImportFile.WriteMode := false;
        ImportFile.Open(ImportFileName);

        ImportFile.Read(Header);
        ProcessHeader(Header);

        Continue := true;

        while (ImportFile.Pos < ImportFile.Len) and Continue do begin
            ImportFile.Read(Line);

            if IsFooter(Line) then
                Continue := false
            else begin
                ChangeType := ReadInteger(Line, 1, 1);

                OldPostCodeRange.Init();
                OldPostCodeRange."Post Code" := FormatPostCode(CopyStr(ReadText(Line, 18, 6), 1, 20));
                OldPostCodeRange.Type := ReadInteger(Line, 24, 1) + 1;
                OldPostCodeRange."From No." := ReadInteger(Line, 25, 5);
                OldPostCodeRange."To No." := ReadInteger(Line, 30, 5);
                OldPostCodeRange.City := CopyStr(ReadText(Line, 53, 24), 1, 30);
                OldPostCodeRange."Street Name" := CopyStr(ReadText(Line, 118, 43), 1, 50);

                NewPostCodeRange.Init();
                NewPostCodeRange."Post Code" := FormatPostCode(CopyStr(ReadText(Line, 202, 6), 1, 20));
                NewPostCodeRange.Type := ReadInteger(Line, 208, 1) + 1;
                NewPostCodeRange."From No." := ReadInteger(Line, 209, 5);
                NewPostCodeRange."To No." := ReadInteger(Line, 214, 5);
                NewPostCodeRange.City := CopyStr(ReadText(Line, 237, 24), 1, 30);
                NewPostCodeRange."Street Name" := CopyStr(ReadText(Line, 302, 43), 1, 50);

                case ChangeType of
                    ChangeType::Insert:
                        InsertRange();
                    ChangeType::Modify:
                        ModifyRange();
                    ChangeType::Delete:
                        DeleteRange();
                end;
            end;
        end;

        ImportFile.Close();
    end;

    var
        PostCodeUpdateLogEntry: Record "Post Code Update Log Entry";
        InvalidSignatureErr: Label 'Invalid update file signature.\\%1', Comment = '%1 = Header of file';
        InvalidMonthErr: Label 'Invalid month %1 in update file signature.\\Valid months are %2.', Comment = '%2 = list of valid months';
        InvalidYearErr: Label 'Invalid year %1 in update file signature.', Comment = '%1 = the invalid year';
        NoImportErr: Label 'Cannot import this update; this update or a newer one has already been imported.';
        GapQst: Label 'There is a gap between the current and the previous post code range update.\\If you continue, you will not be able to import the missing update(s), which may render your post code table incomplete. Continue?';
        NoFullDataSetQst: Label 'No full data sets are present yet. Do you still want to import this update?';
        OldPostCodeRange: Record "Post Code Range";
        NewPostCodeRange: Record "Post Code Range";
        ImportFileName: Text;

    local procedure ReadText(String: Text; Position: Integer; Length: Integer): Text
    begin
        exit(DelChr(CopyStr(String, Position, Length), '>'));
    end;

    local procedure ReadInteger(String: Text; Position: Integer; Length: Integer) Result: Integer
    var
        Text: Text;
    begin
        Text := ReadText(String, Position, Length);

        if DelChr(Text, '<>') = '' then
            exit(0);

        Evaluate(Result, Text);
    end;

    local procedure ProcessHeader(Header: Text)
    var
        PostCodeUpdateLogEntry2: Record "Post Code Update Log Entry";
        Month: Integer;
        Year: Integer;
        i: Integer;
    begin
        if ReadText(Header, 1, StrLen(ExpectedHeader())) <> ExpectedHeader() then
            Error(InvalidSignatureErr, DelChr(Header, '>', '. '));

        for i := 1 to 12 do
            if SelectStr(i, MonthNames()) = ReadText(Header, 42, 3) then
                Month := i;

        if Month = 0 then
            Error(InvalidMonthErr, ReadText(Header, 42, 3), MonthNames());

        if not Evaluate(Year, ReadText(Header, 46, 4)) then
            Error(InvalidYearErr, ReadText(Header, 46, 4));

        PostCodeUpdateLogEntry.Init();
        PostCodeUpdateLogEntry."Period Start Date" := DMY2Date(1, Month, Year);

        PostCodeUpdateLogEntry2.Reset();
        PostCodeUpdateLogEntry2.LockTable();

        if PostCodeUpdateLogEntry2.FindLast() then begin
            if PostCodeUpdateLogEntry."Period Start Date" <= PostCodeUpdateLogEntry2."Period Start Date" then
                Error(NoImportErr);
            if PostCodeUpdateLogEntry."Period Start Date" <> CalcDate('<+1M>', PostCodeUpdateLogEntry2."Period Start Date") then
                if not Confirm(GapQst) then
                    CurrReport.Quit();
        end;

        PostCodeUpdateLogEntry."No." := PostCodeUpdateLogEntry2."No." + 1;
        PostCodeUpdateLogEntry.Date := Today;
        PostCodeUpdateLogEntry.Time := SYSTEM.Time;
        PostCodeUpdateLogEntry."User ID" := UserId;
        PostCodeUpdateLogEntry.Type := PostCodeUpdateLogEntry.Type::Update;
        PostCodeUpdateLogEntry.Insert();
    end;

    local procedure InsertRange()
    begin
        if StrLen(NewPostCodeRange."Post Code") = 7 then
            if not NewPostCodeRange.Insert(true) then;
    end;

    local procedure ModifyRange()
    begin
        DeleteRange();
        InsertRange();
    end;

    local procedure DeleteRange()
    begin
        if not OldPostCodeRange.Delete(true) then;
    end;

    local procedure IsFooter(Line: Text): Boolean
    begin
        if StrLen(Line) = 0 then
            exit(true);
        exit(ReadText(Line, 1, 1) = '*');
    end;

    local procedure FormatPostCode(Text: Text[20]): Text[20]
    begin
        exit(CopyStr(Text, 1, 4) + ' ' + CopyStr(Text, 5, 2));
    end;

    local procedure ExpectedHeader(): Text[50]
    begin
        exit('*** MUTATIES POSTCODETABEL PTT REEKS VAN');
    end;

    local procedure MonthNames(): Text[50]
    begin
        exit('JAN,FEB,MAA,APR,MEI,JUN,JUL,AUG,SEP,OKT,NOV,DEC');
    end;
}

