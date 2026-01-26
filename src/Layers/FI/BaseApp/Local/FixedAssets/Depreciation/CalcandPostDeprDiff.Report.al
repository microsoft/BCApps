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

report 13402 "Calc. and Post Depr. Diff."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FixedAssets/Depreciation/CalcandPostDeprDiff.rdlc';
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
                    if FAPostingGroup."Depr. Difference Acc." = '' then
                        Error(Text13406, FAPostingGroup.Code);
                    if FAPostingGroup."Depr. Difference Bal. Acc." = '' then
                        Error(Text13407, FAPostingGroup.Code);

                    FALedgerEntry.Reset();
                    FALedgerEntry.SetCurrentKey("FA No.", "FA Posting Group", "Depreciation Book Code",
                      "FA Posting Category", "FA Posting Type", "Posting Date", "Depr. Difference Posted");
                    FALedgerEntry.SetRange("FA No.", "No.");
                    FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode1);
                    FALedgerEntry.SetFilter("FA Posting Category", '<>%1', FALedgerEntry."FA Posting Category"::Disposal);
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                    FALedgerEntry.SetRange("Posting Date", StartDate, EndDate);
                    FALedgerEntry.SetRange("Depr. Difference Posted", false);
                    FALedgerEntry.CalcSums(Amount);
                    DeprBookAmt1 := FALedgerEntry.Amount;

                    if PostDeprDiff then
                        FALedgerEntry.ModifyAll("Depr. Difference Posted", true);

                    FALedgerEntry.Reset();
                    FALedgerEntry.SetCurrentKey("FA No.", "FA Posting Group", "Depreciation Book Code",
                      "FA Posting Category", "FA Posting Type", "Posting Date", "Depr. Difference Posted");
                    FALedgerEntry.SetRange("FA No.", "No.");
                    FALedgerEntry.SetRange("Depreciation Book Code", DeprBookCode2);
                    FALedgerEntry.SetFilter("FA Posting Category", '<>%1', FALedgerEntry."FA Posting Category"::Disposal);
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                    FALedgerEntry.SetRange("Posting Date", StartDate, EndDate);
                    FALedgerEntry.SetRange("Depr. Difference Posted", false);
                    FALedgerEntry.CalcSums(Amount);
                    DeprBookAmt2 := FALedgerEntry.Amount;

                    if PostDeprDiff then
                        FALedgerEntry.ModifyAll("Depr. Difference Posted", true);

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
                    DeprDiffPostingBuffer.Reset();
                    if DeprDiffPostingBuffer.FindSet() then begin
                        repeat
                            PostJournalLines(DeprDiffPostingBuffer);
                        until DeprDiffPostingBuffer.Next() = 0;
                        Message(Text13408);
                    end else
                        Message(Text13412);
                end;

                DeprDiffPostingBuffer.DeleteAll();
            end;

            trigger OnPreDataItem()
            begin
                FixedAsset.SetCurrentKey("FA Posting Group");

                if PostDeprDiff then
                    if not Confirm(Text13409, false) then
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
    begin
        if (DeprBookCode1 = '') or (DeprBookCode2 = '') then
            Error(Text13405);
        if StartDate = 0D then
            Error(Text13402);
        if EndDate = 0D then
            Error(Text13403);
        if EndDate < StartDate then
            Error(Text13404);

        if DeprBook.Get(DeprBookCode1) then
            if not (DeprBook."G/L Integration - Depreciation" and DeprBook."G/L Integration - Acq. Cost") then
                Error(Text13410);

        if DeprBook.Get(DeprBookCode2) then
            if (DeprBook."G/L Integration - Depreciation") or (DeprBook."G/L Integration - Acq. Cost") then
                Error(Text13411);

        if PostDeprDiff then begin
            if PostingDate = 0D then
                Error(Text13400);
            if DocNo = '' then
                Error(Text13401);
        end;

        DeprBook.Get(DeprBookCode1);
        FAGenReport.SetFAPostingGroup(FixedAsset, DeprBook.Code);
        FAGenReport.AppendFAPostingFilter(FixedAsset, StartDate, EndDate);
        FAFilter := FixedAsset.GetFilters();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        FAPostingGroup: Record "FA Posting Group";
        DeprDiffPostingBuffer: Record "Depr. Diff. Posting Buffer" temporary;
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
        Text13400: Label 'Please enter the Posting Date.';
        Text13401: Label 'Please enter the Document No.';
        Text13402: Label 'Please enter the Starting Date for Depreciation Calculation.';
        Text13403: Label 'Please enter the Ending Date for Depreciation Calculation.';
        Text13404: Label 'Ending Date must not be before Starting Date.';
        Text13405: Label 'Please specify Depreciation Book Code 1 and Depreciation Book Code 2.';
        Text13406: Label 'You must specify Depr. Difference Acc. in FA posting Group %1.';
        Text13407: Label 'You must specify Depr. Difference Bal. Acc. in FA posting Group %1.';
        Text13408: Label 'The Depreciation Difference was successfully posted.';
        Text13409: Label 'Do you want to post the Depreciation Difference ?';
        Text13410: Label 'The Depreciation Book Code 1 must be integrated with G/L.';
        Text13411: Label 'The Depreciation Book Code 2 must not be integrated with G/L.';
        Text13412: Label 'There is no Depreciation Difference posted for the specified period.';
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

    local procedure PostJournalLines(DeprDiffBuffer: Record "Depr. Diff. Posting Buffer")
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
        GenJnlLine."Source Code" := SourceCodeSetup."Depr. Difference";
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
        Clear(DeprDiffPostingBuffer);
        DeprDiffPostingBuffer."Depr. Difference Acc." := FAPostingGroup."Depr. Difference Acc.";
        DeprDiffPostingBuffer."Depr. Difference Bal. Acc." := FAPostingGroup."Depr. Difference Bal. Acc.";
        DeprDiffPostingBuffer."Depreciation Amount 1" := DeprBookAmt1;
        DeprDiffPostingBuffer."Depreciation Amount 2" := DeprBookAmt2;
        DeprDiffPostingBuffer."FA No." := FixedAsset."No.";
        DeprDiffPostingBuffer.Insert();
    end;
}

