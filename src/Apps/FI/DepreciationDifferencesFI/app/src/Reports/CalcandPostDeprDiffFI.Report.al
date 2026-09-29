// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;

report 13478 "Calc. and Post Depr. Diff. FI"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Reports/CalcandPostDeprDiff.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate and Post Deprication Difference';
    Permissions = TableData "FA Ledger Entry" = rimd;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(FixedAsset; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "FA Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FixedAssetFAFilter; FixedAsset.TableCaption + ': ' + FAFilter)
            {
            }
            column(DeprBookAmt2; DeprBookAmt2)
            {
            }
            column(DeprBookAmt1; DeprBookAmt1)
            {
            }
            column(No_FixedAsset; "No.")
            {
            }
            column(Description_FixedAsset; Description)
            {
            }
            column(DifferenceAmt; DifferenceAmt)
            {
            }
            column(FAPostingGroupCode; FAPostingGroup.Code)
            {
            }
            column(DepreciationDifferenceEntriesCaption; DepreciationDifferenceEntriesCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(DeprAmtforBookCode1Caption; DeprAmtForBookCode1CaptionLbl)
            {
            }
            column(DeprAmtforBookCode2Caption; DeprAmtForBookCode2CaptionLbl)
            {
            }
            column(No_FixedAssetCaption; FieldCaption("No."))
            {
            }
            column(Description_FixedAssetCaption; FieldCaption(Description))
            {
            }
            column(DeprDiffAmountCaption; DeprDiffAmountCaptionLbl)
            {
            }
            column(FAPostingGroupCaption; FAPostingGroupCaptionLbl)
            {
            }
            column(GroupTotalCaption; GroupTotalCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(FAPostingGroup_FixedAsset; "FA Posting Group")
            {
            }

            trigger OnAfterGetRecord()
            begin
                DeprBookAmt1 := 0;
                DeprBookAmt2 := 0;
                DifferenceAmt := 0;

                if not (FADeprBook1.Get("No.", DeprBookCode1) and FADeprBook2.Get("No.", DeprBookCode2)) then
                    CurrReport.Skip();

                TestField("FA Posting Group", FADeprBook1."FA Posting Group");
                if FADeprBook2."FA Posting Group" <> '' then
                    FADeprBook2.TestField("FA Posting Group", FADeprBook1."FA Posting Group");

                if FAPostingGroup.Get(FADeprBook1."FA Posting Group") then begin
                    if FAPostingGroup."Deprec. Difference Account" = '' then
                        Error(SpecifyDeprDiffAccountErr, FAPostingGroup.Code);
                    if FAPostingGroup."Deprec. Difference Bal Acct" = '' then
                        Error(SpecifyDeprDiffBalAccountErr, FAPostingGroup.Code);

                    FALedgerEntry.Reset();
                    FALedgerEntry.SetCurrentKey("FA No.", "FA Posting Group", "Depreciation Book Code",
                      "FA Posting Category", "FA Posting Type", "Posting Date", "Depreciation Difference Posted");
                    FALedgerEntry.SetRange("FA No.", "No.");
                    FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode1);
                    FALedgerEntry.SetFilter("FA Posting Category", '<>%1', FALedgerEntry."FA Posting Category"::Disposal);
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                    FALedgerEntry.SetRange("Posting Date", StartDate, EndDate);
                    FALedgerEntry.SetRange("Depreciation Difference Posted", false);
                    FALedgerEntry.CalcSums(Amount);
                    DeprBookAmt1 := FALedgerEntry.Amount;

                    if PostDeprDiff then
                        FALedgerEntry.ModifyAll("Depreciation Difference Posted", true);

                    FALedgerEntry.Reset();
                    FALedgerEntry.SetCurrentKey("FA No.", "FA Posting Group", "Depreciation Book Code",
                      "FA Posting Category", "FA Posting Type", "Posting Date", "Depreciation Difference Posted");
                    FALedgerEntry.SetRange("FA No.", "No.");
                    FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode2);
                    FALedgerEntry.SetFilter("FA Posting Category", '<>%1', FALedgerEntry."FA Posting Category"::Disposal);
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                    FALedgerEntry.SetRange("Posting Date", StartDate, EndDate);
                    FALedgerEntry.SetRange("Depreciation Difference Posted", false);
                    FALedgerEntry.CalcSums(Amount);
                    DeprBookAmt2 := FALedgerEntry.Amount;

                    if PostDeprDiff then
                        FALedgerEntry.ModifyAll("Depreciation Difference Posted", true);

                    DifferenceAmt := CalcDeprDifference(DeprBookAmt1, DeprBookAmt2);

                    if ((DeprBookAmt1 <> 0) or (DeprBookAmt2 <> 0)) and (PrintEmptyLines or (DifferenceAmt <> 0)) then
                        InsertDifferenceBuffer()
                    else
                        CurrReport.Skip();
                end;
            end;

            trigger OnPostDataItem()
            begin
                if PostDeprDiff then begin
                    TempDeprDiffPostingBuffer.Reset();
                    if TempDeprDiffPostingBuffer.FindSet() then begin
                        repeat
                            PostJournalLines(TempDeprDiffPostingBuffer);
                        until TempDeprDiffPostingBuffer.Next() = 0;
                        Message(DeprDiffPostedMsg);
                    end else
                        Message(NoDeprDiffPostedMsg);
                end;

                TempDeprDiffPostingBuffer.DeleteAll();
            end;

            trigger OnPreDataItem()
            begin
                FixedAsset.SetCurrentKey("FA Posting Group");

                if PostDeprDiff then
                    if not Confirm(PostDeprDiffQst, false) then
                        CurrReport.Quit();
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
                    field("Depreciation Book Code 1"; DeprBookCode1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book Code 1';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book that should be integrated with the general ledger.';
                    }
                    field("Depreciation Book Code 2"; DeprBookCode2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depreciation Book Code 2';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book that should not be integrated with the general ledger.';
                    }
                    field("Starting Date"; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start for the depreciation difference calculation.';
                    }
                    field("Ending Date"; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the end date for the depreciation difference calculation.';
                    }
                    field("Posting Date"; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date to define when the depreciation difference calculation is applied.';
                    }
                    field("Document No."; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number.';
                    }
                    field("Posting Description"; PostingDesc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a posting description.';
                    }
                    field("Print Empty Lines"; PrintEmptyLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Empty Lines';
                        ToolTip = 'Specifies whether to print fixed asset lines that have no depreciation difference.';
                    }
                    field("Post Depreciation Difference"; PostDeprDiff)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies whether to post the depreciation difference.';
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

    trigger OnPreReport()
#if not CLEAN30
    var
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        if not DepreciationDifferencesFIFeature.IsEnabled() then
            Error(FeatureNotEnabledErr);
#else
    begin
#endif

        if (DeprBookCode1 = '') or (DeprBookCode2 = '') then
            Error(SpecifyDeprBooksErr);
        if StartDate = 0D then
            Error(EnterStartingDateErr);
        if EndDate = 0D then
            Error(EnterEndingDateErr);
        if EndDate < StartDate then
            Error(EndingDateBeforeStartingDateErr);

        if DeprBook.Get(DeprBookCode1) then
            if not (DeprBook."G/L Integration - Depreciation" and DeprBook."G/L Integration - Acq. Cost") then
                Error(Book1GLIntegrationErr);

        if DeprBook.Get(DeprBookCode2) then
            if (DeprBook."G/L Integration - Depreciation") or (DeprBook."G/L Integration - Acq. Cost") then
                Error(Book2GLIntegrationErr);

        if PostDeprDiff then begin
            if PostingDate = 0D then
                Error(EnterPostingDateErr);
            if DocNo = '' then
                Error(EnterDocumentNoErr);
        end;

        DeprBook.Get(DeprBookCode1);
        FAGenReport.SetFAPostingGroup(FixedAsset, DeprBook.Code);
        FAGenReport.AppendFAPostingFilter(FixedAsset, StartDate, EndDate);
        FAFilter := CopyStr(FixedAsset.GetFilters(), 1, MaxStrLen(FAFilter));
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        FAPostingGroup: Record "FA Posting Group";
        TempDeprDiffPostingBuffer: Record "Depr. Diff. Posting Buffer FI" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        FALedgerEntry: Record "FA Ledger Entry";
        FADeprBook1: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        FAGenReport: Codeunit "FA General Report";
        DeprBookCode1: Code[20];
        DeprBookCode2: Code[20];
        DocNo: Code[20];
        PostingDesc: Text[50];
        FAFilter: Text[250];
        DifferenceAmt: Decimal;
        DeprBookAmt1: Decimal;
        DeprBookAmt2: Decimal;
        GenJnlNextLineNo: Integer;
        PostDeprDiff: Boolean;
        PrintEmptyLines: Boolean;
        EnterPostingDateErr: Label 'Please enter the Posting Date.';
        EnterDocumentNoErr: Label 'Please enter the Document No.';
        EnterStartingDateErr: Label 'Please enter the Starting Date for Depreciation Calculation.';
        EnterEndingDateErr: Label 'Please enter the Ending Date for Depreciation Calculation.';
        EndingDateBeforeStartingDateErr: Label 'Ending Date must not be before Starting Date.';
        SpecifyDeprBooksErr: Label 'Please specify Depreciation Book Code 1 and Depreciation Book Code 2.';
        SpecifyDeprDiffAccountErr: Label 'You must specify Depr. Difference Acc. in FA posting Group %1.', Comment = '%1 is the FA posting group code.';
        SpecifyDeprDiffBalAccountErr: Label 'You must specify Depr. Difference Bal. Acc. in FA posting Group %1.', Comment = '%1 is the FA posting group code.';
        DeprDiffPostedMsg: Label 'The Depreciation Difference was successfully posted.';
        PostDeprDiffQst: Label 'Do you want to post the Depreciation Difference ?';
        Book1GLIntegrationErr: Label 'The Depreciation Book Code 1 must be integrated with G/L.';
        Book2GLIntegrationErr: Label 'The Depreciation Book Code 2 must not be integrated with G/L.';
        NoDeprDiffPostedMsg: Label 'There is no Depreciation Difference posted for the specified period.';
#if not CLEAN30
        FeatureNotEnabledErr: Label 'The Depreciation Differences FI feature must be enabled before you can run this report.';
#endif
        StartDate: Date;
        EndDate: Date;
        PostingDate: Date;
        DepreciationDifferenceEntriesCaptionLbl: Label 'Depreciation Difference Entries';
        PageCaptionLbl: Label 'Page';
        DeprAmtForBookCode1CaptionLbl: Label 'Depr. Amt. for Book Code 1';
        DeprAmtForBookCode2CaptionLbl: Label 'Depr. Amt. for Book Code 2';
        DeprDiffAmountCaptionLbl: Label 'Depr. Diff. Amount';
        FAPostingGroupCaptionLbl: Label 'FA Posting Group';
        GroupTotalCaptionLbl: Label 'Group Total';
        TotalCaptionLbl: Label 'Total';

    local procedure PostJournalLines(DeprDiffBuffer: Record "Depr. Diff. Posting Buffer FI")
    var
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        SourceCodeSetup.Get();
        Clear(GenJnlLine);
        GenJnlNextLineNo := 0;
        FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := DeprDiffBuffer."Depr. Difference Acc.";
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document No." := DocNo;
        GenJnlLine.Description := PostingDesc;
        GenJnlLine.Amount :=
          CalcDeprDifference(DeprDiffBuffer."Depreciation Amount 1",
          DeprDiffBuffer."Depreciation Amount 2");
        GenJnlLine."Source Code" := SourceCodeSetup."Depreciation Difference Code";
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine."Bal. Account No." := DeprDiffBuffer."Depr. Difference Bal. Acc.";
        GenJnlLine."Line No." := GenJnlNextLineNo + 10000;
        DimMgt.AddDimSource(DefaultDimSource, Database::"Fixed Asset", DeprDiffBuffer."FA No.");

        GenJnlLine."Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            DefaultDimSource, GenJnlLine."Source Code",
            GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code",
            0, 0);

        GenJnlPostLine.Run(GenJnlLine);
    end;

    local procedure CalcDeprDifference(DeprAmt1: Decimal; DeprAmt2: Decimal): Decimal
    begin
        exit(DeprAmt1 - DeprAmt2);
    end;

    local procedure InsertDifferenceBuffer()
    begin
        Clear(TempDeprDiffPostingBuffer);
        TempDeprDiffPostingBuffer."Depr. Difference Acc." := FAPostingGroup."Deprec. Difference Account";
        TempDeprDiffPostingBuffer."Depr. Difference Bal. Acc." := FAPostingGroup."Deprec. Difference Bal Acct";
        TempDeprDiffPostingBuffer."Depreciation Amount 1" := DeprBookAmt1;
        TempDeprDiffPostingBuffer."Depreciation Amount 2" := DeprBookAmt2;
        TempDeprDiffPostingBuffer."FA No." := FixedAsset."No.";
        TempDeprDiffPostingBuffer.Insert();
    end;
}
