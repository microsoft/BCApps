// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Sustainability.ExciseTax;

report 7412 "Excise Tax Report"
{
    ProcessingOnly = true;
    Caption = 'Generate Excise Tax Journal Entries';
    UsageCategory = Tasks;
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("Excise Tax Type"; "Excise Tax Type")
        {
            RequestFilterFields = Code;
            trigger OnAfterGetRecord()
            var
                ExciseJournalBatch: Record "Sust. Excise Journal Batch";
                ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
            begin
                ExciseTaxCalculation.GetExciseBatchForTaxType(ExciseJournalBatch, "Excise Tax Type".Code, false);
                if ExciseJournalBatch.IsEmpty() then
                    exit;

                ExciseTaxCalculation.ProcessTaxTypeItemsWithFilter("Excise Tax Type".Code, StartingDate, EndingDate, ItemFilter, PostingDate);
                ExciseTaxCalculation.ProcessFATaxTypeItemsWithFilter("Excise Tax Type".Code, StartingDate, EndingDate, FixedAssetFilter, PostingDate);
                ProcessedTaxTypes += 1;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Enabled, true);
                ProcessedTaxTypes := 0;
                TotalJournalLines := 0;
                LinesCountBefore := GetCurrentJournalLineCount();
            end;

            trigger OnPostDataItem()
            begin
                CountCreatedJournalLines();
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
                group("Posting Information")
                {
                    Caption = 'Posting Information';

                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the generated journal lines.';

                        trigger OnValidate()
                        begin
                            if PostingDate = 0D then
                                Error(PostingDateRequiredErr);
                        end;
                    }
                }
                group("Date Filters")
                {
                    Caption = 'Date Filters';

                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date for filtering Item Ledger Entries and FA Ledger Entries. Only entries with posting dates from this date onwards will be included in the journal line generation.';

                        trigger OnValidate()
                        begin
                            ValidateDateRange();
                        end;
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date for filtering Item Ledger Entries and FA Ledger Entries. Only entries with posting dates up to this date will be included in the journal line generation.';

                        trigger OnValidate()
                        begin
                            ValidateDateRange();
                        end;
                    }
                }
                group("Source Filters")
                {
                    Caption = 'Source Filters';

                    field(ItemFilter; ItemFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the item filter. Leave blank to include all items.';
                        TableRelation = Item;
                    }
                    field(FixedAssetFilter; FixedAssetFilter)
                    {
                        ApplicationArea = All;
                        Caption = 'Fixed Asset Filter';
                        ToolTip = 'Specifies the fixed asset filter. Leave blank to include all fixed assets.';
                        TableRelation = "Fixed Asset";
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        if PostingDate = 0D then
            Error(PostingDateRequiredErr);
        if StartingDate = 0D then
            Error(StartingDateRequiredErr);
        if EndingDate = 0D then
            Error(EndingDateRequiredErr);

        if StartingDate > EndingDate then
            Error(StartingDateLaterErr);
    end;

    trigger OnPostReport()
    begin
        Message(ProcessingCompletedMsg, ProcessedTaxTypes, TotalJournalLines, StartingDate, EndingDate);
    end;

    var
        StartingDate: Date;
        EndingDate: Date;
        PostingDate: Date;
        ItemFilter: Text[250];
        FixedAssetFilter: Text[250];
        ProcessedTaxTypes: Integer;
        TotalJournalLines: Integer;
        LinesCountBefore: Integer;
        EndingDateEarlierErr: Label 'Ending Date cannot be earlier than Starting Date.';
        StartingDateLaterErr: Label 'Starting Date cannot be later than Ending Date.';
        PostingDateRequiredErr: Label 'Posting Date is required. Please specify a posting date.';
        StartingDateRequiredErr: Label 'Starting Date is required. Please specify a starting date.';
        EndingDateRequiredErr: Label 'Ending Date is required. Please specify an ending date.';
        ProcessingCompletedMsg: Label 'Processing completed successfully:\Tax Types Processed: %1\Journal Lines Created: %2\Date Range: %3 to %4';

    procedure SetRequestPageParameters(NewPostingDate: Date; NewStartingDate: Date; NewEndingDate: Date; NewItemFilter: Text[250]; NewFixedAssetFilter: Text[250])
    begin
        PostingDate := NewPostingDate;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
        ItemFilter := NewItemFilter;
        FixedAssetFilter := NewFixedAssetFilter;
    end;

    local procedure CountCreatedJournalLines()
    var
        LinesCountAfter: Integer;
    begin
        LinesCountAfter := GetCurrentJournalLineCount();
        TotalJournalLines := LinesCountAfter - LinesCountBefore;
    end;

    local procedure GetCurrentJournalLineCount(): Integer
    var
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        ExciseJnlBatch: Record "Sust. Excise Journal Batch";
        TotalCount: Integer;
    begin
        TotalCount := 0;

        ExciseJnlBatch.SetRange(Type, ExciseJnlBatch.Type::Excises);
        if ExciseJnlBatch.FindSet() then
            repeat
                ExciseJnlLine.SetRange("Journal Template Name", ExciseJnlBatch."Journal Template Name");
                ExciseJnlLine.SetRange("Journal Batch Name", ExciseJnlBatch.Name);
                TotalCount += ExciseJnlLine.Count;
            until ExciseJnlBatch.Next() = 0;

        exit(TotalCount);
    end;

    local procedure ValidateDateRange()
    begin
        if (EndingDate <> 0D) and (StartingDate <> 0D) and (EndingDate < StartingDate) then
            Error(EndingDateEarlierErr);
    end;
}