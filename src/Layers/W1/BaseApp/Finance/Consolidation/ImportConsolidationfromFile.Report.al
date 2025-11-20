// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Environment;
using System.IO;
using System.Utilities;

report 92 "Import Consolidation from File"
{
    Caption = 'Import Consolidation from File';
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));

            trigger OnAfterGetRecord()
            begin
                "Consol. Debit Acc." := "No.";
                "Consol. Credit Acc." := "No.";
                "Consol. Translation Method" := "Consol. Translation Method"::"Average Rate (Manual)";
                Consolidate.InsertGLAccount("G/L Account");
            end;

            trigger OnPostDataItem()
            var
                TempGLEntry: Record "G/L Entry" temporary;
                TempDimBuf: Record "Dimension Buffer" temporary;
            begin
                if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then
                    CurrReport.Break();

                // Import G/L entries
                while GLEntryFile.Pos <> GLEntryFile.Len do begin
                    GLEntryFile.Read(TextLine);
                    case CopyStr(TextLine, 1, 4) of
                        '<02>':
                            begin
                                TempGLEntry.Init();
                                Evaluate(TempGLEntry."G/L Account No.", CopyStr(TextLine, 5, 20));
                                Evaluate(TempGLEntry."Posting Date", CopyStr(TextLine, 26, 9));
                                Evaluate(TempGLEntry.Amount, CopyStr(TextLine, 36, 22));
                                if TempGLEntry.Amount > 0 then
                                    TempGLEntry."Debit Amount" := TempGLEntry.Amount
                                else
                                    TempGLEntry."Credit Amount" := -TempGLEntry.Amount;
                                TempGLEntry."Entry No." := Consolidate.InsertGLEntry(TempGLEntry);
                            end;
                        '<03>':
                            begin
                                TempDimBuf.Init();
                                TempDimBuf."Table ID" := DATABASE::"G/L Entry";
                                TempDimBuf."Entry No." := TempGLEntry."Entry No.";
                                TempDimBuf."Dimension Code" := CopyStr(TextLine, 5, 20);
                                TempDimBuf."Dimension Value Code" := CopyStr(TextLine, 26, 20);
                                Consolidate.InsertEntryDim(TempDimBuf, TempDimBuf."Entry No.");
                            end;
                    end;
                end;

                Consolidate.SelectAllImportedDimensions();
            end;

            trigger OnPreDataItem()
            begin
                if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FileFormat; FileFormat)
                    {
                        ApplicationArea = Suite;
                        Caption = 'File Format';
                        ToolTip = 'Specifies the format of the file that you want to use for consolidation.';
                    }
                    field(FileNameControl; FileName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name of the file that you want to use for consolidation.';

                        trigger OnAssistEdit()
                        var
                            FileManagement: Codeunit "File Management";
                            ClientTypeMgt: Codeunit "Client Type Management";
                        begin
                            FilePath := FileManagement.UploadFile(Text031, FileName);
                            if ClientTypeMgt.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop] then
                                ServerFileName := FilePath;
                            FileName := GetFileName(FilePath);
                        end;
                    }
                    field(GLDocNo; GLDocNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number to be used on all new ledger entries created from the consolidation.';
                    }
                }
            }
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
        if FileFormat = FileFormat::"Version 3.70 or Earlier (.txt)" then
            Consolidate.SetGlobals(
              '', '', BusUnit."Company Name",
              SubsidCurrencyCode, AdditionalCurrencyCode, ParentCurrencyCode,
              0, ConsolidStartDate, ConsolidEndDate);

        Consolidate.UpdateGLEntryDimSetID();
        Consolidate.SetDocNo(GLDocNo);
        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then
            Consolidate.SetGenJnlBatch(GenJnlBatch);
        Consolidate.Run(BusUnit);
    end;

    trigger OnPreReport()
    var
        BusUnit2: Record "Business Unit";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if GLDocNo = '' then
            Error(Text015);

        if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then begin
            Consolidate.ImportFromXML(ServerFileName);
            Consolidate.GetGlobals(
              ProductVersion, FormatVersion, BusUnit."Company Name",
              SubsidCurrencyCode, AdditionalCurrencyCode, ParentCurrencyCode,
              CheckSum, ConsolidStartDate, ConsolidEndDate);
            CalculatedCheckSum := Consolidate.CalcCheckSum();
            if CheckSum <> CalculatedCheckSum then
                Error(Text036, CheckSum, CalculatedCheckSum);
            TransferPerDay := true;
        end else begin
            Clear(GLEntryFile);
            GLEntryFile.TextMode := true;
            GLEntryFile.Open(ServerFileName);
            GLEntryFile.Read(TextLine);
            if CopyStr(TextLine, 1, 4) = '<01>' then begin
                BusUnit."Company Name" := DelChr(CopyStr(TextLine, 5, 30), '>');
                Evaluate(ConsolidStartDate, CopyStr(TextLine, 36, 9));
                Evaluate(ConsolidEndDate, CopyStr(TextLine, 46, 9));
                Evaluate(TransferPerDay, CopyStr(TextLine, 56, 3));
            end;
        end;

        if (BusUnit."Company Name" = '') or (ConsolidStartDate = 0D) or (ConsolidEndDate = 0D) then
            Error(Text001);

        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text023, ConsolidStartDate, ConsolidEndDate), true)
        then
            CurrReport.Quit();

        BusUnit.SetCurrentKey("Company Name");
        BusUnit.SetRange("Company Name", BusUnit."Company Name");
        BusUnit.Find('-');
        if BusUnit.Next() <> 0 then
            Error(
              Text005 +
              Text006,
              BusUnit.FieldCaption("Company Name"), BusUnit."Company Name");
        BusUnit.TestField(Consolidate, true);

        BusUnit2."File Format" := FileFormat;
        if BusUnit."File Format" <> FileFormat then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   FileFormatQst, BusUnit.FieldCaption("File Format"), BusUnit2."File Format",
                   BusUnit.TableCaption(), BusUnit."File Format"), true)
            then
                CurrReport.Quit();

        if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then begin
            if SubsidCurrencyCode = '' then
                SubsidCurrencyCode := BusUnit."Currency Code";
            GLSetup.GetRecordOnce();
            if (SubsidCurrencyCode <> BusUnit."Currency Code") and
               (SubsidCurrencyCode <> GLSetup."LCY Code") and
               not ((BusUnit."Currency Code" = '') and (GLSetup."LCY Code" = ''))
            then
                Error(
                  Text002,
                  BusUnit.FieldCaption("Currency Code"), SubsidCurrencyCode,
                  BusUnit.TableCaption(), BusUnit."Currency Code");
        end else begin
            SubsidCurrencyCode := BusUnit."Currency Code";
            Window.Open(
              '#1###############################\\' +
              Text024 +
              Text025 +
              Text026);
            Window.Update(1, Text027);
            Window.Update(2, BusUnit.Code);
            Window.Update(3, '');
        end;
    end;

    var
        BusUnit: Record "Business Unit";
        GLSetup: Record "General Ledger Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        Consolidate: Codeunit Consolidate;
        Window: Dialog;
        GLEntryFile: File;
        FileName: Text;
        FilePath: Text;
        FileFormat: Enum "Business Unit File Format";
        TextLine: Text[250];
        GLDocNo: Code[20];
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        TransferPerDay: Boolean;
        CheckSum: Decimal;
        CalculatedCheckSum: Decimal;
        ParentCurrencyCode: Code[10];
        SubsidCurrencyCode: Code[10];
        AdditionalCurrencyCode: Code[10];
        ProductVersion: Code[10];
        FormatVersion: Code[10];
        ServerFileName: Text;

