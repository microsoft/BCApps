// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Foundation.Navigate;

page 5237 "Employee Ledger Entries"
{
    ApplicationArea = BasicHR;
    Caption = 'Employee Ledger Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "Employee Ledger Entry" = m;
    SourceTable = "Employee Ledger Entry";
    UsageCategory = History;
    AdditionalSearchTerms = 'Employee Check, Employee Expense, Pay Employee';


    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Message to Recipient"; Rec."Message to Recipient")
                {
                    ApplicationArea = BasicHR;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = BasicHR;
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = BasicHR;
                }
                field("Original Amt. (LCY)"; Rec."Original Amt. (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount that the entry originally consisted of, in LCY.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = BasicHR;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = BasicHR;
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Amount to Apply"; Rec."Amount to Apply")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Applying Entry"; Rec."Applying Entry")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Exported to Payment File"; Rec."Exported to Payment File")
                {
                    ApplicationArea = BasicHR;
                    Editable = true;
                    Visible = false;
                }
                field("Payment Reference"; Rec."Payment Reference")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the payment of the employee document.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = BasicHR;
                    Editable = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim2Visible;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
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
                action("Applied E&ntries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunObject = Page "Applied Employee Entries";
                    RunPageOnRec = true;
                    Scope = Repeater;
                    ToolTip = 'View the ledger entries that have been applied to this record.';
                }
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
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Empl. Ledger Entries";
                    RunPageLink = "Employee Ledger Entry No." = field("Entry No."),
                                  "Employee No." = field("Employee No.");
                    RunPageView = sorting("Employee Ledger Entry No.", "Posting Date");
                    Scope = Repeater;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of the all posted entries and adjustments related to a specific employee ledger entry';
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ActionApplyEntries)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this record to so that the related posted documents are closed as paid or refunded.';

                    trigger OnAction()
                    var
                        EmployeeLedgerEntry: Record "Employee Ledger Entry";
                        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
                    begin
                        EmployeeLedgerEntry.Copy(Rec);
                        EmplEntryApplyPostedEntries.ApplyEmplEntryFormEntry(EmployeeLedgerEntry);
                        Rec := EmployeeLedgerEntry;
                        Rec.Get(Rec."Entry No.");
                        CurrPage.Update();
                    end;
                }
                separator(Action9)
                {
                }
                action(UnapplyEntries)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Unapply Entries';
                    Ellipsis = true;
                    Image = UnApply;
                    Scope = Repeater;
                    ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                    trigger OnAction()
                    var
                        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
                    begin
                        EmplEntryApplyPostedEntries.UnApplyEmplLedgEntry(Rec."Entry No.");
                    end;
                }
                action(CreatePayment)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Create Payment';
                    Image = SuggestVendorPayments;
                    ToolTip = 'Create a payment journal based on the selected entries.';

                    trigger OnAction()
                    var
                        EmployeeLedgerEntry: Record "Employee Ledger Entry";
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GenJnlManagement: Codeunit GenJnlManagement;
                    begin
                        CurrPage.SetSelectionFilter(EmployeeLedgerEntry);
                        if CreateEmployeePayment.RunModal() = ACTION::OK then begin
                            CreateEmployeePayment.MakeGenJnlLines(EmployeeLedgerEntry);
                            GetBatchRecord(GenJournalBatch);
                            GenJnlManagement.TemplateSelectionFromBatch(GenJournalBatch);
                            Clear(CreateEmployeePayment);
                        end else
                            Clear(CreateEmployeePayment);
                    end;
                }
                action(ReverseTransaction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse Transaction';
                    Ellipsis = true;
                    Image = ReverseRegister;
                    Scope = Repeater;
                    ToolTip = 'Reverse an erroneous employee ledger entry.';

                    trigger OnAction()
                    var
                        ReversalEntry: Record "Reversal Entry";
                        ReversePaymentRec: Codeunit "Reverse Payment Rec. Journal";
                    begin
                        ReversePaymentRec.ErrorIfEntryIsNotReversable(Rec);
                        ReversalEntry.ReverseTransaction(Rec."Transaction No.");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ActionApplyEntries_Promoted; ActionApplyEntries)
                {
                }
                actionref(UnapplyEntries_Promoted; UnapplyEntries)
                {
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref(CreatePayment_Promoted; CreatePayment)
                {
                }
                actionref(ReverseTransaction_Promoted; ReverseTransaction)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Applied E&ntries_Promoted"; "Applied E&ntries")
                {
                }
                actionref("Detailed &Ledger Entries_Promoted"; "Detailed &Ledger Entries")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        CreateEmployeePayment: Page "Create Employee Payment";

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

    local procedure GetBatchRecord(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
    begin
        GenJournalTemplate.Reset();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        if GenJournalTemplate.FindFirst() then
            JournalTemplateName := GenJournalTemplate.Name;

        JournalBatchName := CreateEmployeePayment.GetBatchNumber();

        GenJournalTemplate.Get(JournalTemplateName);
        GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
    end;
}

