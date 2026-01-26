// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Customer;

page 3010834 "LSV Journal"
{
    Caption = 'LSV Journal';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "LSV Journal Line";

    layout
    {
        area(content)
        {
            field(CurrJourNumber; CurrJourNumber)
            {
                ApplicationArea = Suite;
                Caption = 'Journal No.';
                Editable = false;
                ToolTip = 'Specifies the number of the journal.';

                trigger OnValidate()
                begin
                    CurrJourNumberOnAfterValidate();
                end;
            }
            repeater(JourLines)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = CustomerNoEditable;
                    ToolTip = 'Specifies the customer number that belongs to the LSV journal line.';

                    trigger OnValidate()
                    begin
                        Rec."LSV Journal No." := CurrJourNumber;
                    end;
                }
                field("Collection Amount"; Rec."Collection Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = CollectionAmountEditable;
                    ToolTip = 'Specifies the total amount for the entries for the collection.';
                }
                field("LSV Status"; Rec."LSV Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the LSV journal line.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = AppliesToDocNoEditable;
                    ToolTip = 'Specifies the Document No. of the customer ledger entry the LSV journal line is related to.';

                    trigger OnValidate()
                    begin
                        Rec."LSV Journal No." := CurrJourNumber;
                    end;
                }
                field("Cust. Ledg. Entry No."; Rec."Cust. Ledg. Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = CustLedgEntryNoEditable;
                    ToolTip = 'Specifies the Entry No. of the customer ledger entry the LSV journal line is related to.';

                    trigger OnValidate()
                    begin
                        Rec."LSV Journal No." := CurrJourNumber;
                    end;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = RemainingAmountEditable;
                    ToolTip = 'Specifies the remaining amount for the current LSV journal line.';
                }
                field("Pmt. Discount"; Rec."Pmt. Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PmtDiscountEditable;
                    ToolTip = 'Specifies the sum of the payment discount amounts granted on the selected LSV journal line.';
                }
                field("DD Rejection Reason"; Rec."DD Rejection Reason")
                {
                    ToolTip = 'Specifies the reason why the DebitDirect transaction was rejected.';
                    Visible = false;
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct debit collection of payments.';
                }
            }
            field("LSVJournal.""Currency Code"""; LSVJournal."Currency Code")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Currency Code';
                Editable = false;
                ToolTip = 'Specifies the currency. ';
            }
            field(TotalAmount; TotalAmount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Total Amount';
                Editable = false;
                ToolTip = 'Specifies the total of all amount on journal lines.';
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Account)
            {
                Caption = 'Account';
                action("Customer Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Card';
                    Image = CustomerList;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = field("Customer No.");
                    ToolTip = 'Open the related customer card.';
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                action("LSV Suggest Collection")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Suggest Collection';
                    Image = SuggestCustomerPayments;
                    ToolTip = 'Transfers open invoices to the LSV Journal. Customer entries are only suggested in CHF and EUR. Only invoices from customers that have a payment method code that matches the code entered in the LSV Payment Method Code field in the LSV Setup window are considered.';

                    trigger OnAction()
                    begin
                        Clear(LSVCollectSuggestion);
                        LSVCollectSuggestion.SetGlobals(CurrJourNumber);
                        LSVCollectSuggestion.RunModal();
                    end;
                }
                action("P&rint Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&rint Journal';
                    Image = Print;
                    ToolTip = 'View the journal contents in a report.';

                    trigger OnAction()
                    begin
                        Clear(LSVCollectionJournal);
                        LSVCollectionJournal.SetGlobals(Rec);
                        LSVCollectionJournal.RunModal();
                    end;
                }
                action("&Close Collection")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Close Collection';
                    Image = ReleaseDoc;
                    ToolTip = 'Complete the payment collection.';

                    trigger OnAction()
                    begin
                        Clear(LsvCloseCollection);
                        LSVJournal.Reset();
                        LSVJournal.Get(Rec."LSV Journal No.");
                        LsvCloseCollection.SetGlobals(LSVJournal);
                        LsvCloseCollection.Run();
                        UpdateForm();
                    end;
                }
                separator(Action1000007)
                {
                }
                action("Modify &Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Modify &Posting Date';
                    Image = ChangeDate;
                    ToolTip = 'Change one or more posting dates in the journal.';

                    trigger OnAction()
                    begin
                        LsvMgt.ModifyPostingDate(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        xRec := Rec;
        UpdateBalance();
    end;

    trigger OnClosePage()
    begin
        LSVJournal.Get(Rec."LSV Journal No.");
        LSVJournal.Validate("LSV Status");
        LSVJournal.Modify();
    end;

    trigger OnInit()
    begin
        CustomerNoEditable := true;
        CollectionAmountEditable := true;
        AppliesToDocNoEditable := true;
        CustLedgEntryNoEditable := true;
        RemainingAmountEditable := true;
        PmtDiscountEditable := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."LSV Journal No." := CurrJourNumber;
    end;

    trigger OnOpenPage()
    begin
        if Rec."LSV Journal No." = 0 then
            Rec.FindFirst();

        CurrJourNumber := Rec."LSV Journal No.";
        Rec.FilterGroup := 2;
        Rec.SetRange("LSV Journal No.", CurrJourNumber);
        Rec.FilterGroup := 0;

        UpdateForm();
    end;

    var
        TempLSVJournalLine: Record "LSV Journal Line";
        LSVJournal: Record "LSV Journal";
        LSVCollectSuggestion: Report "LSV Suggest Collection";
        LSVCollectionJournal: Report "LSV Collection Journal";
        LsvCloseCollection: Report "LSV Close Collection";
        LsvMgt: Codeunit LSVMgt;
        CurrJourNumber: Integer;
        TotalAmount: Decimal;
        CustomerNoEditable: Boolean;
        CollectionAmountEditable: Boolean;
        AppliesToDocNoEditable: Boolean;
        CustLedgEntryNoEditable: Boolean;
        RemainingAmountEditable: Boolean;
        PmtDiscountEditable: Boolean;

    [Scope('OnPrem')]
    procedure UpdateForm()
    begin
        LSVJournal.Reset();
        LSVJournal.Get(CurrJourNumber);
        if LSVJournal."LSV Status" <> LSVJournal."LSV Status"::Edit then
            if LSVJournal."LSV Status" = LSVJournal."LSV Status"::Finished then
                CurrPage.Editable(false)
            else begin
                CustomerNoEditable := false;
                CollectionAmountEditable := false;
                AppliesToDocNoEditable := false;
                CustLedgEntryNoEditable := false;
                RemainingAmountEditable := false;
                PmtDiscountEditable := false;
            end
        else
            CurrPage.Editable(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateBalance()
    begin
        TotalAmount := 0;
        TempLSVJournalLine.Reset();

        TempLSVJournalLine.Copy(Rec);

        if TempLSVJournalLine.FindSet() then
            repeat
                TotalAmount := TotalAmount + TempLSVJournalLine."Collection Amount";
            until TempLSVJournalLine.Next() = 0;
    end;

    local procedure CurrJourNumberOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        Rec.FilterGroup := 2;
        Rec.SetRange("LSV Journal No.", LSVJournal."No.");
        Rec.FilterGroup := 0;
        if Rec.FindFirst() then;

        CurrPage.Update(false);
        UpdateForm();
        UpdateBalance();
    end;
}

