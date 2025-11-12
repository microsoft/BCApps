// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;
using System.Environment;
using System.Utilities;

report 5692 "Calculate Depreciation"
{
    AdditionalSearchTerms = 'write down fixed asset';
    ApplicationArea = FixedAssets;
    Caption = 'Calculate Depreciation';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";

            trigger OnAfterGetRecord()
            begin
                if Inactive or Blocked then
                    CurrReport.Skip();

                OnBeforeCalculateDepreciation(
                    "No.", TempGenJnlLine, TempFAJnlLine, DeprAmount, NumberOfDays, DeprBookCode, DeprUntilDate, EntryAmounts, DaysInPeriod);

                CalculateDepr.Calculate(
                    DeprAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays, "No.", DeprBookCode, DeprUntilDate, EntryAmounts, 0D, DaysInPeriod);
                if GuiAllowed() then
                    if (DeprAmount <> 0) or (Custom1Amount <> 0) then
                        Window.Update(1, "No.")
                    else
                        Window.Update(2, "No.");

                Custom1Amount := Round(Custom1Amount, GeneralLedgerSetup."Amount Rounding Precision");
                DeprAmount := Round(DeprAmount, GeneralLedgerSetup."Amount Rounding Precision");

                OnAfterCalculateDepreciation(
                    "No.", TempGenJnlLine, TempFAJnlLine, DeprAmount, NumberOfDays, DeprBookCode, DeprUntilDate, EntryAmounts, DaysInPeriod);

                if Custom1Amount <> 0 then
                    if not DeprBook."G/L Integration - Custom 1" or "Budgeted Asset" then begin
                        TempFAJnlLine."FA No." := "No.";
                        TempFAJnlLine."FA Posting Type" := TempFAJnlLine."FA Posting Type"::"Custom 1";
                        TempFAJnlLine.Amount := Custom1Amount;
                        TempFAJnlLine."No. of Depreciation Days" := Custom1NumberOfDays;
                        TempFAJnlLine."FA Error Entry No." := Custom1ErrorNo;
                        TempFAJnlLine."Line No." := TempFAJnlLine."Line No." + 1;
                        TempFAJnlLine.Insert();
                    end else begin
                        TempGenJnlLine."Account No." := "No.";
                        TempGenJnlLine."FA Posting Type" := TempGenJnlLine."FA Posting Type"::"Custom 1";
                        TempGenJnlLine.Amount := Custom1Amount;
                        TempGenJnlLine."No. of Depreciation Days" := Custom1NumberOfDays;
                        TempGenJnlLine."FA Error Entry No." := Custom1ErrorNo;
                        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
                        TempGenJnlLine.Insert();
                    end;

                if DeprAmount <> 0 then
                    if not DeprBook."G/L Integration - Depreciation" or "Budgeted Asset" then begin
                        TempFAJnlLine."FA No." := "No.";
                        TempFAJnlLine."FA Posting Type" := TempFAJnlLine."FA Posting Type"::Depreciation;
                        TempFAJnlLine.Amount := DeprAmount;
                        TempFAJnlLine."No. of Depreciation Days" := NumberOfDays;
                        TempFAJnlLine."FA Error Entry No." := ErrorNo;
                        TempFAJnlLine."Line No." := TempFAJnlLine."Line No." + 1;
                        TempFAJnlLine.Insert();
                    end else begin
                        TempGenJnlLine."Account No." := "No.";
                        TempGenJnlLine."FA Posting Type" := TempGenJnlLine."FA Posting Type"::Depreciation;
                        TempGenJnlLine.Amount := DeprAmount;
                        TempGenJnlLine."No. of Depreciation Days" := NumberOfDays;
                        TempGenJnlLine."FA Error Entry No." := ErrorNo;
                        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
                        TempGenJnlLine.Insert();
                    end;
            end;

            trigger OnPostDataItem()
            var
                NeedCommit: Boolean;
            begin
                if TempFAJnlLine.Find('-') then begin
                    NeedCommit := true;
                    FAJnlLine.LockTable();
                    FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
                    NoSeries := FAJnlSetup.GetFANoSeries(FAJnlLine);
                    if DocumentNo = '' then
                        if FAJnlLine.FindLast() then
                            AutoDocumentNo := FAJnlLine."Document No."
                        else
                            AutoDocumentNo := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, DeprUntilDate, true)
                    else
                        AutoDocumentNo := DocumentNo;
                end;
                if TempFAJnlLine.Find('-') then
                    repeat
                        FAJnlLine.Init();
                        OnPostFixedAssetOnAfterFAJnlLineInit(TempFAJnlLine, FAJnlLine, DocumentNo, AutoDocumentNo);
                        FAJnlLine."Line No." := 0;
                        FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                        LineNo := LineNo + 1;
                        if GuiAllowed() then
                            Window.Update(3, LineNo);
                        FAJnlLine."Posting Date" := PostingDate;
                        FAJnlLine."FA Posting Date" := DeprUntilDate;
                        if FAJnlLine."Posting Date" = FAJnlLine."FA Posting Date" then
                            FAJnlLine."Posting Date" := 0D;
                        FAJnlLine."FA Posting Type" := TempFAJnlLine."FA Posting Type";
                        FAJnlLine.Validate("FA No.", TempFAJnlLine."FA No.");
                        FAJnlLine."Document No." := AutoDocumentNo;
                        FAJnlLine."Posting No. Series" := NoSeries;
                        FAJnlLine.Description := PostingDescription;
                        FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                        FAJnlLine.Validate(Amount, TempFAJnlLine.Amount);
                        FAJnlLine."No. of Depreciation Days" := TempFAJnlLine."No. of Depreciation Days";
                        FAJnlLine."FA Error Entry No." := TempFAJnlLine."FA Error Entry No.";
                        FAJnlNextLineNo := FAJnlNextLineNo + 10000;
                        FAJnlLine."Line No." := FAJnlNextLineNo;
                        OnBeforeFAJnlLineInsert(TempFAJnlLine, FAJnlLine);
                        FAJnlLine.Insert(true);
                        FAJnlLineCreatedCount += 1;
                    until TempFAJnlLine.Next() = 0;

                if TempGenJnlLine.Find('-') then begin
                    NeedCommit := true;
                    GenJnlLine.LockTable();
                    FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
                    NoSeries := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                    if DocumentNo = '' then
                        if GenJnlLine.FindLast() then
                            AutoDocumentNo := GenJnlLine."Document No."
                        else
                            AutoDocumentNo := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, DeprUntilDate, true)
                    else
                        AutoDocumentNo := DocumentNo;
                end;
                if TempGenJnlLine.Find('-') then
                    repeat
                        GenJnlLine.Init();
                        OnBeforeGenJnlLineCreate(TempGenJnlLine, GenJnlLine, DocumentNo, AutoDocumentNo);
                        GenJnlLine."Line No." := 0;
                        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                        LineNo := LineNo + 1;
                        if GuiAllowed() then
                            Window.Update(3, LineNo);
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."FA Posting Date" := DeprUntilDate;
                        if GenJnlLine."Posting Date" = GenJnlLine."FA Posting Date" then
                            GenJnlLine."FA Posting Date" := 0D;
                        GenJnlLine."FA Posting Type" := TempGenJnlLine."FA Posting Type";
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
                        GenJnlLine.Validate("Account No.", TempGenJnlLine."Account No.");
                        GenJnlLine.Description := PostingDescription;
                        GenJnlLine."Document No." := AutoDocumentNo;
                        GenJnlLine."Posting No. Series" := NoSeries;
                        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
                        GenJnlLine.Validate(Amount, TempGenJnlLine.Amount);
                        GenJnlLine."No. of Depreciation Days" := TempGenJnlLine."No. of Depreciation Days";
                        GenJnlLine."FA Error Entry No." := TempGenJnlLine."FA Error Entry No.";
                        GenJnlNextLineNo := GenJnlNextLineNo + 1000;
                        GenJnlLine."Line No." := GenJnlNextLineNo;
                        OnBeforeGenJnlLineInsert(TempGenJnlLine, GenJnlLine);
                        GenJnlLine.Insert(true);
                        GenJnlLineCreatedCount += 1;
                        if BalAccount then
                            FAInsertGLAcc.GetBalAcc(GenJnlLine, GenJnlNextLineNo);
                        OnAfterFAInsertGLAccGetBalAcc(GenJnlLine, GenJnlNextLineNo, BalAccount, TempGenJnlLine);
                    until TempGenJnlLine.Next() = 0;
                OnAfterPostDataItem();
                if NeedCommit and not SuppressCommit then
                    Commit();
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
                    field(DepreciationBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field(FAPostingDate; DeprUntilDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Posting Date';
                        Importance = Additional;
                        ToolTip = 'Specifies the fixed asset posting date to be used by the batch job. The batch job includes ledger entries up to this date. This date appears in the FA Posting Date field in the resulting journal lines. If the Use Same FA+G/L Posting Dates field has been activated in the depreciation book that is used in the batch job, then this date must be the same as the posting date entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            DeprUntilDateModified := true;
                        end;
                    }
                    field(UseForceNoOfDays; UseForceNoOfDays)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Use Force No. of Days';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want the program to use the number of days, as specified in the field below, in the depreciation calculation.';

                        trigger OnValidate()
                        begin
                            if not UseForceNoOfDays then
                                DaysInPeriod := 0;
                        end;
                    }
                    field(ForceNoOfDays; DaysInPeriod)
                    {
                        ApplicationArea = FixedAssets;
                        BlankZero = true;
                        Caption = 'Force No. of Days';
                        Importance = Additional;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of days to use for the depreciation calculation.';

                        trigger OnValidate()
                        begin
                            if not UseForceNoOfDays and (DaysInPeriod <> 0) then
                                Error(Text006);
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date to be used by the batch job.';

                        trigger OnValidate()
                        begin
                            if not DeprUntilDateModified then
                                DeprUntilDate := PostingDate;
                        end;
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the Posting Description.';
                    }
                    field(InsertBalAccount; BalAccount)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insert Bal. Account';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want the batch job to automatically insert fixed asset entries with balancing accounts.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            ClientTypeManagement: Codeunit "Client Type Management";
        begin
            BalAccount := true;
            if ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Background then begin
                PostingDate := WorkDate();
                DeprUntilDate := WorkDate();
            end;
            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := FASetup."Default Depr. Book";
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OnBeforeOnInitReport(DeprBookCode);
    end;

    trigger OnPostReport()
    var
        PageGenJnlLine: Record "Gen. Journal Line";
        PageFAJnlLine: Record "FA Journal Line";
        ConfirmMgt: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        if ErrorMessageHandler.HasErrors() then
            if ErrorMessageHandler.ShowErrors() then
                Error('');
        if GuiAllowed() then
            Window.Close();
        if (FAJnlLineCreatedCount = 0) and (GenJnlLineCreatedCount = 0) then begin
            Message(CompletionStatsMsg);
            exit;
        end;

        if FAJnlLineCreatedCount > 0 then begin
            IsHandled := false;
            OnPostReportOnBeforeConfirmShowFAJournalLines(DeprBook, FAJnlLine, FAJnlLineCreatedCount, IsHandled);
            if not IsHandled then
                if ConfirmMgt.GetResponse(StrSubstNo(CompletionStatsFAJnlQst, FAJnlLineCreatedCount), true) then begin
                    PageFAJnlLine.SetRange("Journal Template Name", FAJnlLine."Journal Template Name");
                    PageFAJnlLine.SetRange("Journal Batch Name", FAJnlLine."Journal Batch Name");
                    PageFAJnlLine.FindFirst();
                    PAGE.Run(PAGE::"Fixed Asset Journal", PageFAJnlLine);
                end;
        end;

        if GenJnlLineCreatedCount > 0 then begin
            IsHandled := false;
            OnPostReportOnBeforeConfirmShowGenJournalLines(DeprBook, GenJnlLine, GenJnlLineCreatedCount, IsHandled);
            if not IsHandled then
                if ConfirmMgt.GetResponse(StrSubstNo(CompletionStatsGenJnlQst, GenJnlLineCreatedCount), true) then begin
                    PageGenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                    PageGenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                    PageGenJnlLine.FindFirst();
                    PAGE.Run(PAGE::"Fixed Asset G/L Journal", PageGenJnlLine);
                end;
        end;

        OnAfterOnPostReport();
    end;

    trigger OnPreReport()
    begin
        ActivateErrorMessageHandling("Fixed Asset");

        GeneralLedgerSetup.Get();

        DeprBook.Get(DeprBookCode);
        if DeprUntilDate = 0D then
            Error(Text000, FAJnlLine.FieldCaption("FA Posting Date"));
        if PostingDate = 0D then
            PostingDate := DeprUntilDate;
        if UseForceNoOfDays and (DaysInPeriod = 0) then
            Error(Text001);

        if DeprBook."Use Same FA+G/L Posting Dates" and (DeprUntilDate <> PostingDate) then
            Error(
              Text002,
              FAJnlLine.FieldCaption("FA Posting Date"),
              FAJnlLine.FieldCaption("Posting Date"),
              DeprBook.FieldCaption("Use Same FA+G/L Posting Dates"),
              false,
              DeprBook.TableCaption(),
              DeprBook.FieldCaption(Code),
              DeprBook.Code);
        if GuiAllowed() then
            Window.Open(Text003 + Text004 + Text005);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        FASetup: Record "FA Setup";
        FAJnlLine: Record "FA Journal Line";
        TempFAJnlLine: Record "FA Journal Line" temporary;
        DeprBook: Record "Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CalculateDepr: Codeunit "Calculate Depreciation";
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        Window: Dialog;
        DeprAmount: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        Custom1NumberOfDays: Integer;
        AutoDocumentNo: Code[20];
        NoSeries: Code[20];
        ErrorNo: Integer;
        Custom1ErrorNo: Integer;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        EntryAmounts: array[4] of Decimal;
        LineNo: Integer;
        FAJnlLineCreatedCount: Integer;
        GenJnlLineCreatedCount: Integer;
        DeprUntilDateModified: Boolean;
        SuppressCommit: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify %1.';
