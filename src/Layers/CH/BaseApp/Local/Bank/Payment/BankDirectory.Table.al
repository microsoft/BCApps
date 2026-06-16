// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Address;
using System.Utilities;

table 11500 "Bank Directory"
{
    Caption = 'Bank Directory';
    DataPerCompany = false;
    DrillDownPageID = "Bank Directory";
    LookupPageID = "Bank Directory";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Clearing No."; Code[5])
        {
            Caption = 'Clearing No.';
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; Address; Text[30])
        {
            Caption = 'Address';
        }
        field(4; "Address 2"; Text[30])
        {
            Caption = 'Address 2';
        }
        field(5; "Post Code"; Text[20])
        {
            Caption = 'Post Code';

            trigger OnValidate()
            begin
                if PostCode.Get("Post Code") then
                    City := PostCode.City;
            end;
        }
        field(6; City; Text[30])
        {
            Caption = 'City';
        }
        field(9; "New Clearing No."; Code[5])
        {
            Caption = 'New Clearing No.';
        }
        field(10; Group; Option)
        {
            Caption = 'Group';
            OptionCaption = ' ,SNB,UBS,Spare,CS,,Regionalbank,Kantonalbank,Raiffeisen/Indivual Banks,Miscellaneous';
            OptionMembers = " ",SNB,UBS,Spare,CS,,Regionalbank,Kantonalbank,"Raiffeisen/Indivual Banks",Miscellaneous;
        }
        field(20; "No of Outlets"; Integer)
        {
            BlankZero = true;
            Caption = 'No of Outlets';
        }
        field(30; "SIC No."; Code[10])
        {
            Caption = 'SIC No.';
        }
        field(32; "Clearing Main Office"; Code[5])
        {
            Caption = 'Clearing Main Office';
        }
        field(34; "Bank Type"; Option)
        {
            Caption = 'Bank Type';
            OptionCaption = ' ,Main Office,Head Office,Outlet';
            OptionMembers = " ","Main Office","Head Office",Outlet;
        }
        field(40; "Valid from"; Date)
        {
            Caption = 'Valid from';
        }
        field(50; "SIC Member"; Option)
        {
            Caption = 'SIC Member';
            OptionCaption = 'No,Yes,Indirect';
            OptionMembers = No,Yes,Indirect;
        }
        field(52; "euroSIC Member"; Option)
        {
            Caption = 'euroSIC Member';
            OptionCaption = 'No,Yes';
            OptionMembers = No,Yes;
        }
        field(54; "Language Code"; Text[1])
        {
            Caption = 'Language Code';
        }
        field(60; "Short Name"; Text[20])
        {
            Caption = 'Short Name';
        }
        field(62; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(64; Country; Code[2])
        {
            Caption = 'Country';
        }
        field(66; "SWIFT Address"; Code[15])
        {
            Caption = 'SWIFT Address';
        }
        field(70; "Import from File"; Boolean)
        {
            Caption = 'Import from File';
            Editable = false;
        }
        field(71; "Sight Deposit Account"; Code[12])
        {
            Caption = 'Sight Deposit Account';
        }
    }

    keys
    {
        key(Key1; "Clearing No.")
        {
            Clustered = true;
        }
        key(Key2; "Post Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Clearing No.", Name, City)
        {
        }
    }

    var
        Text006: Label 'File %1 not found.';
        Text007: Label 'Import bank directory\';
        Text008: Label 'Clearingno.       #1####\';
        Text009: Label 'Number of recs    #2####';
        PostCode: Record "Post Code";
        BankDirectory2: Record "Bank Directory";
        Window: Dialog;
        Txt1: Text[250];
        Txt2: Text[250];

    [Scope('OnPrem')]
    procedure ImportBankDirectoryDirect(Filename: Text[1024]; var NoOfRecsRead: Integer; var NoOfRecsWritten: Integer)
    var
        f: File;
        FileInStream: InStream;
        FirstLine: Text;
        Byte: Char;
        i: Integer;
    begin
        InitImport();

        // Peek at first line with Windows encoding so Windows-1252 legacy files do not
        // fail decoding before we get a chance to fall back to the legacy format path.
        // The 'IID' header is ASCII, so detection works identically in either encoding.
        f.TextMode(true);
        if not f.Open(Filename, TEXTENCODING::Windows) then
            Error(Text006, Filename);
        f.Read(FirstLine);
        f.Close();

        if StrPos(FirstLine, 'IID') = 1 then begin
            f.TextMode(false);
            if not f.Open(Filename, TEXTENCODING::UTF8) then
                Error(Text006, Filename);
            f.CreateInStream(FileInStream);
            // Skip header line
            FileInStream.ReadText(FirstLine);
            ImportBankDirectoryCsvFromStream(FileInStream, NoOfRecsRead, NoOfRecsWritten);
            f.Close();
            exit;
        end;

        // Legacy fixed-width format
        f.TextMode(false);
        if not f.Open(Filename, TEXTENCODING::Windows) then
            Error(Text006, Filename);
        Window.Open(
          Text007 + // Read bank directory
          Text008 + // Clearing no #1
          Text009);  // No of recs #2

        while f.Read(Byte) <> 0 do
            HandleChar(i, NoOfRecsRead, NoOfRecsWritten, Byte);

        Window.Close();
        f.Close();
    end;

    [Scope('OnPrem')]
    procedure ImportBankDirectoryFromTempBlob(TempBlob: Codeunit "Temp Blob"; var NoOfRecsRead: Integer; var NoOfRecsWritten: Integer)
    var
        FileInStream: InStream;
        FirstLine: Text;
        Byte: Char;
        i: Integer;
    begin
        InitImport();

        // Peek at first line to detect CSV V3 format (semicolon-delimited, starts with "IID")
        // Use Windows encoding for peek since legacy files contain Windows-1252 characters that are invalid UTF-8
        TempBlob.CreateInStream(FileInStream, TEXTENCODING::Windows);
        FileInStream.ReadText(FirstLine);
        if StrPos(FirstLine, 'IID') = 1 then begin
            // Re-open as UTF-8 for proper CSV V3 parsing (header already consumed by peek)
            TempBlob.CreateInStream(FileInStream, TEXTENCODING::UTF8);
            FileInStream.ReadText(FirstLine); // skip header
            ImportBankDirectoryCsvFromStream(FileInStream, NoOfRecsRead, NoOfRecsWritten);
            exit;
        end;

        // Legacy fixed-width format - re-open stream from beginning
        TempBlob.CreateInStream(FileInStream, TEXTENCODING::Windows);

        Window.Open(
          Text007 +
          Text008 +
          Text009);

        while not FileInStream.EOS() do begin
            FileInStream.Read(Byte, 1);
            HandleChar(i, NoOfRecsRead, NoOfRecsWritten, Byte);
        end;

        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure WriteBankRecord(var NoOfRecsRead: Integer; var NoOfRecsWritten: Integer)
    var
        xBankGrp: Text[2];
        xClearingNoNew: Text[10];
        xBankType: Text[1];
        xSIC: Text[1];
        xEuroSIC: Text[1];
        xLanguage: Text[1];
        dd: Integer;
        mm: Integer;
        yy: Integer;
    begin
        // Bank Group: Pos1/L2
        xBankGrp := DelChr(CopyStr(Txt1, 1, 2), '>');
        case xBankGrp of
            '01':
                Group := Group::SNB;
            '02':
                Group := Group::UBS;
            '03':
                Group := Group::Spare;
            '04':
                Group := Group::CS;
            '05':
                Group := Group::CS;
            '06':
                Group := Group::Regionalbank;
            '07':
                Group := Group::Kantonalbank;
            '08':
                Group := Group::"Raiffeisen/Indivual Banks";
            '09':
                Group := Group::CS;
            else
                Group := Group::Miscellaneous;
        end;

        // Clearing: Pos3/L5
        "Clearing No." := DelChr(CopyStr(Txt1, 3, 5), '>');

        // Clearing new: Pos12/L5, if link to new bank, skip
        xClearingNoNew := DelChr(CopyStr(Txt1, 12, 5), '>');
        "New Clearing No." := CopyStr(xClearingNoNew, 1, MaxStrLen("New Clearing No."));
        "Import from File" := true;

        // SIC: Pos17/L6
        "SIC No." := DelChr(CopyStr(Txt1, 17, 6), '>');

        // Clr Main Office: Pos23/L5
        "Clearing Main Office" := DelChr(CopyStr(Txt1, 23, 5), '>');

        // Bank Type: Pos28/L1
        xBankType := DelChr(CopyStr(Txt1, 28, 1), '>');
        case xBankType of
            '1':
                "Bank Type" := "Bank Type"::"Main Office";
            '2':
                "Bank Type" := "Bank Type"::"Head Office";
            '3':
                "Bank Type" := "Bank Type"::Outlet;
        end;

        // Valid from: Pos29/L8, yyyymmdd
        if Evaluate(yy, CopyStr(Txt1, 29, 4)) and
           Evaluate(mm, CopyStr(Txt1, 33, 2)) and
           Evaluate(dd, CopyStr(Txt1, 35, 2))
        then
            "Valid from" := DMY2Date(dd, mm, yy);

        // SIC member: Pos37/L1
        xSIC := DelChr(CopyStr(Txt1, 37, 1), '>');
        case xSIC of
            '0':
                "SIC Member" := "SIC Member"::No;
            '1':
                "SIC Member" := "SIC Member"::Yes;
            '2':
                "SIC Member" := "SIC Member"::Indirect;
        end;

        // euroSIC member: Pos38/L1
        xEuroSIC := DelChr(CopyStr(Txt1, 38, 1), '>');
        case xEuroSIC of
            '0':
                "euroSIC Member" := "euroSIC Member"::No;
            '1':
                "euroSIC Member" := "euroSIC Member"::Yes;
        end;

        // Language: Pos39/L1
        xLanguage := DelChr(CopyStr(Txt1, 39, 1), '>');
        case xLanguage of
            '1':
                "Language Code" := 'D';
            '2':
                "Language Code" := 'F';
            '3':
                "Language Code" := 'I';
        end;

        // trim address and other strings
        "Short Name" := DelChr(CopyStr(Txt1, 40, 15), '>');  // Pos40/15
        Name := DelChr(CopyStr(Txt1, 55, 30), '>');  // Pos55/60->30
        Address := DelChr(CopyStr(Txt1, 115, 30), '>');
        "Address 2" := DelChr(CopyStr(Txt1, 150, 30), '>');
        "Post Code" := DelChr(CopyStr(Txt1, 185, 10), '>');
        City := DelChr(CopyStr(Txt1, 195, 30), '>');
        "Phone No." := DelChr(CopyStr(Txt1, 230, 18), '>');

        // cut off due to overflow in Supp. Bank
        "Post Code" := CopyStr("Post Code", 1, 5);

        // Rec Part 2, from Pos 249
        Country := DelChr(CopyStr(Txt2, 23, 2), '>');

        // Sight deposit account
        "Sight Deposit Account" := DelChr(CopyStr(Txt2, 25, 12), '>');

        // Foreign phone no
        if Country <> '' then
            "Phone No." := CopyStr(Txt2, 18, 5) + "Phone No.";

        "SWIFT Address" := DelChr(CopyStr(Txt2, 37, 14), '>');

        NoOfRecsRead := NoOfRecsRead + 1;

        if Insert() then
            NoOfRecsWritten := NoOfRecsWritten + 1
        else begin
            BankDirectory2.Get("Clearing No.");
            BankDirectory2."No of Outlets" := BankDirectory2."No of Outlets" + 1;
            BankDirectory2.Modify();
        end;
    end;

    local procedure ImportBankDirectoryCsvFromStream(var FileInStream: InStream; var NoOfRecsRead: Integer; var NoOfRecsWritten: Integer)
    var
        Line: Text;
        Fields: List of [Text];
        FieldValue: Text;
        IIDType: Text;
        SICParticipation: Text;
        EuroSICParticipation: Text;
    begin
        // Header line was already consumed by the caller for format detection.
        Window.Open(
          Text007 +
          Text008 +
          Text009);

        while not FileInStream.EOS() do begin
            FileInStream.ReadText(Line);
            // Skip empty and malformed lines (missing expected 19+ columns) to avoid inserting
            // stale/incorrect bank routing data carried over from the previous loop iteration.
            if (Line <> '') and (Line.Split(';').Count() >= 19) then begin
                // Reset record so fields not assigned by the CSV branch (Group, Language Code,
                // Short Name, Phone No., Sight Deposit Account, No of Outlets, ...) do not leak
                // values from the previous loop iteration into the row being processed.
                Init();
                Fields := Line.Split(';');

                // Column 1: IID/QR-IID
                Fields.Get(1, FieldValue);
                "Clearing No." := CopyStr(DelChr(FieldValue, '>'), 1, MaxStrLen("Clearing No."));

                // Column 2: Valid on (YYYY-MM-DD) - parse with XML/ISO format (9) so the
                // result is independent of the session's regional date format.
                Fields.Get(2, FieldValue);
                if not Evaluate("Valid from", FieldValue, 9) then
                    "Valid from" := 0D;

                // Column 4: New IID/QR-IID
                Fields.Get(4, FieldValue);
                "New Clearing No." := CopyStr(DelChr(FieldValue, '>'), 1, MaxStrLen("New Clearing No."));

                // Column 5: SIC IID
                Fields.Get(5, FieldValue);
                "SIC No." := CopyStr(DelChr(FieldValue, '>'), 1, MaxStrLen("SIC No."));

                // Column 6: Headquarters
                Fields.Get(6, FieldValue);
                "Clearing Main Office" := CopyStr(DelChr(FieldValue, '>'), 1, MaxStrLen("Clearing Main Office"));

                // Column 7: IID type (1=Main Office, 2=Head Office, 3=Outlet)
                Fields.Get(7, IIDType);
                case IIDType of
                    '1':
                        "Bank Type" := "Bank Type"::"Main Office";
                    '2':
                        "Bank Type" := "Bank Type"::"Head Office";
                    '3':
                        "Bank Type" := "Bank Type"::Outlet;
                    else
                        "Bank Type" := "Bank Type"::" ";
                end;

                // Column 9: Name of bank/institution
                Fields.Get(9, FieldValue);
                Name := CopyStr(FieldValue, 1, MaxStrLen(Name));

                // Column 10: Street Name → Address
                Fields.Get(10, FieldValue);
                Address := CopyStr(FieldValue, 1, MaxStrLen(Address));

                // Column 11: Building Number → Address 2
                Fields.Get(11, FieldValue);
                "Address 2" := CopyStr(FieldValue, 1, MaxStrLen("Address 2"));

                // Column 12: Post Code
                Fields.Get(12, FieldValue);
                "Post Code" := CopyStr(FieldValue, 1, MaxStrLen("Post Code"));

                // Column 13: Town Name
                Fields.Get(13, FieldValue);
                City := CopyStr(FieldValue, 1, MaxStrLen(City));

                // Column 14: Country
                Fields.Get(14, FieldValue);
                Country := CopyStr(DelChr(FieldValue, '>'), 1, MaxStrLen(Country));

                // Column 15: BIC
                Fields.Get(15, FieldValue);
                "SWIFT Address" := CopyStr(DelChr(FieldValue, '>'), 1, MaxStrLen("SWIFT Address"));

                // Column 16: SIC participation (Y/N)
                Fields.Get(16, SICParticipation);
                case SICParticipation of
                    'Y':
                        "SIC Member" := "SIC Member"::Yes;
                    'N':
                        "SIC Member" := "SIC Member"::No;
                end;

                // Column 19: euroSIC participation (Y/N)
                Fields.Get(19, EuroSICParticipation);
                case EuroSICParticipation of
                    'Y':
                        "euroSIC Member" := "euroSIC Member"::Yes;
                    'N':
                        "euroSIC Member" := "euroSIC Member"::No;
                end;

                "Import from File" := true;

                NoOfRecsRead := NoOfRecsRead + 1;

                if Insert() then
                    NoOfRecsWritten := NoOfRecsWritten + 1
                else begin
                    BankDirectory2.Get("Clearing No.");
                    BankDirectory2."No of Outlets" := BankDirectory2."No of Outlets" + 1;
                    BankDirectory2.Modify();
                end;

                if (NoOfRecsRead mod 100) = 0 then begin
                    Window.Update(1, "Clearing No.");
                    Window.Update(2, NoOfRecsRead);
                end;
            end;
        end;

        Window.Close();
    end;

    local procedure InitImport()
    begin
        ModifyAll("Import from File", false);
        ModifyAll("No of Outlets", 0);
    end;

    local procedure HandleChar(var i: Integer; var NoOfRecsRead: Integer; var NoOfRecsWritten: Integer; Byte: Char)
    begin
        i := i + 1;

        if i <= 248 then
            Txt1 := Txt1 + Format(Byte)
        else
            Txt2 := Txt2 + Format(Byte);

        // Record length 298 + CR/LF
        if i = 300 then begin
            WriteBankRecord(NoOfRecsRead, NoOfRecsWritten);

            Txt1 := '';
            Txt2 := '';
            i := 0;

            if (NoOfRecsRead mod 100) = 0 then begin
                Window.Update(1, "Clearing No.");
                Window.Update(2, NoOfRecsRead);
            end;
        end;
    end;
}

