// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;

page 6903 "Expense Ledger Entries"
{
    ApplicationArea = BasicHR;
    Caption = 'Expense Ledger Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    Editable = false;
    PageType = List;
    Permissions = TableData "Expense Ledger Entry" = m;
    SourceTable = "Expense Ledger Entry";
    UsageCategory = History;
    AdditionalSearchTerms = 'Employee Check, Employee Expense, Pay Employee';

    AboutTitle = 'About expense ledger entries';
    AboutText = 'Review, filter, and analyze all posted expense reports and related ledger entries, including expense records processed without financial postings.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the posting date of the entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the document type of the entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the document number of the entry.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee number linked to the entry.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the expense user number linked to the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry description.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the currency code for the entry amount.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment method used for the entry.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the original entry amount.';
                }
                field("Original Amt. (LCY)"; Rec."Original Amt. (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the original entry amount in local currency (LCY).';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry amount.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry amount in local currency (LCY).';
                    Visible = false;
                }
                field("Non-Refundable Amount"; Rec."Non-Refundable Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the reduction applied to the entry amount.';
                }
                field("Non-Refundable Amount (LCY)"; Rec."Non-Refundable Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the reduction applied to the entry amount in local currency (LCY).';
                    Visible = false;
                }
                field("Reimbursable Amount"; Rec."Reimbursable Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount that can be reimbursed for this entry.';
                }
                field("Reimbursable Amt. (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the reimbursable amount for the entry in local currency (LCY).';
                }
                field("Refundable Amount"; Rec."Refundable Amount")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount refundable for this entry.';
                }
                field("Refundable Amount (LCY)"; Rec."Refundable Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the refundable amount for the entry in local currency (LCY).';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job number assigned to the entry.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the job task number assigned to the entry.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for global dimension 1 linked to this entry for analysis.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for global dimension 2 linked to this entry for analysis.';
                    Visible = Dim2Visible;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3 as defined in General Ledger Setup.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4 as defined in General Ledger Setup.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5 as defined in General Ledger Setup.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6 as defined in General Ledger Setup.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7 as defined in General Ledger Setup.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8 as defined in General Ledger Setup.';
                    Visible = Dim8Visible;
                }
            }
        }
        area(factboxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Scope = Repeater;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(Navigate)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                    trigger OnAction()
                    var
                        Navigate: Page Navigate;
                    begin
                        Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                        Navigate.Run();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
            group(Category_Expense)
            {
                Caption = 'Expense';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;
}