#pragma warning restore AA0470
        Text001: Label 'Force No. of Days must be activated.';
#pragma warning disable AA0470
        Text002: Label '%1 and %2 must be identical. %3 must be %4 in %5 %6 = %7.';
        Text003: Label 'Depreciating fixed asset      #1##########\';
        Text004: Label 'Not depreciating fixed asset  #2##########\';
        Text005: Label 'Inserting journal lines       #3##########';
#pragma warning restore AA0470
        Text006: Label 'Use Force No. of Days must be activated.';
#pragma warning restore AA0074
        CompletionStatsMsg: Label 'The depreciation has been calculated.\\No journal lines were created.';
#pragma warning disable AA0470
        CompletionStatsFAJnlQst: Label 'The depreciation has been calculated.\\%1 fixed asset journal lines were created.\\Do you want to open the Fixed Asset Journal window?', Comment = 'The depreciation has been calculated.\\5 fixed asset journal lines were created.\\Do you want to open the Fixed Asset Journal window?';
        CompletionStatsGenJnlQst: Label 'The depreciation has been calculated.\\%1 fixed asset G/L journal lines were created.\\Do you want to open the Fixed Asset G/L Journal window?', Comment = 'The depreciation has been calculated.\\2 fixed asset G/L  journal lines were created.\\Do you want to open the Fixed Asset G/L Journal window?';
