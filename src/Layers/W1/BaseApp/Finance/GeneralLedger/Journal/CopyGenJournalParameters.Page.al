// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Provides user interface for configuring parameters when copying general journal lines between batches.
/// Enables users to specify source batch, target batch, and transformation options for the copying operation.
/// </summary>
/// <remarks>
/// Parameter configuration dialog for journal copying functionality. Supports batch-to-batch line copying with optional
/// field transformations including posting date replacement, document number updates, and amount sign reversal.
/// Key features: Source and target batch selection, optional date and document number replacement, amount sign reversal option.
/// Integration: Used by copy journal management processes and provides parameter validation before copying operations.
/// </remarks>
page 184 "Copy Gen. Journal Parameters"
{
    Caption = 'Copy Gen. Journal Parameters';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Copy Gen. Journal Parameters";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SourceJnlTemplateName; SourceJnlTemplateName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Journal Template';
                    ToolTip = 'Specifies original journal template.';
                    Editable = false;
                }
                field(SourceJnlBatchName; SourceJnlBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Journal Batch';
                    ToolTip = 'Specifies original journal batch.';
                    Editable = false;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Target Journal Template';
                    ToolTip = 'Specifies journal template is used to copy posted journal lines.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Target Journal Batch';
                    ToolTip = 'Specifies journal batch is used to copy posted journal lines.';
                }
                field("Replace Posting Date"; Rec."Replace Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Replace Posting Date';
                    ToolTip = 'Specifies if the posting date will be validated with the value of current field while copy posted journal lines. If you leave this field blank original Posting Date will be used in Target Journal.';
                }
                field("Replace Document No."; Rec."Replace Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Replace Document No.';
                    ToolTip = 'Specifies if the document number will be replaced with the value of current field while copy posted journal lines. If you leave this field blank original Document No. will be used in Target Journal.';
                }
                field("Reverse Sign"; Rec."Reverse Sign")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse Sign';
                    ToolTip = 'Specifies if the amount will be replaced with the opposite value while copy posted journal lines. If you leave this field disabled original amount will be used in Target Journal.';
                }
            }
        }
    }

    var
        SourceJnlTemplateName: Text;
        SourceJnlBatchName: Text;
        MultipleTxt: Label '(multiple)';

    trigger OnOpenPage()
    begin
        InsertRecord();

        if (SourceJnlTemplateName = '') or (SourceJnlBatchName = '') then begin
            SourceJnlTemplateName := MultipleTxt;
            SourceJnlBatchName := MultipleTxt;
        end;
    end;

    /// <summary>
    /// Retrieves the configured copy parameters from the page for use in copying operations.
    /// Returns user-configured settings for journal line copying process.
    /// </summary>
    /// <param name="CopyGenJournalParameters">Parameter record that will be populated with current page settings.</param>
    procedure GetCopyParameters(var CopyGenJournalParameters: Record "Copy Gen. Journal Parameters")
    begin
        CopyGenJournalParameters := Rec;
    end;

    /// <summary>
    /// Initializes the page with existing copy parameters and source batch information.
    /// Sets up the page with predefined values and source journal batch context.
    /// </summary>
    /// <param name="CopyGenJournalParameters">Parameter record containing initial copy settings.</param>
    /// <param name="TempGenJournalBatch">Temporary journal batch record providing source context information.</param>
    procedure SetCopyParameters(CopyGenJournalParameters: Record "Copy Gen. Journal Parameters"; TempGenJournalBatch: Record "Gen. Journal Batch" temporary)
    begin
        InsertRecord();

        Rec := CopyGenJournalParameters;
        Rec.Modify(true);

        SourceJnlTemplateName := TempGenJournalBatch."Journal Template Name";
        SourceJnlBatchName := TempGenJournalBatch.Name;
    end;

    local procedure InsertRecord()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
