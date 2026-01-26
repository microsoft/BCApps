// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Utilities;
using System.Utilities;

report 12113 "Close/Open Balance Sheet"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Close/Open Balance Statement';
    Permissions = TableData "G/L Entry" = m;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) order(ascending) where(Number = filter(1 .. 2));
            dataitem("G/L Account"; "G/L Account")
            {
                DataItemTableView = sorting("No.") where("Account Type" = const(Posting), "Income/Balance" = const("Balance Sheet"));
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = field("No.");
                    DataItemTableView = sorting("G/L Account No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    var
                        TempDimBuf: Record "Dimension Buffer" temporary;
                        TempDimBuf2: Record "Dimension Buffer" temporary;
                        EntryNo: Integer;
                    begin
                        if FieldActive("Business Unit Code") and
                           (ClosePerBusUnit or ClosePerGlobalDim1 or ClosePerGlobalDim2 or not ClosePerGlobalDimOnly)
                        then begin
                            SetRange("Business Unit Code", "Business Unit Code");
                            GenJnlLine."Business Unit Code" := "Business Unit Code";
                        end;
                        if FieldActive("Global Dimension 1 Code") and
                           (ClosePerGlobalDim1 or ClosePerGlobalDim2 or not ClosePerGlobalDimOnly)
                        then
                            SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                        if FieldActive("Global Dimension 2 Code") and
                           (ClosePerGlobalDim2 or not ClosePerGlobalDimOnly)
                        then
                            SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");

                        CalcSumsInFilter();

                        if (Amount <> 0) or ("Additional-Currency Amount" <> 0) then begin
                            if ClosePerGlobalDimOnly then begin
                                EntryNo := "Entry No.";
                                GetGLEntryDimensions(EntryNo, "Dimension Set ID", TempDimBuf);
                            end else begin
                                EntryNo := "Close Income Statement Dim. ID";
                                DimBufMgt.GetDimensions(EntryNo, TempDimBuf);
                            end;
                            TempDimBuf2.DeleteAll();
                            if TempSelectedDim.FindSet() then
                                repeat
                                    if TempDimBuf.Get(DATABASE::"G/L Entry", EntryNo, TempSelectedDim."Dimension Code")
                                    then begin
                                        TempDimBuf2."Table ID" := TempDimBuf."Table ID";
                                        TempDimBuf2."Dimension Code" := TempDimBuf."Dimension Code";
                                        TempDimBuf2."Dimension Value Code" := TempDimBuf."Dimension Value Code";
                                        TempDimBuf2.Insert();
                                    end;
                                until TempSelectedDim.Next() = 0;

                            EntryNo := DimBufMgt.GetDimensionId(TempDimBuf2);

                            if EntryNoAmountBuf.Get("Business Unit Code", EntryNo) then begin
                                EntryNoAmountBuf.Amount := EntryNoAmountBuf.Amount + Amount;
                                EntryNoAmountBuf.Amount2 := EntryNoAmountBuf.Amount2 + "Additional-Currency Amount";
                                EntryNoAmountBuf.Modify();
                            end else begin
                                EntryNoAmountBuf."Business Unit Code" := "Business Unit Code";
                                EntryNoAmountBuf."Entry No." := EntryNo;
                                EntryNoAmountBuf.Amount := Amount;
                                EntryNoAmountBuf.Amount2 := "Additional-Currency Amount";
                                EntryNoAmountBuf.Insert();
                            end;
                        end;
                        Find('+');
                        if FieldActive("Business Unit Code") then
                            SetRange("Business Unit Code");
                        if FieldActive("Global Dimension 1 Code") then
                            SetRange("Global Dimension 1 Code");
                        if FieldActive("Global Dimension 2 Code") then
                            SetRange("Global Dimension 2 Code");
                    end;

                    trigger OnPostDataItem()
                    var
                        TempDimBuf2: Record "Dimension Buffer" temporary;
                        GlobalDimVal1: Code[20];
                        GlobalDimVal2: Code[20];
                        NewDimensionID: Integer;
                    begin
                        if EntryNoAmountBuf.FindSet() then
                            repeat
                                GenJnlLine."Line No." := GenJnlLine."Line No." + 10000;
                                GenJnlLine."Account No." := "G/L Account No.";
                                GenJnlLine."Source Code" := SourceCodeSetup."Close Income Statement";
                                GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
                                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                                if Integer.Number = 1 then begin
                                    GenJnlLine."Bal. Account No." := ClAccNo;
                                    GenJnlLine.Validate(Amount, -EntryNoAmountBuf.Amount);
                                    GenJnlLine."Source Currency Amount" := -EntryNoAmountBuf.Amount2;
                                end else begin
                                    GenJnlLine."Bal. Account No." := OpAccNo;
                                    GenJnlLine.Validate(Amount, EntryNoAmountBuf.Amount);
                                    GenJnlLine."Source Currency Amount" := EntryNoAmountBuf.Amount2;
                                end;
                                TempDimBuf2.DeleteAll();
                                DimBufMgt.RetrieveDimensions(EntryNoAmountBuf."Entry No.", TempDimBuf2);
                                NewDimensionID := DimMgt.CreateDimSetIDFromDimBuf(TempDimBuf2);
                                GenJnlLine."Dimension Set ID" := NewDimensionID;
                                DimMgt.UpdateGlobalDimFromDimSetID(NewDimensionID, GlobalDimVal1, GlobalDimVal2);
                                GenJnlLine."Shortcut Dimension 1 Code" := '';
                                if ClosePerGlobalDim1 then
                                    GenJnlLine."Shortcut Dimension 1 Code" := GlobalDimVal1;
                                GenJnlLine."Shortcut Dimension 2 Code" := '';
                                if ClosePerGlobalDim2 then
                                    GenJnlLine."Shortcut Dimension 2 Code" := GlobalDimVal2;
                                HandleGenJnlLine();
                            until EntryNoAmountBuf.Next() = 0;

                        EntryNoAmountBuf.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if ClosePerBusUnit or ClosePerGlobalDim1 or ClosePerGlobalDim2 or not ClosePerGlobalDimOnly then
                            SetCurrentKey(
                              "G/L Account No.", "Business Unit Code",
                              "Global Dimension 1 Code", "Global Dimension 2 Code", "Close Income Statement Dim. ID",
                              "Posting Date", "Bal. Account No.", "Transaction No.")
                        else
                            SetCurrentKey("G/L Account No.", "Posting Date", "Bal. Account No.");
                        SetRange("Posting Date", FiscalYearStartDate, FiscYearClosingDate);

                        if (GLSetup."Additional Reporting Currency" <> '') and (Integer.Number = 2) then
                            if CloseTransactionNo <> 0 then
                                SetFilter("Transaction No.", '<>%1', CloseTransactionNo);

                        EntryNoAmountBuf.DeleteAll();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if ("No." = ClAccNo) or ("No." = OpAccNo) then
                        CurrReport.Skip();
                    Window.Update(1, "No.");
                    UpdateCloseIncomeStmtDimID("No.");
                    GenJnlLine."Closing Balance Sheet" := true;
                end;

                trigger OnPreDataItem()
                begin
                    if Integer.Number = 1 then begin
                        GenJnlLine."Posting Date" := FiscYearClosingDate;
                        GenJnlLine."Document No." := ClDocNo;
                        GenJnlLine.Description := ClPostingDescription;
                    end else begin
                        GenJnlLine."Posting Date" := EndDateReq + 1;
                        GenJnlLine."Document No." := OpDocNo;
                        GenJnlLine.Description := OpPostingDescription;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            var
                CloseGLEntry: Record "G/L Entry";
            begin
                if Number = 1 then begin
                    GenJnlLine."Journal Template Name" := ClTemplateName;
                    GenJnlLine."Journal Batch Name" := ClBatchName;
                end else begin
                    GenJnlLine."Journal Template Name" := OpTemplateName;
                    GenJnlLine."Journal Batch Name" := OpBatchName;
                    if GLSetup."Additional Reporting Currency" <> '' then
                        if CloseGLEntry.FindLast() then
                            CloseTransactionNo := CloseGLEntry."Transaction No.";
                end;

                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

                GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if not GenJnlLine.FindLast() then;
                GenJnlLine.Init();
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
                    field(FiscalYearEndingDate; EndDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Year Ending Date';
                        Editable = false;
                        ToolTip = 'Specifies the end date of the fiscal year.';

                        trigger OnValidate()
                        begin
                            ValidateEndDate(true);
                        end;
                    }
                    group("Close Balance Entries")
                    {
                        Caption = 'Close Balance Entries';
                        field(GenJournalTemplate_CloseBalanceEntries; ClTemplateName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Gen. Journal Template';
                            TableRelation = "Gen. Journal Template";
                            ToolTip = 'Specifies the general journal template.';

                            trigger OnValidate()
                            begin
                                ClDocNo := '';
                            end;
                        }
                        field(GenJournalBatch_CloseBalanceEntries; ClBatchName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Gen. Journal Batch';
                            Lookup = true;
                            ToolTip = 'Specifies the general journal batch.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenJnlBatch.SetRange("Journal Template Name", ClTemplateName);
                                if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                    ClBatchName := GenJnlBatch.Name;
                                    ValidateJnl();
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                if ClBatchName <> '' then begin
                                    if ClTemplateName = '' then
                                        Error(Text1130010);
                                    GenJnlBatch.Get(ClTemplateName, ClBatchName);
                                end;
                                ValidateJnl();
                            end;
                        }
                        field(DocumentNo_CloseBalanceEntries; ClDocNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the document number.';
                        }
                        field(ClosingAccountNo; ClAccNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Closing Account No.';
                            TableRelation = "G/L Account";
                            ToolTip = 'Specifies the closing account no.';

                            trigger OnValidate()
                            var
                                RClAcc: Record "G/L Account";
                            begin
                                if ClAccNo <> '' then begin
                                    RClAcc.Get(ClAccNo);
                                    RClAcc.CheckGLAcc();
                                end;
                            end;
                        }
                        field(ClPostingDescription; ClPostingDescription)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posting Description';
                            ToolTip = 'Specifies the posting description.';
                        }
                    }
                    group("Open Balance Entries")
                    {
                        Caption = 'Open Balance Entries';
                        field(GenJournalTemplate_OpenBalanceEntries; OpTemplateName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Gen. Journal Template';
                            TableRelation = "Gen. Journal Template";
                            ToolTip = 'Specifies the general journal template.';

                            trigger OnValidate()
                            begin
                                OpDocNo := '';
                            end;
                        }
                        field(GenJournalBatch_OpenBalanceEntries; OpBatchName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Gen. Journal Batch';
                            Lookup = true;
                            ToolTip = 'Specifies the general journal batch.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                GenJnlBatch.SetRange("Journal Template Name", OpTemplateName);
                                if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                    OpBatchName := GenJnlBatch.Name;
                                    ValidateOpJnl();
                                end;
                            end;

                            trigger OnValidate()
                            begin
                                if OpBatchName <> '' then begin
                                    if OpTemplateName = '' then
                                        Error(Text1130011);
                                    GenJnlBatch.Get(OpTemplateName, OpBatchName);
                                end;

                                ValidateOpJnl();
                            end;
                        }
                        field(DocumentNo_OpenBalanceEntries; OpDocNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the document number.';
                        }
                        field(OpeningAccountNo; OpAccNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Opening Account No.';
                            TableRelation = "G/L Account";
                            ToolTip = 'Specifies the opening account.';

                            trigger OnValidate()
                            var
                                ROpAcc: Record "G/L Account";
                            begin
                                if OpAccNo <> '' then begin
                                    ROpAcc.Get(OpAccNo);
                                    ROpAcc.CheckGLAcc();
                                end;
                            end;
                        }
                        field(OpPostingDescription; OpPostingDescription)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Posting Description';
                            ToolTip = 'Specifies the posting description.';
                        }
                    }
                    group("Close by")
                    {
                        Caption = 'Close by';
                        field(BusinessUnitCode; ClosePerBusUnit)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Code';
                            ToolTip = 'Specifies the business unit code.';
                        }
                        field(Dimensions; ColumnDim)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimensions';
                            Editable = false;
                            ToolTip = 'Specifies the dimensions.';

                            trigger OnAssistEdit()
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Close Income Statement", ColumnDim);
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if ClPostingDescription = '' then begin
                ClPostingDescription := Text1130003;
                OpPostingDescription := Text1130002;
            end;
            EndDateReq := 0D;
            AccountingPeriod.SetRange("New Fiscal Year", true);
            AccountingPeriod.SetRange("Date Locked", true);
            if AccountingPeriod.Find('+') then begin
                EndDateReq := AccountingPeriod."Starting Date" - 1;
                if not ValidateEndDate(false) then
                    EndDateReq := 0D;
            end;
            if ClDocNo = '' then
                ValidateJnl();
            ColumnDim := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Close Income Statement", '');
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            Error(Text000);
        ValidateEndDate(true);
        if (ClDocNo = '') or
           (OpDocNo = '')
        then
            Error(Text001);
        if (ClAccNo = '') or (OpAccNo = '') then
            Error(Text1130012);

        SourceCodeSetup.Get();
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then
            if not Confirm(AddRepCurrUsageQst, false) then
                CurrReport.Quit();

        SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Close Income Statement", '', TempSelectedDim);

        ClosePerGlobalDim1 := false;
        ClosePerGlobalDim2 := false;
        ClosePerGlobalDimOnly := true;

        if TempSelectedDim.FindSet() then
            repeat
                if TempSelectedDim."Dimension Code" = GLSetup."Global Dimension 1 Code" then
                    ClosePerGlobalDim1 := true;
                if TempSelectedDim."Dimension Code" = GLSetup."Global Dimension 2 Code" then
                    ClosePerGlobalDim2 := true;
                if (TempSelectedDim."Dimension Code" <> GLSetup."Global Dimension 1 Code") and
                   (TempSelectedDim."Dimension Code" <> GLSetup."Global Dimension 2 Code")
                then
                    ClosePerGlobalDimOnly := false;
            until TempSelectedDim.Next() = 0;

        CollectCloseIncomeStmtDimID();

        Window.Open(ProgressBarTxt);
    end;

    var
        Text000: Label 'Please enter the ending date for the fiscal year.';
        Text001: Label 'Please enter a Document No.';
        AddRepCurrUsageQst: Label 'With the use of an additional reporting currency, this batch job will post closing entries directly to the general ledger. These closing entries will not be transferred to a general journal before the program posts them to the general ledger.\Do you want to continue?';
        ProgressBarTxt: Label 'Creating general journal lines...\\Account No.          #1##########';
        Text014: Label 'The fiscal year must be closed before the income statement can be closed.';
        Text015: Label 'The fiscal year does not exist.';
        AccountingPeriod: Record "Accounting Period";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        DimSelectionBuf: Record "Dimension Selection Buffer";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        EntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        FiscalYearStartDate: Date;
        FiscYearClosingDate: Date;
        EndDateReq: Date;
        ClDocNo: Code[20];
        OpDocNo: Code[20];
        ClPostingDescription: Text[50];
        OpPostingDescription: Text[50];
        ClosePerBusUnit: Boolean;
        ClosePerGlobalDim1: Boolean;
        ClosePerGlobalDim2: Boolean;
        ClosePerGlobalDimOnly: Boolean;
        ColumnDim: Text[250];
        NextDimID: Integer;
        Text1130002: Label 'Open Balance Sheet';
        Text1130003: Label 'Close Balance Sheet';
        ClAccNo: Code[20];
        OpAccNo: Code[20];
        ClBatchName: Code[10];
        OpBatchName: Code[10];
        ClTemplateName: Code[10];
        OpTemplateName: Code[10];
        Text1130010: Label 'Please specify the Closing Journal Template Name.';
        Text1130011: Label 'Please specify the Opening Journal Template Name.';
        Text1130012: Label 'Please specify the Closing Account No. and the Opening Account No.';
        CloseTransactionNo: Integer;

    local procedure ValidateEndDate(RealMode: Boolean): Boolean
    var
        OK: Boolean;
    begin
        if EndDateReq = 0D then
            exit;

        OK := AccountingPeriod.Get(EndDateReq + 1);
        if OK then
            OK := AccountingPeriod."New Fiscal Year";
        if OK then begin
            if not AccountingPeriod."Date Locked" then begin
                if not RealMode then
                    exit;
                Error(Text014);
            end;
            FiscYearClosingDate := ClosingDate(EndDateReq);
            AccountingPeriod.SetRange("New Fiscal Year", true);
            OK := AccountingPeriod.Find('<');
            FiscalYearStartDate := AccountingPeriod."Starting Date";
        end;
        if not OK then begin
            if not RealMode then
                exit;
            Error(Text015);
        end;
        exit(true);
    end;

    local procedure ValidateJnl()
    var
        NoSeries: Codeunit "No. Series";
    begin
        ClDocNo := '';
        if GenJnlBatch.Get(ClTemplateName, ClBatchName) then
            if GenJnlBatch."No. Series" <> '' then
                ClDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", EndDateReq);
    end;

    local procedure HandleGenJnlLine()
    begin
        OnBeforeHandledGenJnlLine(GenJnlLine, Integer.Number);

        GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::None;
        GenJnlLine."System-Created Entry" := true;
        if GLSetup."Additional Reporting Currency" <> '' then begin
            GenJnlLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
            if (GenJnlLine.Amount = 0) and
               (GenJnlLine."Source Currency Amount" <> 0)
            then begin
                GenJnlLine."Additional-Currency Posting" :=
                  GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
                GenJnlLine.Validate(Amount, GenJnlLine."Source Currency Amount");
                GenJnlLine."Source Currency Amount" := 0;
            end;
            GenJnlPostLine.RunWithCheck(GenJnlLine);
            OnAfterHandleGenJnlLineGenJnlPostLine(GenJnlLine, Integer.Number);
        end else
            GenJnlLine.Insert();
    end;

    local procedure CollectCloseIncomeStmtDimID()
    var
        GLEntry: Record "G/L Entry";
        TempDimBuf: Record "Dimension Buffer";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if ClosePerGlobalDimOnly then
            exit;

        GLEntry.SetCurrentKey("Close Income Statement Dim. ID");
        GLEntry.SetFilter("Close Income Statement Dim. ID", '>1');
        if GLEntry.FindSet() then begin
            repeat
                if GLEntry."Dimension Set ID" <> 0 then begin
                    DimSetEntry.SetRange("Dimension Set ID", GLEntry."Dimension Set ID");
                    TempDimBuf.DeleteAll();
                    DimSetEntry.FindSet();
                    repeat
                        TempDimBuf."Table ID" := DATABASE::"G/L Entry";
                        TempDimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                        TempDimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                        TempDimBuf.Insert();
                    until DimSetEntry.Next() = 0;
                    DimBufMgt.InsertDimensionsUsingEntryNo(
                      TempDimBuf, GLEntry."Close Income Statement Dim. ID");
                end;
                GLEntry.SetFilter(
                  "Close Income Statement Dim. ID", '>%1', GLEntry."Close Income Statement Dim. ID");
            until GLEntry.Next() = 0;
            NextDimID := GLEntry."Close Income Statement Dim. ID" + 1;
        end else
            NextDimID := 2; // 1 is used when there are no dimensions on the entry
    end;

    local procedure UpdateCloseIncomeStmtDimID(AccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        DimensionSetID: Integer;
    begin
        if ClosePerGlobalDimOnly then
            exit;

        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date", "Close Income Statement Dim. ID", "Entry No.");
        GLEntry.SetLoadFields("Entry No.", "Dimension Set ID", "Close Income Statement Dim. ID");
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Posting Date", FiscalYearStartDate, FiscYearClosingDate);
        GLEntry.SetRange("Close Income Statement Dim. ID", 0);

        if GLEntry.FindSet() then
            repeat
                DimensionSetID := TryInsertDimensionsUsingEntryNo(GLEntry."Entry No.", GLEntry."Dimension Set ID", NextDimID);
                GLEntry."Close Income Statement Dim. ID" := DimensionSetID;
                GLEntry.Modify(true);
            until GLEntry.Next() = 0;
    end;

    local procedure CalcSumsInFilter()
    begin
        "G/L Entry".CalcSums(Amount);
        if GLSetup."Additional Reporting Currency" <> '' then
            "G/L Entry".CalcSums("Additional-Currency Amount");
    end;

    local procedure GetGLEntryDimensions(GLEntryNo: Integer; GLEntryDimensionSetID: Integer; var DimBuf: Record "Dimension Buffer"): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
        Counter: Integer;
    begin
        Counter := 0;
        DimSetEntry.SetRange("Dimension Set ID", GLEntryDimensionSetID);
        if DimSetEntry.FindSet() then
            repeat
                DimBuf."Table ID" := DATABASE::"G/L Entry";
                DimBuf."Entry No." := GLEntryNo;
                DimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                DimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                DimBuf.Insert();
                Counter += 1;
            until DimSetEntry.Next() = 0;
        exit(Counter);
    end;

    local procedure ValidateOpJnl()
    var
        NoSeries: Codeunit "No. Series";
    begin
        OpDocNo := '';
        if GenJnlBatch.Get(OpTemplateName, OpBatchName) then
            if GenJnlBatch."No. Series" <> '' then
                OpDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", EndDateReq);
    end;

    local procedure TryInsertDimensionsUsingEntryNo(GLEntryNo: Integer; GLEntryDimensionSetID: Integer; var NextDimensionSetID: Integer): Integer
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        DimBufCount: Integer;
        DimensionSetID: Integer;
    begin
        DimBufCount := GetGLEntryDimensions(GLEntryNo, GLEntryDimensionSetID, TempDimBuf);
        if not TempDimBuf.IsEmpty() then begin
            TempDimBuf.FindFirst();
            DimensionSetID := DimBufMgt.FindDimensionsKnownDimBufCount(TempDimBuf, DimBufCount);
            if DimensionSetID = 0 then begin
                DimBufMgt.InsertDimensionsUsingEntryNo(TempDimBuf, NextDimensionSetID);
                DimensionSetID := NextDimensionSetID;
                NextDimensionSetID += 1;
            end;
        end else
            DimensionSetID := 1;

        exit(DimensionSetID);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleGenJnlLineGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ReportType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandledGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ReportType: Integer)
    begin
    end;
}