#pragma warning restore AA0470

    protected var
        DeprBookCode: Code[10];
        DeprUntilDate: Date;
        UseForceNoOfDays: Boolean;
        DaysInPeriod: Integer;
        PostingDate: Date;
        DocumentNo: Code[20];
        PostingDescription: Text[100];
        BalAccount: Boolean;

    procedure InitializeRequest(DeprBookCodeFrom: Code[10]; DeprUntilDateFrom: Date; UseForceNoOfDaysFrom: Boolean; DaysInPeriodFrom: Integer; PostingDateFrom: Date; DocumentNoFrom: Code[20]; PostingDescriptionFrom: Text[100]; BalAccountFrom: Boolean)
    begin
        DeprBookCode := DeprBookCodeFrom;
        DeprUntilDate := DeprUntilDateFrom;
        UseForceNoOfDays := UseForceNoOfDaysFrom;
        DaysInPeriod := DaysInPeriodFrom;
        PostingDate := PostingDateFrom;
        DocumentNo := DocumentNoFrom;
        PostingDescription := PostingDescriptionFrom;
        BalAccount := BalAccountFrom;
    end;

    local procedure ActivateErrorMessageHandling(var FixedAsset: Record "Fixed Asset")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeActivateErrorMessageHandling(FixedAsset, ErrorMessageMgt, ErrorMessageHandler, ErrorContextElement, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed then
            ErrorMessageMgt.Activate(ErrorMessageHandler);
    end;

    procedure SetSuppressCommit(NewSuppressCommmit: Boolean)
    begin
        SuppressCommit := NewSuppressCommmit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateDepreciation(FANo: Code[20]; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var TempFAJournalLine: Record "FA Journal Line" temporary; var DeprAmount: Decimal; var NumberOfDays: Integer; DeprBookCode: Code[10]; DeprUntilDate: Date; EntryAmounts: array[4] of Decimal; DaysInPeriod: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFAInsertGLAccGetBalAcc(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlNextLineNo: Integer; var BalAccount: Boolean; var TempGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDataItem()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPostReport()
    begin
    end;

#pragma warning disable AS0025
    [IntegrationEvent(false, false)]
    local procedure OnBeforeActivateErrorMessageHandling(var FixedAsset: Record "Fixed Asset"; var ErrorMessageMgt: Codeunit "Error Message Management"; var ErrorMessageHandler: Codeunit "Error Message Handler"; var ErrorContextElement: Codeunit "Error Context Element"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0025

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateDepreciation(FANo: Code[20]; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var TempFAJournalLine: Record "FA Journal Line" temporary; var DeprAmount: Decimal; var NumberOfDays: Integer; DeprBookCode: Code[10]; DeprUntilDate: Date; EntryAmounts: array[4] of Decimal; DaysInPeriod: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var TempFAJournalLine: Record "FA Journal Line" temporary; var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInitReport(var DeprBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeConfirmShowFAJournalLines(DeprBook: Record "Depreciation Book"; FAJnlLine: Record "FA Journal Line"; FAJnlLineCreatedCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforeConfirmShowGenJournalLines(DeprBook: Record "Depreciation Book"; GenJnlLine: Record "Gen. Journal Line"; GenJnlLineCreatedCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineCreate(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; var AutoDocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnAfterFAJnlLineInit(var TempFAJournalLine: Record "FA Journal Line" temporary; var FAJournalLine: Record "FA Journal Line"; DocumentNo: Code[20]; var AutoDocumentNo: Code[20])
    begin
    end;
}

