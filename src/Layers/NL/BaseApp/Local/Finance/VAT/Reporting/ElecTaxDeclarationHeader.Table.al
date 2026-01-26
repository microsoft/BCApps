// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using System.Environment;
using System.IO;
using System.Utilities;

table 11409 "Elec. Tax Declaration Header"
{
    Caption = 'Elec. Tax Declaration Header';
    DataCaptionFields = "Declaration Type", "Declaration Period", "Declaration Year";
    DrillDownPageID = "Elec. Tax Declaration List";
    LookupPageID = "Elec. Tax Declaration List";
    Permissions = TableData "Elec. Tax Declaration Line" = imd,
                  TableData "Elec. Tax Decl. Error Log" = d,
                  TableData "Elec. Tax Decl. Response Msg." = d;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Declaration Type"; Option)
        {
            Caption = 'Declaration Type';
            OptionCaption = 'VAT Declaration,ICP Declaration';
            OptionMembers = "VAT Declaration","ICP Declaration";

            trigger OnValidate()
            begin
                if "Declaration Type" <> xRec."Declaration Type" then
                    if "No." <> '' then
                        Error(Text003, FieldCaption("Declaration Type"), FieldCaption("No."), TableCaption);
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    ElecTaxDeclarationSetup.Get();
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,,,Created,,,Submitted,,,Acknowledged,,,Error,Warning';
            OptionMembers = " ",,,Created,,,Submitted,,,Acknowledged,,,Error,Warning;
        }
        field(20; "Message ID"; Text[64])
        {
            Caption = 'Message ID';
            Editable = false;
        }
        field(21; "Schema Version"; Code[10])
        {
            Caption = 'Schema Version';
            Editable = false;
        }
        field(30; "Our Reference"; Code[20])
        {
            Caption = 'Our Reference';

            trigger OnValidate()
            begin
                if "Declaration Type" = "Declaration Type"::"VAT Declaration" then begin
                    if "Our Reference" <> DelChr("Our Reference", '=', DelChr("Our Reference", '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-')) then
                        FieldError("Our Reference", Text004);
                    if CopyStr("Our Reference", 1, 3) <> 'OB-' then
                        FieldError("Our Reference", Text005);
                end;

                if ("Our Reference" <> xRec."Our Reference") and ("Our Reference" <> '') then begin
                    ElecTaxDeclarationHeader.Reset();
                    ElecTaxDeclarationHeader.SetCurrentKey("Our Reference");
                    ElecTaxDeclarationHeader.SetRange("Our Reference", "Our Reference");
                    if ElecTaxDeclarationHeader.FindFirst() then
                        Error(Text002, FieldCaption("Our Reference"),
                          TableCaption, "Our Reference", ElecTaxDeclarationHeader."Declaration Type", ElecTaxDeclarationHeader."No.");
                end;
            end;
        }
        field(40; "Declaration Year"; Integer)
        {
            BlankZero = true;
            Caption = 'Declaration Year';
            MaxValue = 9999;
            MinValue = 2003;

            trigger OnValidate()
            begin
                UpdateDates();
            end;
        }
        field(41; "Declaration Period"; Enum "Elec. Tax Declaration Period")
        {
            Caption = 'Declaration Period';

            trigger OnValidate()
            begin
                if "Declaration Type" = "Declaration Type"::"VAT Declaration" then
                    if ("Declaration Period" in
                        ["Declaration Period"::"January-February", "Declaration Period"::"April-May", "Declaration Period"::"July-August",
                         "Declaration Period"::"October-November"])
                    then
                        Error(Text011, FieldCaption("Declaration Period"), FieldCaption("Declaration Type"), "Declaration Type");
                UpdateDates();
            end;
        }
        field(42; "Declaration Period From Date"; Date)
        {
            Caption = 'Declaration Period From Date';
            Editable = false;
        }
        field(43; "Declaration Period To Date"; Date)
        {
            Caption = 'Declaration Period To Date';
            Editable = false;
        }
        field(80; "Date Created"; Date)
        {
            Caption = 'Date Created';
            Editable = false;
        }
        field(81; "Time Created"; Time)
        {
            Caption = 'Time Created';
            Editable = false;
        }
        field(82; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(90; "Date Submitted"; Date)
        {
            Caption = 'Date Submitted';
            Editable = false;
        }
        field(91; "Time Submitted"; Time)
        {
            Caption = 'Time Submitted';
            Editable = false;
        }
        field(92; "Submitted By"; Code[50])
        {
            Caption = 'Submitted By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(93; "Submission Message BLOB"; BLOB)
        {
            Caption = 'Submission Message BLOB';
        }
        field(100; "Date Received"; Date)
        {
            Caption = 'Date Received';
            Editable = false;
        }
        field(101; "Time Received"; Time)
        {
            Caption = 'Time Received';
            Editable = false;
        }
        field(120; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(130; "SMTP Server Response"; Text[250])
        {
            Caption = 'SMTP Server Response';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Declaration Type", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Our Reference")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Status = Status::Submitted then
            Error(Text000, TableCaption(), FieldCaption(Status), Status);

        ElecTaxDeclarationLine.Reset();
        ElecTaxDeclarationLine.SetRange("Declaration Type", "Declaration Type");
        ElecTaxDeclarationLine.SetRange("Declaration No.", "No.");
        ElecTaxDeclarationLine.DeleteAll();

        ElecTaxDeclErrorLog.Reset();
        ElecTaxDeclErrorLog.SetRange("Declaration Type", "Declaration Type");
        ElecTaxDeclErrorLog.SetRange("Declaration No.", "No.");
        ElecTaxDeclErrorLog.DeleteAll();

        ElecTaxDeclResponseMsg.Reset();
        ElecTaxDeclResponseMsg.SetCurrentKey("Declaration Type", "Declaration No.");
        ElecTaxDeclResponseMsg.SetRange("Declaration Type", "Declaration Type");
        ElecTaxDeclResponseMsg.SetRange("Declaration No.", "No.");
        ElecTaxDeclResponseMsg.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            ElecTaxDeclarationSetup.Get();
            TestNoSeries();
            "No. Series" := GetNoSeriesCode();
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", 0D);
        end;
    end;

    var
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
        Text000: Label 'You cannot delete a %1 if %2 is %3.';
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
        ElecTaxDeclErrorLog: Record "Elec. Tax Decl. Error Log";
        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
        Text002: Label 'The value in %1 must be unique. Value %3 is already used in %2 %4 %5.';
        Text003: Label 'You cannot change %1 once a %2 is assigned to a %3.';
        Text004: Label 'can only contain letters, digits and dashes';
        Text005: Label 'must start with ''OB-''';
        Text007: Label 'You cannot export a %1 of %2 %3 if there was no relevant economic activity during the declaration period.';
        Text008: Label 'It is not allowed to send a declaration with a period that ends after today.';
        Text009: Label 'Declarations from %1 %2 should be processed before September %3.';
        Text010: Label 'A declaration for %1 %2 already exists. Do you wish to continue?';
        Text011: Label '%1 must not be bi-monthly if %2 is %3.';
        UnknownDeclTypeErr: Label 'Unknown declaration type: %1.', Comment = '%1 = declaration type';
        DownloadSubmissionMessageQst: Label 'Do you want to download the submission message?';
        NoSubmissionMessageAvailableErr: Label 'The submission message of the report is not available.';
        SubmissionFileNameTxt: Label 'Submission';

    [Scope('OnPrem')]
    procedure AssistEdit(OldElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        ElecTaxDeclarationHeader := Rec;
        ElecTaxDeclarationSetup.Get();
        Rec.TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(Rec.GetNoSeriesCode(), OldElecTaxDeclarationHeader."No. Series", ElecTaxDeclarationHeader."No. Series") then begin
            ElecTaxDeclarationHeader."No." := NoSeries.GetNextNo(ElecTaxDeclarationHeader."No. Series");
            Rec := ElecTaxDeclarationHeader;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure TestNoSeries()
    begin
        case "Declaration Type" of
            "Declaration Type"::"VAT Declaration":
                ElecTaxDeclarationSetup.TestField("VAT Declaration Nos.");
            "Declaration Type"::"ICP Declaration":
                ElecTaxDeclarationSetup.TestField("ICP Declaration Nos.");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetNoSeriesCode(): Code[20]
    begin
        case "Declaration Type" of
            "Declaration Type"::"VAT Declaration":
                exit(ElecTaxDeclarationSetup."VAT Declaration Nos.");
            "Declaration Type"::"ICP Declaration":
                exit(ElecTaxDeclarationSetup."ICP Declaration Nos.");
        end;
    end;

    local procedure UpdateDates()
    var
        ElecTaxDeclaration2: Record "Elec. Tax Declaration Header";
    begin
        if ("Declaration Year" = 0) or ("Declaration Period" = "Declaration Period"::" ") then begin
            "Declaration Period From Date" := 0D;
            "Declaration Period To Date" := 0D;
            exit;
        end;

        case "Declaration Period" of
            "Declaration Period"::January,
            "Declaration Period"::February,
            "Declaration Period"::March,
            "Declaration Period"::April,
            "Declaration Period"::May,
            "Declaration Period"::June,
            "Declaration Period"::July,
            "Declaration Period"::August,
            "Declaration Period"::September,
            "Declaration Period"::October,
            "Declaration Period"::November,
             "Declaration Period"::December:
                "Declaration Period From Date" := DMY2Date(1, "Declaration Period".AsInteger(), "Declaration Year");
            "Declaration Period"::"First Quarter", "Declaration Period"::Year, "Declaration Period"::"January-February":
                "Declaration Period From Date" := DMY2Date(1, 1, "Declaration Year");
            "Declaration Period"::"Second Quarter", "Declaration Period"::"April-May":
                "Declaration Period From Date" := DMY2Date(1, 4, "Declaration Year");
            "Declaration Period"::"Third Quarter", "Declaration Period"::"July-August":
                "Declaration Period From Date" := DMY2Date(1, 7, "Declaration Year");
            "Declaration Period"::"Fourth Quarter", "Declaration Period"::"October-November":
                "Declaration Period From Date" := DMY2Date(1, 10, "Declaration Year");
        end;

        OnAfterUpdateDeclarationPeriodFromDate(Rec);

        case "Declaration Period" of
            "Declaration Period"::January,
            "Declaration Period"::February,
            "Declaration Period"::March,
            "Declaration Period"::April,
            "Declaration Period"::May,
            "Declaration Period"::June,
            "Declaration Period"::July,
            "Declaration Period"::August,
            "Declaration Period"::September,
            "Declaration Period"::October,
            "Declaration Period"::November,
             "Declaration Period"::December:
                "Declaration Period To Date" := CalcDate('<+CM>', "Declaration Period From Date");
            "Declaration Period"::"First Quarter",
            "Declaration Period"::"Second Quarter",
            "Declaration Period"::"Third Quarter",
            "Declaration Period"::"Fourth Quarter":
                "Declaration Period To Date" := CalcDate('<+CQ>', "Declaration Period From Date");
            "Declaration Period"::Year:
                "Declaration Period To Date" := CalcDate('<+CY>', "Declaration Period From Date");
            "Declaration Period"::"January-February",
            "Declaration Period"::"April-May",
            "Declaration Period"::"July-August",
            "Declaration Period"::"October-November":
                "Declaration Period To Date" := CalcDate('<+1M + CM>', "Declaration Period From Date");
        end;

        OnAfterUpdateDeclarationPeriodToDate(Rec);

        if "Declaration Period To Date" >= Today then
            Error(Text008);

        if "Declaration Type" = "Declaration Type"::"VAT Declaration" then begin
            if (Date2DMY(Today, 2) > 8) and (Date2DMY(Today, 3) - "Declaration Year" = 1) then
                Error(Text009, FieldCaption("Declaration Year"), "Declaration Year", "Declaration Year" + 1);
            if Date2DMY(Today, 3) - "Declaration Year" > 1 then
                Error(Text009, FieldCaption("Declaration Year"), "Declaration Year", "Declaration Year" + 1);
        end;

        ElecTaxDeclaration2.Reset();
        ElecTaxDeclaration2.SetRange("Declaration Type", "Declaration Type");
        ElecTaxDeclaration2.SetFilter("No.", '<>%1', "No.");
        ElecTaxDeclaration2.SetRange("Declaration Year", "Declaration Year");
        ElecTaxDeclaration2.SetRange("Declaration Period", "Declaration Period");
        ElecTaxDeclaration2.SetFilter(Status, '<>%1', Status::Error);
        if ElecTaxDeclaration2.FindFirst() then
            if not Confirm(StrSubstNo(Text010, "Declaration Period", "Declaration Year")) then
                Error('');
    end;

    procedure InsertLine(LineType: Integer; IndentLevel: Integer; Name: Text[80]; Data: Text[250])
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclarationLine."Declaration Type" := "Declaration Type";
        ElecTaxDeclarationLine."Declaration No." := "No.";
        ElecTaxDeclarationLine."Line No." := 0;
        ElecTaxDeclarationLine."Line Type" := LineType;
        ElecTaxDeclarationLine."Indentation Level" := IndentLevel;
        ElecTaxDeclarationLine.Name := Name;
        ElecTaxDeclarationLine.Data := Data;
        ElecTaxDeclarationLine.Insert(true);
    end;

    procedure ClearLines()
    var
        ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclarationLine.SetRange("Declaration Type", "Declaration Type");
        ElecTaxDeclarationLine.SetRange("Declaration No.", "No.");
        ElecTaxDeclarationLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure DeleteLine(ElecTaxDeclarationLine: Record "Elec. Tax Declaration Line")
    var
        ElecTaxDeclarationLine2: Record "Elec. Tax Declaration Line";
    begin
        ElecTaxDeclarationLine2.SetRange("Declaration Type", ElecTaxDeclarationLine."Declaration Type");
        ElecTaxDeclarationLine2.SetRange("Declaration No.", ElecTaxDeclarationLine."Declaration No.");
        ElecTaxDeclarationLine2.SetRange("Parent Line No.", ElecTaxDeclarationLine."Line No.");
        if ElecTaxDeclarationLine2.Find('-') then
            repeat
                DeleteLine(ElecTaxDeclarationLine2);
            until ElecTaxDeclarationLine2.Next() = 0;
        ElecTaxDeclarationLine.Delete();
    end;

    procedure FormatDateTime(Date: Date; Time: Time): Text[20]
    begin
        exit(
          StrSubstNo('%1%2',
            Format(Date, 0, '<Year4><Month,2><Day,2>'),
            Format(Time, 0, '<Hour,2><Filler Character,0><Minute,2>')));
    end;

    [Scope('OnPrem')]
    procedure OnPreExport()
    begin
        if "Declaration Type" = "Declaration Type"::"ICP Declaration" then begin
            ElecTaxDeclarationLine.Reset();
            ElecTaxDeclarationLine.SetRange("Declaration Type", "Declaration Type");
            ElecTaxDeclarationLine.SetRange("Declaration No.", "No.");
            ElecTaxDeclarationLine.SetRange("Line Type", ElecTaxDeclarationLine."Line Type"::Element);
            ElecTaxDeclarationLine.SetFilter(Name, '%1|%2|%3', 'bd-t:IntraCommunitySupplies', 'bd-t:IntraCommunityServices',
              'bd-t:IntraCommunityABCSupplies');
            if not ElecTaxDeclarationLine.FindFirst() then
                Error(Text007, TableCaption(), FieldCaption("Declaration Type"), "Declaration Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDocType(): Text
    begin
        case "Declaration Type" of
            "Declaration Type"::"ICP Declaration":
                exit('ICP');
            "Declaration Type"::"VAT Declaration":
                exit('Omzetbelasting');
        end;
        Error(UnknownDeclTypeErr, "Declaration Type");
    end;

    procedure DownloadGeneratedSubmissionMessage()
    var
        LocalElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        SubmitElecTaxDeclaration: Report "Submit Elec. Tax Declaration";
        EnvironmentInformation: Codeunit "Environment Information";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        LocalElecTaxDeclarationHeader := Rec;
        LocalElecTaxDeclarationHeader.SetRecFilter();
        SubmitElecTaxDeclaration.SetTableView(LocalElecTaxDeclarationHeader);
        SubmitElecTaxDeclaration.UseRequestPage(EnvironmentInformation.IsSaaS());
        SubmitElecTaxDeclaration.SetGenerateSubmissionMessageOnly();
        SubmitElecTaxDeclaration.RunModal();
        Find();
        CalcFields("Submission Message BLOB");
        if "Submission Message BLOB".HasValue() then
            if ConfirmManagement.GetResponse(DownloadSubmissionMessageQst, false) then
                DownloadSubmissionMessage();
    end;

    procedure DownloadSubmissionMessage()
    var
        TempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        ServerFileInStream: InStream;
        ZipOutStream: OutStream;
        ZipInStream: InStream;
        ZipFileName: Text;
    begin
        if not "Submission Message BLOB".HasValue() then
            Error(NoSubmissionMessageAvailableErr);

        CalcFields("Submission Message BLOB");
        TempBlob.FromRecord(Rec, Fieldno("Submission Message BLOB"));

        DataCompression.CreateZipArchive();
        TempBlob.CreateInStream(ServerFileInStream);
        ZipFileName := SubmissionFileNameTxt + '.xbrl';
        DataCompression.AddEntry(ServerFileInStream, ZipFileName);
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        FileManagement.DownloadFromStreamHandler(ZipInStream, '', '', '', SubmissionFileNameTxt + '.zip');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDeclarationPeriodFromDate(var ElecTaxDeclaration: Record "Elec. Tax Declaration Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDeclarationPeriodToDate(var ElecTaxDeclaration: Record "Elec. Tax Declaration Header")
    begin
    end;
}