#pragma warning disable AA0074
        Text001: Label 'The file to be imported has an unknown format.';
#pragma warning disable AA0470
        Text002: Label 'The %1 in the file to be imported (%2) does not match the %1 in the %3 (%4).';
        Text005: Label 'The business unit %1 %2 is not unique.\\';
        Text006: Label 'Delete %1 in the extra records.';
#pragma warning restore AA0470
        Text015: Label 'Enter a document number.';
#pragma warning disable AA0470
        Text023: Label 'Do you want to consolidate in the period from %1 to %2?';
        Text024: Label 'Business Unit Code   #2##########\';
        Text025: Label 'G/L Account No.      #3##########\';
        Text026: Label 'Date                 #4######';
#pragma warning restore AA0470
        Text027: Label 'Reading File...';
        Text031: Label 'Import from File';
#pragma warning disable AA0470
        Text036: Label 'Imported checksum (%1) does not equal the calculated checksum (%2). The file may be corrupt.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FileFormatQst: Label 'The entered %1, %2, does not equal the %1 on this %3, %4.\Do you want to continue?', Comment = '%1 - field caption, %2 - field value, %3 - table captoin, %4 - field value';

    procedure SetParameters(NewFileFormat: Enum "Business Unit File Format"; NewFilePath: Text; NewGLDocNo: Code[20])
    begin
        FileFormat := NewFileFormat;
        FilePath := NewFilePath;
        FileName := GetFileName(FilePath);
        GLDocNo := NewGLDocNo;
    end;

#if not CLEAN26
    [Obsolete('Replaced by procedure SetParameters()', '26.0')]
    procedure InitializeRequest(NewFileFormat: Option; NewFilePath: Text; NewGLDocNo: Code[20])
    begin
        FileFormat := "Business Unit File Format".FromInteger(NewFileFormat);
        FilePath := NewFilePath;
        FileName := GetFileName(FilePath);
        GLDocNo := NewGLDocNo;
    end;
#endif

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    local procedure GetFileName(FilePath: Text): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        exit(FileManagement.GetFileName(FilePath));
    end;
}

