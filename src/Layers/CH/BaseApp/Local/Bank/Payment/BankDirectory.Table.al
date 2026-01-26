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
        Byte: Char;
        i: Integer;
    begin
        InitImport();

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
        Byte: Char;
        i: Integer;
    begin
        InitImport();

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

