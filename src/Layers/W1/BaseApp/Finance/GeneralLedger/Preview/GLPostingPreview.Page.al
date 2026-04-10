// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Foundation.Navigate;

/// <summary>
/// Main posting preview page displaying entry types and counts generated during preview operations.
/// Provides overview of all ledger entries that would be created during actual posting.
/// </summary>
/// <remarks>
/// Displays document entries in a list format showing table names, entry counts, and total amounts.
/// Enables drill-down functionality to view detailed preview entries for each ledger type.
/// Serves as the primary interface for posting preview analysis and validation.
/// </remarks>
page 115 "G/L Posting Preview"
{
    Caption = 'Posting Preview';
    Editable = false;
    PageType = List;
    SourceTable = "Document Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control16)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Related Entries';
                    ToolTip = 'Specifies the name of the table where the Navigate facility has found entries with the selected document number and/or posting date.';

                    trigger OnDrillDown()
                    begin
                        PostingPreviewEventHandler.ShowEntries(Rec."Table ID");
                    end;
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Entries';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of documents that the Navigate facility has found in the table with the selected entries.';

                    trigger OnDrillDown()
                    begin
                        PostingPreviewEventHandler.ShowEntries(Rec."Table ID");
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(Show)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Show Related Entries';
                    Image = ViewDocumentLine;
                    ToolTip = 'View details about other entries that are related to the general ledger posting.';

                    trigger OnAction()
                    begin
                        PostingPreviewEventHandler.ShowEntries(Rec."Table ID");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Show_Promoted; Show)
                {
                }
            }
        }
    }

    var
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";

    /// <summary>
    /// Initializes the G/L posting preview page with document entries from posting preview operations.
    /// Loads entry types and counts for comprehensive overview of posting preview results.
    /// </summary>
    /// <param name="TempDocumentEntry">Temporary document entry records containing preview results</param>
    /// <param name="NewPostingPreviewEventHandler">Event handler for accessing detailed entries and operations</param>
    procedure Set(var TempDocumentEntry: Record "Document Entry" temporary; NewPostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        PostingPreviewEventHandler := NewPostingPreviewEventHandler;
        if TempDocumentEntry.FindSet() then
            repeat
                Rec := TempDocumentEntry;
                Rec.Insert();
            until TempDocumentEntry.Next() = 0;
    end;
}

