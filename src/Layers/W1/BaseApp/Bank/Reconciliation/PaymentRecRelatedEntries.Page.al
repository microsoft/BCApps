// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

page 496 "Payment Rec. Related Entries"
{
    PageType = NavigatePage;
    SourceTable = "Payment Rec. Related Entry";
    Caption = 'Reverse Payment Reconciliation Journal';
    Editable = true;
    RefreshOnActivate = true;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            label(RelatedEntriesLabel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select the entries that will be unapplied or reversed:';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Entry No. that was created by the Posted Payment Reconciliation Journal.';
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        VendorLedgerEntry: Record "Vendor Ledger Entry";
                        EmployeeLedgerEntry: Record "Employee Ledger Entry";
                        CustomerLedgerEntries: Page "Customer Ledger Entries";
                        VendorLedgerEntries: Page "Vendor Ledger Entries";
                        EmployeeLedgerEntries: Page "Employee Ledger Entries";
                    begin
                        case Rec."Entry Type" of
                            Rec."Entry Type"::Customer:
                                begin
                                    CustLedgerEntry.SetRange("Entry No.", Rec."Entry No.");
                                    CustomerLedgerEntries.SetTableView(CustLedgerEntry);
                                    CustomerLedgerEntries.Run();
                                end;
                            Rec."Entry Type"::Vendor:
                                begin
                                    VendorLedgerEntry.SetRange("Entry No.", Rec."Entry No.");
                                    VendorLedgerEntries.SetTableView(VendorLedgerEntry);
                                    VendorLedgerEntries.Run();
                                end;
                            Rec."Entry Type"::Employee:
                                begin
                                    EmployeeLedgerEntry.SetRange("Entry No.", Rec."Entry No.");
                                    EmployeeLedgerEntries.SetTableView(EmployeeLedgerEntry);
                                    EmployeeLedgerEntries.Run();
                                end;

                        end;
                    end;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the entry that was created by the posted payment reconciliation journal.';
                }
                field(Unapplied; Rec.ToUnapply)
                {
                    Caption = 'Unapply';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry created by the posted payment reconciliation journal will be unapplied.';
                    Enabled = ToUnapplyEnabled;
                    trigger OnValidate()
                    begin
                        if Rec.ToUnapply then
                            exit;
                        if not ToReverseEnabled then
                            exit;
                        Rec.ToReverse := false;
                    end;
                }
                field(Reversed; Rec.ToReverse)
                {
                    Caption = 'Reverse';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry created by the posted payment reconciliation journal will be reversed.';
                    Enabled = ToReverseEnabled;
                    trigger OnValidate()
                    begin
                        if not Rec.ToReverse then
                            exit;
                        if not ToUnapplyEnabled then
                            exit;
                        Rec.ToUnapply := true;
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ActionUnapplyManual)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Inspect Unapply';
                Image = UnApply;
                trigger OnAction()
                begin
                    ReversePaymentRecJournal.UnapplyEntry(Rec, true);
                end;
            }
            action(ActionReverseManual)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Inspect Reverse';
                Image = ReverseRegister;
                trigger OnAction()
                begin
                    ReversePaymentRecJournal.ReverseEntry(Rec, true);
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Back';
                Image = PreviousRecord;
                Visible = not ActionBackHidden;

                trigger OnAction()
                begin
                    ActionSelected := ActionSelected::Back;
                    CurrPage.Close();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Next';
                Image = NextRecord;

                trigger OnAction()
                begin
                    ActionSelected := ActionSelected::Next;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        ReversePaymentRecJournal: Codeunit "Reverse Payment Rec. Journal";
        ToUnapplyEnabled: Boolean;
        ToReverseEnabled: Boolean;
        ActionBackHidden: Boolean;
        ActionSelected: Option Nothing,Next,Back;
        BankAccountNo: Code[20];
        StatementNo: Code[20];

    trigger OnAfterGetRecord()
    begin
        ToUnapplyEnabled := not Rec.Unapplied;
        ToReverseEnabled := not Rec.Reversed;
    end;

    trigger OnOpenPage()
    begin
        ActionSelected := ActionSelected::Nothing;
        Rec.SetRange("Bank Account No.", BankAccountNo);
        Rec.SetRange("Statement No.", StatementNo);
        Rec.FilterGroup(2);
        Rec.SetFilter("Entry Type", '<>%1', Rec."Entry Type"::"Bank Account");
        Rec.FilterGroup(0);
    end;

    procedure HideBackAction()
    begin
        ActionBackHidden := true;
    end;

    procedure SetPaymentRecRelatedEntries(BankAccountNoToOpen: Code[20]; StatementNoToOpen: Code[20])
    begin
        BankAccountNo := BankAccountNoToOpen;
        StatementNo := StatementNoToOpen;
    end;

    procedure NextSelected(): Boolean
    begin
        exit(ActionSelected = ActionSelected::Next);
    end;

    procedure BackSelected(): Boolean
    begin
        exit(ActionSelected = ActionSelected::Back);
    end;

}
