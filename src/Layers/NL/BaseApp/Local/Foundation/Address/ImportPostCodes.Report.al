// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using System.IO;

report 11414 "Import Post Codes"
{
    Caption = 'Import Post Codes';
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

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
        ImportFile: File;
        Header: Text;
        Line: Text;
        Continue: Boolean;
    begin
        PostCodeRange.Reset();

        if not PostCodeRange.IsEmpty() then
            if not Confirm(Text000, false, PostCodeRange.TableCaption()) then
                CurrReport.Quit();

        PostCodeRange.DeleteAll();

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
                PostCodeRange."Post Code" := FormatPostCode(ReadText(Line, 1, 6));

                if StrLen(PostCodeRange."Post Code") = 7 then begin
                    PostCodeRange.Type := ReadInteger(Line, 7, 1) + 1;
                    PostCodeRange."From No." := ReadInteger(Line, 8, 5);
                    PostCodeRange."To No." := ReadInteger(Line, 13, 5);
                    PostCodeRange.City := ReadText(Line, 36, 24);
                    PostCodeRange."Street Name" := ReadText(Line, 101, 43);
                    PostCodeRange.Insert(true);
                end;
            end;
        end;

        ImportFile.Close();
    end;

    var
        PostCodeRange: Record "Post Code Range";
        Text000: Label 'Importing a complete post code data file (as opposed to an upgrade file) will delete any existing %1 entries.\\Do you want to continue?';
        PostCodeUpdateLogEntry: Record "Post Code Update Log Entry";
        ImportFileName: Text;
        Text002: Label 'Invalid file signature.\\%1';
        Text004: Label 'Invalid month %1 in file signature.\\Valid months are %2.';
        Text005: Label 'Invalid year %1 in file signature.';

    [Scope('OnPrem')]
    procedure ReadText(String: Text; Position: Integer; Length: Integer): Text
    begin
        exit(DelChr(CopyStr(String, Position, Length), '>'));
    end;

    [Scope('OnPrem')]
    procedure ReadInteger(String: Text; Position: Integer; Length: Integer) Result: Integer
    var
        Text: Text;
    begin
        Text := ReadText(String, Position, Length);

        if DelChr(Text, '<>') = '' then
            exit(0);

        Evaluate(Result, Text);
    end;

    [Scope('OnPrem')]
    procedure ProcessHeader(Header: Text)
    var
        PostCodeUpdateLogEntry2: Record "Post Code Update Log Entry";
        Month: Integer;
        Year: Integer;
        i: Integer;
    begin
        if ReadText(Header, 1, StrLen(ExpectedHeader())) <> ExpectedHeader() then
            Error(Text002, DelChr(Header, '>', ' .'));

        for i := 1 to 12 do
            if SelectStr(i, MonthNames()) = ReadText(Header, 33, 3) then
                Month := i;

        if Month = 0 then
            Error(Text004, ReadText(Header, 33, 3), MonthNames());

        if not Evaluate(Year, ReadText(Header, 37, 4)) then
            Error(Text005, ReadText(Header, 37, 4));

        PostCodeUpdateLogEntry2.LockTable();
        if not PostCodeUpdateLogEntry2.FindLast() then;

        PostCodeUpdateLogEntry."No." := PostCodeUpdateLogEntry2."No." + 1;
        PostCodeUpdateLogEntry."Period Start Date" := DMY2Date(1, Month, Year);
        PostCodeUpdateLogEntry.Date := Today;
        PostCodeUpdateLogEntry.Time := Time;
        PostCodeUpdateLogEntry."User ID" := UserId;
        PostCodeUpdateLogEntry.Type := PostCodeUpdateLogEntry.Type::"Full Data Set";
        PostCodeUpdateLogEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure IsFooter(Line: Text): Boolean
    begin
        if StrLen(Line) = 0 then
            exit(true);
        exit(ReadText(Line, 1, 1) = '*');
    end;

    [Scope('OnPrem')]
    procedure FormatPostCode(Text: Text[30]): Text[30]
    begin
        exit(CopyStr(Text, 1, 4) + ' ' + CopyStr(Text, 5, 2));
    end;

    [Scope('OnPrem')]
    procedure ExpectedHeader(): Text[50]
    begin
        exit('*** POSTCODETABEL PTT REEKS VAN');
    end;

    [Scope('OnPrem')]
    procedure MonthNames(): Text[50]
    begin
        exit('JAN,FEB,MAA,APR,MEI,JUN,JUL,AUG,SEP,OKT,NOV,DEC');
    end;
}

