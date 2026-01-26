// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

page 10007 "Customer Credit Information"
{
    Caption = 'Customer Credit Information';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field(Contact; Rec.Contact)
            {
                ApplicationArea = Basic, Suite;
                Editable = ContactEditable;
                ToolTip = 'Specifies the contact person for the customer record.';
            }
            field("Phone No."; Rec."Phone No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = "Phone No.Editable";
                ToolTip = 'Specifies the customer''s phone number.';
            }
            field("Collection Method"; Rec."Collection Method")
            {
                ApplicationArea = Basic, Suite;
                Editable = "Collection MethodEditable";
                ToolTip = 'Specifies the method you normally use to collect payment from this customer, such as bank transfer or check.';
            }
            field(Blocked; Rec.Blocked)
            {
                ApplicationArea = Basic, Suite;
                Editable = BlockedEditable;
                ToolTip = 'Specifies if the customer is blocked from posting.';
            }
            group(Control39)
            {
                ShowCaption = false;
                field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Credit Limit (LCY)Editable";
                    ToolTip = 'Specifies the maximum credit (in LCY) that can be extended to the customer.';
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';
                }
                field("""Credit Limit (LCY)"" - ""Balance (LCY)"""; Rec."Credit Limit (LCY)" - Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the credit limit and the balance for the customer. The formula is credit limit minus balance.';
                }
                field("CustLedgerEntry[1].""Remaining Amt. (LCY)"""; CustLedgerEntry[1]."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown(1);
                    end;
                }
                label("Aging Date")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(Text000, WorkDate()));
                    Caption = 'Aging Date';
                    Editable = false;
                    ToolTip = 'Specifies the date when payment becomes overdue.';
                }
                field("CustLedgerEntry[2].""Remaining Amt. (LCY)"""; CustLedgerEntry[2]."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown(2);
                    end;
                }
                field("AgingTitle[4]"; AgingTitle[4])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(AgingTitle[3]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("CustLedgerEntry[3].""Remaining Amt. (LCY)"""; CustLedgerEntry[3]."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown(3);
                    end;
                }
                field("CustLedgerEntry[4].""Remaining Amt. (LCY)"""; CustLedgerEntry[4]."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        DrillDown(4);
                    end;
                }
            }
            field("Payment Terms Code"; Rec."Payment Terms Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = "Payment Terms CodeEditable";
                ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount on sales documents. By default, the payment term from the customer card is entered.';
            }
            field("Payment Method Code"; Rec."Payment Method Code")
            {
                ApplicationArea = Basic, Suite;
                Editable = "Payment Method CodeEditable";
                ToolTip = 'Specifies how the customer must pay for products on the sales document. By default, the payment method is copied from the customer card.';
            }
            field("LatestCustLedgerEntry.""Posting Date"""; LatestCustLedgerEntry."Posting Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Latest Payment Date';
                Editable = false;
                ToolTip = 'Specifies the date when a payment was last made.';

                trigger OnDrillDown()
                begin
                    DrillDown(0);
                end;
            }
            field("-LatestCustLedgerEntry.""Amount (LCY)"""; -LatestCustLedgerEntry."Amount (LCY)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Latest Payment Amount';
                Editable = false;
                ToolTip = 'Specifies the last payment amount that was made.';

                trigger OnDrillDown()
                begin
                    DrillDown(0);
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnInit()
    begin
        "Payment Method CodeEditable" := true;
        "Collection MethodEditable" := true;
        "Payment Terms CodeEditable" := true;
        "Credit Limit (LCY)Editable" := true;
        BlockedEditable := true;
        "Phone No.Editable" := true;
        ContactEditable := true;
        // Default the Aging Period to 30D
        Evaluate(AgingPeriod, '<30D>');
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    begin
        // Initialize Record Variables
        LatestCustLedgerEntry.Reset();
        LatestCustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date");
        LatestCustLedgerEntry.SetRange("Document Type", LatestCustLedgerEntry."Document Type"::Payment);
        for I := 1 to ArrayLen(CustLedgerEntry) do begin
            CustLedgerEntry[I].Reset();
            CustLedgerEntry[I].SetCurrentKey("Customer No.", Open, Positive, "Due Date");
            CustLedgerEntry[I].SetRange(Open, true);
        end;
        // Turn off editability on Certain fields by default
        OnCreditManagementForm(false);
    end;

    var
        LatestCustLedgerEntry: Record "Cust. Ledger Entry";
        AgingTitle: array[4] of Text[30];
        AgingPeriod: DateFormula;
        I: Integer;
        PeriodStart: Date;
        PeriodEnd: Date;
        Text000: Label 'Aging as of %1 (showing days overdue)';
        Text002: Label 'Not Yet Due';
        Text003: Label 'Over %1 Days';
        Text004: Label '%1-%2 Days';
        ContactEditable: Boolean;
        "Phone No.Editable": Boolean;
        BlockedEditable: Boolean;
        "Credit Limit (LCY)Editable": Boolean;
        "Payment Terms CodeEditable": Boolean;
        "Collection MethodEditable": Boolean;
        "Payment Method CodeEditable": Boolean;

    protected var
        CustLedgerEntry: array[4] of Record "Cust. Ledger Entry";

    procedure OnCreditManagementForm(SetOnCreditManagementForm: Boolean)
    begin
        // Make certain Fields editable
        ContactEditable := SetOnCreditManagementForm;
        "Phone No.Editable" := SetOnCreditManagementForm;
        BlockedEditable := SetOnCreditManagementForm;
        "Credit Limit (LCY)Editable" := SetOnCreditManagementForm;
        "Payment Terms CodeEditable" := SetOnCreditManagementForm;
        "Collection MethodEditable" := SetOnCreditManagementForm;
        "Payment Method CodeEditable" := SetOnCreditManagementForm;
    end;

    procedure CalculateAgingForPeriod(PeriodBeginDate: Date; PeriodEndDate: Date; Index: Integer)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        NumDaysToBegin: Integer;
        NumDaysToEnd: Integer;
    begin
        // Calculate the Aged Balance for a particular Date Range
        if PeriodEndDate = 0D then
            CustLedgerEntry[Index].SetFilter("Due Date", '%1..', PeriodBeginDate)
        else
            CustLedgerEntry[Index].SetRange("Due Date", PeriodBeginDate, PeriodEndDate);

        CustLedgerEntry2.Copy(CustLedgerEntry[Index]);
        CustLedgerEntry[Index]."Remaining Amt. (LCY)" := 0;
        if CustLedgerEntry2.Find('-') then
            repeat
                CustLedgerEntry2.CalcFields("Remaining Amt. (LCY)");
                CustLedgerEntry[Index]."Remaining Amt. (LCY)" :=
                  CustLedgerEntry[Index]."Remaining Amt. (LCY)" + CustLedgerEntry2."Remaining Amt. (LCY)";
            until CustLedgerEntry2.Next() = 0;

        if PeriodBeginDate <> 0D then
            NumDaysToBegin := WorkDate() - PeriodBeginDate;
        if PeriodEndDate <> 0D then
            NumDaysToEnd := WorkDate() - PeriodEndDate;
        if PeriodEndDate = 0D then
            AgingTitle[Index] := Text002
        else
            if PeriodBeginDate = 0D then
                AgingTitle[Index] := StrSubstNo(Text003, NumDaysToEnd - 1)
            else
                AgingTitle[Index] := StrSubstNo(Text004, NumDaysToEnd, NumDaysToBegin);
    end;

    procedure CalculateAging()
    begin
        // Calculate the Entire Aging (four Periods)
        for I := 1 to ArrayLen(CustLedgerEntry) do begin
            case I of
                1:
                    begin
                        PeriodEnd := 0D;
                        PeriodStart := WorkDate();
                    end;
                ArrayLen(CustLedgerEntry):
                    begin
                        PeriodEnd := PeriodStart - 1;
                        PeriodStart := 0D;
                    end;
                else begin
                    PeriodEnd := PeriodStart - 1;
                    PeriodStart := CalcDate('-' + Format(AgingPeriod), PeriodStart);
                end;
            end;
            CalculateAgingForPeriod(PeriodStart, PeriodEnd, I);
        end;
    end;

    procedure GetLatestPayment()
    begin
        // Find the Latest Payment
        if LatestCustLedgerEntry.FindLast() then
            LatestCustLedgerEntry.CalcFields("Amount (LCY)")
        else
            LatestCustLedgerEntry.Init();
    end;

    procedure ChangeCustomer()
    begin
        // Change the Customer Filters
        LatestCustLedgerEntry.SetRange("Customer No.", Rec."No.");
        for I := 1 to ArrayLen(CustLedgerEntry) do
            CustLedgerEntry[I].SetRange("Customer No.", Rec."No.");
    end;

    procedure DrillDown(Index: Integer)
    begin
        if Index = 0 then
            PAGE.RunModal(PAGE::"Customer Ledger Entries", LatestCustLedgerEntry)
        else
            PAGE.RunModal(PAGE::"Customer Ledger Entries", CustLedgerEntry[Index]);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        ChangeCustomer();
        GetLatestPayment();
        CalculateAging();
    end;
}

