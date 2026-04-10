// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Dimension;

/// <summary>
/// Provides user interface for defining dimension-based filtering criteria for general journal line analysis.
/// Enables users to specify multiple dimension filters for advanced journal line querying and reporting.
/// </summary>
/// <remarks>
/// Dimension filtering configuration page for journal line analysis. Supports multi-dimensional filtering scenarios
/// where users need to analyze journal entries based on specific dimension value combinations.
/// Key features: Multiple dimension filter definition, dimension value lookup, filter expression support.
/// Integration: Works with journal reporting tools and dimension analysis functions for enhanced filtering capabilities.
/// </remarks>
page 482 "Gen. Jnl. Dim. Filters"
{
    Caption = 'Gen. Jnl. Dim. Filters';
    DelayedInsert = true;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Gen. Jnl. Dim. Filter";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(Rec."Dimension Code", Text));
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", GenJournalLine."Line No.");
        if GenJnlDimFilter.FindSet() then
            repeat
                Rec.Init();
                Rec.TransferFields(GenJnlDimFilter);
                Rec.Insert();
            until GenJnlDimFilter.Next() = 0;
    end;

    trigger OnClosePage()
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", GenJournalLine."Line No.");
        GenJnlDimFilter.DeleteAll();
        if Rec.FindSet() then
            repeat
                GenJnlDimFilter.Init();
                GenJnlDimFilter.TransferFields(Rec);
                GenJnlDimFilter."Journal Template Name" := GenJournalLine."Journal Template Name";
                GenJnlDimFilter."Journal Batch Name" := GenJournalLine."Journal Batch Name";
                GenJnlDimFilter."Journal Line No." := GenJournalLine."Line No.";
                GenJnlDimFilter.Insert();
            until Rec.Next() = 0;
    end;

    var
        GenJournalLine: Record "Gen. Journal Line";

    /// <summary>
    /// Sets the journal line context for dimension filter operations.
    /// Establishes the journal line reference used for filter persistence and context.
    /// </summary>
    /// <param name="NewGenJournalLine">Journal line record to use as context for dimension filtering.</param>
    procedure SetGenJnlLine(var NewGenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Copy(NewGenJournalLine);
    end;
}
