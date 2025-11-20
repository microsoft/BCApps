// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Environment;
using System.IO;

report 91 "Export Consolidation"
{
    ApplicationArea = Suite;
    Caption = 'Export Consolidation';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = field("No.");
                DataItemTableView = sorting("G/L Account No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, "Posting Date");
                    SetRange("Posting Date", "Posting Date");
                    OnBeforeGLEntryOnAfterGetRecord("G/L Entry", TempSelectedDim);

                    if not TempSelectedDim.FindFirst() then begin
                        CalcSums(
                          Amount, "Debit Amount", "Credit Amount",
                          "Add.-Currency Debit Amount", "Add.-Currency Credit Amount");
                        if (Amount <> 0) or ("Debit Amount" <> 0) or ("Credit Amount" <> 0) then begin
                            TempGLEntry.Reset();
                            TempGLEntry.DeleteAll();
                            TempDimBufOut.Reset();
                            TempDimBufOut.DeleteAll();
                            TempGLEntry := "G/L Entry";
                            TempGLEntry.Insert();
                            case FileFormat of
                                FileFormat::"Version F&O":
                                    ExportFOConsolidation.InsertGLEntry(TempGLEntry);
                                FileFormat::"Version 4.00 or Later (.xml)":
                                    Consolidate.InsertGLEntry(TempGLEntry);
                                FileFormat::"Version 3.70 or Earlier (.txt)":
                                    begin
                                        UpdateExportedInfo(TempGLEntry);
                                        WriteFile(TempGLEntry, TempDimBufOut);
                                    end;
                            end;
                        end;
                        Find('+');
                    end else begin
                        TempGLEntry.Reset();
                        TempGLEntry.DeleteAll();
                        DimBufMgt.DeleteAllDimensions();
                        repeat
                            TempDimBufIn.Reset();
                            TempDimBufIn.DeleteAll();
                            DimSetEntry.Reset();
                            DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                            if DimSetEntry.FindSet() then
                                repeat
                                    if TempSelectedDim.Get(UserId, 3, REPORT::"Export Consolidation", '', DimSetEntry."Dimension Code") then begin
                                        TempDimBufIn.Init();
                                        TempDimBufIn."Table ID" := DATABASE::"G/L Entry";
                                        TempDimBufIn."Entry No." := "Entry No.";
                                        if TempDim.Get(DimSetEntry."Dimension Code") then
                                            if TempDim."Consolidation Code" <> '' then
                                                TempDimBufIn."Dimension Code" := TempDim."Consolidation Code"
                                            else
                                                TempDimBufIn."Dimension Code" := TempDim.Code
                                        else
                                            TempDimBufIn."Dimension Code" := DimSetEntry."Dimension Code";
                                        if TempDimVal.Get(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code") then
                                            if TempDimVal."Consolidation Code" <> '' then
                                                TempDimBufIn."Dimension Value Code" := TempDimVal."Consolidation Code"
                                            else
                                                TempDimBufIn."Dimension Value Code" := TempDimVal.Code
                                        else
                                            TempDimBufIn."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                                        TempDimBufIn.Insert();
                                    end;
                                until DimSetEntry.Next() = 0;
                            UpdateTempGLEntry(TempDimBufIn);
                        until Next() = 0;

                        TempGLEntry.Reset();
                        if TempGLEntry.FindSet() then
                            repeat
                                TempDimBufOut.Reset();
                                TempDimBufOut.DeleteAll();
                                DimBufMgt.GetDimensions(TempGLEntry."Entry No.", TempDimBufOut);
                                TempDimBufOut.SetRange("Entry No.", TempGLEntry."Entry No.");
                                case FileFormat of
                                    FileFormat::"Version 4.00 or Later (.xml)",
                                    FileFormat::"Version F&O":
                                        if (TempGLEntry."Debit Amount" <> 0) or (TempGLEntry."Credit Amount" <> 0) then
                                            WriteFile(TempGLEntry, TempDimBufOut);
                                    FileFormat::"Version 3.70 or Earlier (.txt)":
                                        begin
                                            UpdateExportedInfo(TempGLEntry);
                                            if TempGLEntry.Amount <> 0 then
                                                WriteFile(TempGLEntry, TempDimBufOut);
                                        end;
                                end;
                            until TempGLEntry.Next() = 0;
                    end;

                    SetRange("Posting Date", ConsolidStartDate, ConsolidEndDate);

                    OnAfterGLEntryOnAfterGetRecord("G/L Entry", TempSelectedDim);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", ConsolidStartDate, ConsolidEndDate);

                    TempDimBufIn.SetRange("Table ID", DATABASE::"G/L Entry");
                    TempDimBufOut.SetRange("Table ID", DATABASE::"G/L Entry");

                    if ConsolidStartDate = NormalDate(ConsolidStartDate) then
                        CheckClosingPostings("G/L Account"."No.", ConsolidStartDate, ConsolidEndDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                Window.Update(2, '');
                case FileFormat of
                    FileFormat::"Version 4.00 or Later (.xml)":
                        Consolidate.InsertGLAccount("G/L Account");
                    FileFormat::"Version F&O":
                        ExportFOConsolidation.ProcessGLBugdetEntries("No.", ConsolidStartDate, ConsolidEndDate);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if FileFormat = FileFormat::"Version 3.70 or Earlier (.txt)" then
                    GLEntryFile.Close();
            end;

            trigger OnPreDataItem()
            begin
                if ServerFileName = '' then
                    Error(Text000);
                if ConsolidStartDate = 0D then
                    Error(Text001);
                if ConsolidEndDate = 0D then
                    Error(Text002);

                CheckClosingDates(ConsolidStartDate, ConsolidEndDate, TransferPerDay);

                if NormalDate(ConsolidEndDate) - NormalDate(ConsolidStartDate) + 1 > 500 then
                    Error(Text003);

                if Dim.Find('-') then
                    repeat
                        TempDim.Init();
                        TempDim := Dim;
                        TempDim.Insert();
                    until Dim.Next() = 0;

                if DimVal.Find('-') then
                    repeat
                        TempDimVal.Init();
                        TempDimVal := DimVal;
                        TempDimVal.Insert();
                    until DimVal.Next() = 0;

                SelectedDim.SetRange("User ID", UserId);
                SelectedDim.SetRange("Object Type", 3);
                SelectedDim.SetRange("Object ID", REPORT::"Export Consolidation");
                if SelectedDim.Find('-') then
                    repeat
                        TempSelectedDim.Init();
                        TempSelectedDim := SelectedDim;
                        TempDim.SetRange("Consolidation Code", SelectedDim."Dimension Code");
                        if TempDim.FindFirst() then
                            TempSelectedDim."Dimension Code" := TempDim.Code;
                        TempSelectedDim.Insert();
                    until SelectedDim.Next() = 0;
                TempDim.Reset();

                if FileFormat = FileFormat::"Version 3.70 or Earlier (.txt)" then begin
                    Clear(GLEntryFile);
                    GLEntryFile.TextMode := true;
                    GLEntryFile.WriteMode := true;
                    GLEntryFile.Create(ServerFileName, TEXTENCODING::UTF8);
                    GLEntryFile.Write(
                      StrSubstNo(
                        '<01>#1############################ #2####### #3####### #4#',
                        CompanyName, ConsolidStartDate, ConsolidEndDate, Format(TransferPerDay, 0, 2)));
                end;

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006);
            end;
        }
        dataitem("Currency Exchange Rate"; "Currency Exchange Rate")
        {
            DataItemTableView = sorting("Currency Code", "Starting Date");

            trigger OnAfterGetRecord()
            begin
                Consolidate.InsertExchRate("Currency Exchange Rate");
            end;

            trigger OnPostDataItem()
            begin
                case FileFormat of
                    FileFormat::"Version 4.00 or Later (.xml)":
                        begin
                            Consolidate.SetGlobals(
                              ProductVersion, FormatVersion, CompanyName,
                              GLSetup."LCY Code", GLSetup."Additional Reporting Currency", ParentCurrencyCode,
                              0, ConsolidStartDate, ConsolidEndDate);
                            Consolidate.SetGlobals(
                              ProductVersion, FormatVersion, CompanyName,
                              GLSetup."LCY Code", GLSetup."Additional Reporting Currency", ParentCurrencyCode,
                              Consolidate.CalcCheckSum(), ConsolidStartDate, ConsolidEndDate);
                            Consolidate.ExportToXML(ServerFileName);
                        end;
                    FileFormat::"Version F&O":
                        ExportFOConsolidation.ExportFile(ServerFileName);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if FileFormat = FileFormat::"Version 3.70 or Earlier (.txt)" then
                    CurrReport.Break();
                GLSetup.Get();
                if GLSetup."Additional Reporting Currency" = '' then
                    SetRange("Currency Code", ParentCurrencyCode)
                else
                    SetFilter("Currency Code", '%1|%2', ParentCurrencyCode, GLSetup."Additional Reporting Currency");
                SetRange("Starting Date", 0D, ConsolidEndDate);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
                        OptionCaption = 'Version 4.00 or Later (.xml),Version 3.70 or Earlier (.txt),Dynamics 365 Finance (.txt)';
                        ToolTip = 'Specifies the file format that you want to use for the consolidation. If the parent company that will perform the consolidation also has Dynamics NAV 4.0 or later versions, select the .xml format. Otherwise, select the .txt format.';

                        trigger OnValidate()
                        begin
                            SetControlsVisibility();
                        end;
                    }
                    field(ClientFileNameControl; ClientFileName)
                    {
                        ApplicationArea = Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name of the file to be exported from a business unit to a consolidated company.';
                    }
                    group("Consolidation Period")
                    {
                        Caption = 'Consolidation Period';
                        field(StartDate; ConsolidStartDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Starting Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the first date in the period from which entries will be exported. If you use a closing date, the starting date and ending date must be the same.';
                        }
                        field(EndDate; ConsolidEndDate)
                        {
                            ApplicationArea = Suite;
                            Caption = 'Ending Date';
                            ClosingDates = true;
                            ToolTip = 'Specifies the last date in the period from which entries will be exported.';
                        }
                    }
                    group("Copy Field Contents")
                    {
                        Caption = 'Copy Field Contents';
                        field(ColumnDim; ColumnDim)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Copy Dimensions';
                            Editable = false;
                            ToolTip = 'Specifies if you want the entries to be classified by dimensions when they are transferred.';

                            trigger OnAssistEdit()
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Export Consolidation", ColumnDim);
                            end;
                        }
                    }
                    field(ParentCurrencyCode; ParentCurrencyCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Parent Currency Code';
                        TableRelation = Currency;
                        ToolTip = 'Specifies the currency code of the company that will perform the consolidation.';
                    }
                    group("Legal Entity ID")
                    {
                        ShowCaption = false;
                        Visible = FOLegalEntityIDVisible;
                        field("F&O Legal Entity ID"; FOLegalEntityID)
                        {
                            ApplicationArea = Suite;
                            Caption = 'F&&O Legal Entity ID';
                            ToolTip = 'Specifies the F&O Legal Entity ID of the company that will perform the consolidation.';
                            Enabled = true;
                            ShowMandatory = true;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            FOLegalEntityIDVisible := false;
        end;

        trigger OnOpenPage()
        begin
            SetControlsVisibility();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        TransferPerDay := true;
    end;

    trigger OnPostReport()
    var
        FileManagement: Codeunit "File Management";
    begin
        if IsWebClient() then begin
            if FileFormat = FileFormat::"Version 4.00 or Later (.xml)" then
                ClientFileName := ClientFileName + '.xml'
            else
                ClientFileName := ClientFileName + '.txt';

            FileManagement.DownloadHandler(ServerFileName, '', '', '', ClientFileName);
        end else
            FileManagement.DownloadHandler(ServerFileName, '', '', '', ClientFileName);
    end;

    trigger OnPreReport()
    var
        FileMgt: Codeunit "File Management";
    begin
        DimSelectionBuf.CompareDimText(3, REPORT::"Export Consolidation", '', ColumnDim, Text007);
        ServerFileName := FileMgt.ServerTempFileName('xml');
        IsWebClient();

        if FileFormat = FileFormat::"Version F&O" then begin
            if FOLegalEntityID = '' then
                Error(LegalEntityIDEmptyErr);
            ExportFOConsolidation.SetFOLegalEntityID(FOLegalEntityID);
        end;
    end;

    var
        TempGLEntry: Record "G/L Entry" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        Dim: Record Dimension;
        DimVal: Record "Dimension Value";
        TempDim: Record Dimension temporary;
        TempDimVal: Record "Dimension Value" temporary;
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        TempDimBufIn: Record "Dimension Buffer" temporary;
        TempDimBufOut: Record "Dimension Buffer" temporary;
        DimSelectionBuf: Record "Dimension Selection Buffer";
        GLSetup: Record "General Ledger Setup";
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Consolidate: Codeunit Consolidate;
        ExportFOConsolidation: Codeunit "Export F/O Consolidation";
        ClientTypeManagement: Codeunit "Client Type Management";
        Window: Dialog;
        GLEntryFile: File;
        ServerFileName: Text;
        FileFormat: Option "Version 4.00 or Later (.xml)","Version 3.70 or Earlier (.txt)","Version F&O";
        ConsolidStartDate: Date;
        ConsolidEndDate: Date;
        TransferPerDay: Boolean;
        TransferPerDayReq: Boolean;
        FOLegalEntityIDVisible: Boolean;
        ColumnDim: Text[250];
        ParentCurrencyCode: Code[10];
        FOLegalEntityID: Code[4];
        ClientFileName: Text;

#pragma warning disable AA0074
        ProductVersion: Label '4.00';
        FormatVersion: Label '1.00';
        Text000: Label 'Enter the file name.';
        Text001: Label 'Enter the starting date for the consolidation period.';
        Text002: Label 'Enter the ending date for the consolidation period.';
        Text003: Label 'The export can include a maximum of 500 days.';
        Text004: Label 'Processing the chart of accounts...\\';
#pragma warning disable AA0470
        Text005: Label 'No.             #1##########\';
        Text006: Label 'Date            #2######';
#pragma warning restore AA0470
        Text007: Label 'Copy Dimensions';
#pragma warning disable AA0470
        Text009: Label 'A G/L Entry with posting date on a closing date (%1) was found while exporting nonclosing entries. G/L Account No. = %2.';
#pragma warning restore AA0470
        Text010: Label 'When using closing dates, the starting and ending dates must be the same.';
#pragma warning restore AA0074
        LegalEntityIDEmptyErr: Label 'You must provide a value in the F&O Legal Entity ID field.';

    local procedure WriteFile(var GLEntry2: Record "G/L Entry"; var DimBuf: Record "Dimension Buffer")
    var
        GLEntryNo: Integer;
    begin
        case FileFormat of
            FileFormat::"Version 4.00 or Later (.xml)":
                GLEntryNo := Consolidate.InsertGLEntry(GLEntry2);
            FileFormat::"Version F&O":
                GLEntryNo := ExportFOConsolidation.InsertGLEntry(GLEntry2);
            FileFormat::"Version 3.70 or Earlier (.txt)":
                GLEntryFile.Write(
                  StrSubstNo(
                    '<02>#1################## #2####### #3####################',
                    GLEntry2."G/L Account No.",
                    GLEntry2."Posting Date",
                    GLEntry2.Amount));
        end;

        if DimBuf.Find('-') then
            repeat
                case FileFormat of
                    FileFormat::"Version 4.00 or Later (.xml)":
                        Consolidate.InsertEntryDim(DimBuf, GLEntryNo);
                    FileFormat::"Version F&O":
                        ExportFOConsolidation.InsertEntryDim(DimBuf, GLEntryNo);
                    FileFormat::"Version 3.70 or Earlier (.txt)":
                        GLEntryFile.Write(
                          StrSubstNo(
                            '<03>#1################## #2##################',
                            DimBuf."Dimension Code",
                            DimBuf."Dimension Value Code"));
                end;
            until DimBuf.Next() = 0;
    end;

    local procedure UpdateTempGLEntry(var TempDimBuf: Record "Dimension Buffer" temporary)
    var
        DimEntryNo: Integer;
    begin
        DimEntryNo := DimBufMgt.FindDimensions(TempDimBuf);
        if (not TempDimBuf.IsEmpty) and (DimEntryNo = 0) then begin
            TempGLEntry := "G/L Entry";
            TempGLEntry."Entry No." := DimBufMgt.InsertDimensions(TempDimBuf);
            TempGLEntry.Insert();
        end else
            if TempGLEntry.Get(DimEntryNo) then begin
                TempGLEntry.Amount := TempGLEntry.Amount + "G/L Entry".Amount;
                TempGLEntry."Debit Amount" := TempGLEntry."Debit Amount" + "G/L Entry"."Debit Amount";
                TempGLEntry."Credit Amount" := TempGLEntry."Credit Amount" + "G/L Entry"."Credit Amount";
                TempGLEntry."Additional-Currency Amount" :=
                  TempGLEntry."Additional-Currency Amount" + "G/L Entry"."Additional-Currency Amount";
                TempGLEntry."Add.-Currency Debit Amount" :=
                  TempGLEntry."Add.-Currency Debit Amount" + "G/L Entry"."Add.-Currency Debit Amount";
                TempGLEntry."Add.-Currency Credit Amount" :=
                  TempGLEntry."Add.-Currency Credit Amount" + "G/L Entry"."Add.-Currency Credit Amount";
                TempGLEntry.Modify();
            end else begin
                TempGLEntry := "G/L Entry";
                TempGLEntry."Entry No." := DimEntryNo;
                TempGLEntry.Insert();
            end;
    end;

    local procedure UpdateExportedInfo(var GLEntry3: Record "G/L Entry")
    begin
        if GLEntry3.Amount < 0 then begin
            "G/L Account".TestField("Consol. Credit Acc.");
            GLEntry3."G/L Account No." := "G/L Account"."Consol. Credit Acc.";
        end else begin
            "G/L Account".TestField("Consol. Debit Acc.");
            GLEntry3."G/L Account No." := "G/L Account"."Consol. Debit Acc.";
        end;
        GLEntry3.Modify();
    end;

    local procedure CheckClosingPostings(GLAccNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        GLEntry: Record "G/L Entry";
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetCurrentKey("New Fiscal Year", "Date Locked");
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Date Locked", true);
        AccountingPeriod.SetRange("Starting Date", StartDate + 1, EndDate);
        if AccountingPeriod.Find('-') then begin
            GLEntry.SetRange("G/L Account No.", GLAccNo);
            repeat
                GLEntry.SetRange("Posting Date", ClosingDate(AccountingPeriod."Starting Date" - 1));
                if not GLEntry.IsEmpty() then
                    Error(
                      Text009,
                      GLEntry.GetFilter("Posting Date"),
                      GLAccNo);
            until AccountingPeriod.Next() = 0;
        end;
    end;

    local procedure CheckClosingDates(StartDate: Date; EndDate: Date; var TransferPerDay: Boolean)
    begin
        if (StartDate = ClosingDate(StartDate)) or
           (EndDate = ClosingDate(EndDate))
        then begin
            if StartDate <> EndDate then
                Error(Text010);
            TransferPerDay := false;
        end else
            TransferPerDay := TransferPerDayReq;
    end;

    procedure InitializeRequest(NewFileFormat: Option; NewFileName: Text)
    begin
        FileFormat := NewFileFormat;
        ClientFileName := NewFileName;
        ColumnDim := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Export Consolidation", '');
    end;

    local procedure IsWebClient(): Boolean
    begin
        exit(ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop]);
    end;

    local procedure SetControlsVisibility()
    begin
        FOLegalEntityIDVisible := FileFormat = FileFormat::"Version F&O";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGLEntryOnAfterGetRecord(var GLEntry: Record "G/L Entry"; var TempSelectedDim: Record "Selected Dimension" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLEntryOnAfterGetRecord(var GLEntry: Record "G/L Entry"; var TempSelectedDim: Record "Selected Dimension" temporary)
    begin
    end;
}

