// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Page 1205 "Credit Transfer Registers" displays a list of credit transfer register entries.
/// Provides overview and management of payment file exports, including re-export functionality
/// and history tracking. Used to monitor and manage exported payment batches.
/// </summary>
/// <remarks>
/// Source table: Credit Transfer Register. Read-only list page for viewing export history,
/// status tracking, and file re-export operations. Supports drill-down to individual entries.
/// </remarks>
page 1205 "Credit Transfer Registers"
{
    AdditionalSearchTerms = 'payment file export,bank file export,re-export payment file,payment history';
    ApplicationArea = Basic, Suite;
    Caption = 'Credit Transfer Registers';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Credit Transfer Register";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Identifier; Rec.Identifier)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a serial number for a successful credit transfer. Failed file exports are excluded from the sequence of serial numbers. For more information, see the Status field.';
                }
#pragma warning disable AA0100
                field("FORMAT(""Created Date-Time"")"; Format(Rec."Created Date-Time"))
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Created Date-Time';
                    Editable = false;
                    ToolTip = 'Specifies when the credit transfer was made.';
                }
                field("Created by User"; Rec."Created by User")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies which user made the credit transfer.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the payment file export for this credit transfer. The field is read-only.';
                }
                field("No. of Transfers"; Rec."No. of Transfers")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies how many credit transfers the exported file covers.';
                }
                field("From Bank Account No."; Rec."From Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of your bank account from which the credit transfer was made.';
                }
                field("From Bank Account Name"; Rec."From Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of your bank account from which the credit transfer was made.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control9; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control10; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Entries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Entries';
                Image = List;
                RunObject = Page "Credit Transfer Reg. Entries";
                RunPageLink = "Credit Transfer Register No." = field("No.");
                ShortCutKey = 'Return';
                ToolTip = 'Specify the credit transfer entries that are related to the payment file export for a selected credit transfer.';
            }
            action(ReexportHistory)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reexported Payments History';
                Image = History;
                RunObject = Page "Credit Trans Re-export History";
                RunPageLink = "Credit Transfer Register No." = field("No.");
                ToolTip = 'View a list of payment files that have already been re-exported.';
            }
        }
        area(processing)
        {
            action("Reexport Payments to File")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reexport Payments to File';
                Image = ExportElectronicDocument;
                ToolTip = 'Export payments for the selected credit transfers to a bank file. The payments were originally exported from the Payment Journal window.';

                trigger OnAction()
                begin
                    Rec.Reexport();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Reexport Payments to File_Promoted"; "Reexport Payments to File")
                {
                }
                actionref(Entries_Promoted; Entries)
                {
                }
                actionref(ReexportHistory_Promoted; ReexportHistory)
                {
                }
            }
        }
    }
}

