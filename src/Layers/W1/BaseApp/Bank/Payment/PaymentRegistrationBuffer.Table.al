// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Table 981 "Payment Registration Buffer" serves as a temporary buffer for payment registration operations.
/// Stores customer ledger entry information for the payment registration workspace, enabling quick
/// payment entry and batch processing. Supports both individual and lump payment scenarios.
/// </summary>
/// <remarks>
/// Used exclusively as a temporary table (ReplicateData = false) for payment registration UI.
/// Integrates with customer ledger entries and supports payment tolerance and discount calculations.
/// Provides extensibility through integration events for custom payment processing logic.
/// </remarks>
table 981 "Payment Registration Buffer"
{
    Caption = 'Payment Registration Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Customer ledger entry number that this buffer record represents.
        /// </summary>
        field(1; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.';
        }
        /// <summary>
        /// Customer number or source account number for the payment.
        /// </summary>
        field(2; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        /// <summary>
        /// Document type of the customer ledger entry.
        /// </summary>
        field(3; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Document number of the customer ledger entry.
        /// </summary>
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Description of the customer ledger entry.
        /// </summary>
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Due date of the customer ledger entry.
        /// </summary>
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Customer name associated with the payment.
        /// </summary>
        field(7; Name; Text[100])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Remaining amount to be paid on the customer ledger entry.
        /// </summary>
        field(8; "Remaining Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        /// <summary>
        /// Indicates whether a payment has been made for this entry.
        /// </summary>
        field(9; "Payment Made"; Boolean)
        {
            Caption = 'Payment Made';

            trigger OnValidate()
            begin
                if not "Payment Made" then begin
                    "Amount Received" := 0;
                    "Date Received" := 0D;
                    "Remaining Amount" := "Original Remaining Amount";
                    "External Document No." := '';
                    exit;
                end;

                AutoFillDate();
                if "Amount Received" = 0 then
                    SuggestAmountReceivedBasedOnDate();
                UpdateRemainingAmount();
            end;
        }
        /// <summary>
        /// Date when the payment was received.
        /// </summary>
        field(10; "Date Received"; Date)
        {
            Caption = 'Date Received';

            trigger OnValidate()
            begin
                if "Date Received" <> 0D then
                    Validate("Payment Made", true);
            end;
        }
        /// <summary>
        /// Amount received for this payment entry.
        /// </summary>
        field(11; "Amount Received"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Received';

            trigger OnValidate()
            var
                MaximumRemainingAmount: Decimal;
            begin
                if "Limit Amount Received" then begin
                    MaximumRemainingAmount := GetMaximumPaymentAmountBasedOnDate();
                    if "Amount Received" > MaximumRemainingAmount then
                        "Amount Received" := MaximumRemainingAmount;
                end;

                AutoFillDate();
                "Payment Made" := true;
                UpdateRemainingAmount();
            end;
        }
        /// <summary>
        /// Original remaining amount before any payment processing.
        /// </summary>
        field(12; "Original Remaining Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Original Remaining Amount';
        }
        /// <summary>
        /// Remaining amount after applying payment discount.
        /// </summary>
        field(13; "Rem. Amt. after Discount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rem. Amt. after Discount';
        }
        /// <summary>
        /// Payment discount date for this customer ledger entry.
        /// </summary>
        field(14; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';

            trigger OnValidate()
            begin
                if "Pmt. Discount Date" <> 0D then
                    Validate("Payment Made", true);
            end;
        }
        /// <summary>
        /// Indicates whether the amount received should be limited to maximum allowable amount.
        /// </summary>
        field(15; "Limit Amount Received"; Boolean)
        {
            Caption = 'Limit Amount Received';
        }
        /// <summary>
        /// Payment method code used for this payment registration.
        /// </summary>
        field(16; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
        }
        /// <summary>
        /// Type of balancing account for the payment (G/L Account or Bank Account).
        /// </summary>
        field(17; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        /// <summary>
        /// Number of the balancing account for the payment.
        /// </summary>
        field(18; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        /// <summary>
        /// External document number for the payment registration.
        /// </summary>
        field(19; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
    }

    keys
    {
        key(Key1; "Ledger Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DueDateMsg: Label 'The payment is overdue. You can calculate interest for late payments from customers by choosing the Finance Charge Memo button.';
        PmtDiscMsg: Label 'Payment Discount Date is earlier than Date Received. Payment will be registered as partial payment.';

    procedure PopulateTable()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Customer: Record Customer;
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup.TestField("Bal. Account No.");

        Reset();
        DeleteAll();

        CustLedgerEntry.SetFilter("Document Type", '<>%1', CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Open, true);
        OnPopulateTableOnAfterCustLedgerEntrySetFilters(CustLedgerEntry, Rec);
        if CustLedgerEntry.FindSet() then
            repeat
                if Customer.Get(CustLedgerEntry."Customer No.") then begin
                    CustLedgerEntry.CalcFields("Remaining Amount");

                    Init();
                    "Ledger Entry No." := CustLedgerEntry."Entry No.";
                    "Source No." := CustLedgerEntry."Customer No.";
                    Name := Customer.Name;
                    "Document No." := CustLedgerEntry."Document No.";
                    "Document Type" := CustLedgerEntry."Document Type";
                    Description := CustLedgerEntry.Description;
                    "Due Date" := CustLedgerEntry."Due Date";
                    "Remaining Amount" := CustLedgerEntry."Remaining Amount";
                    "Original Remaining Amount" := CustLedgerEntry."Remaining Amount";
                    "Pmt. Discount Date" := CustLedgerEntry."Pmt. Discount Date";
                    "Rem. Amt. after Discount" := "Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible";
                    if CustLedgerEntry."Payment Method Code" <> '' then
                        "Payment Method Code" := CustLedgerEntry."Payment Method Code";
                    "Bal. Account Type" := Enum::"Payment Balance Account Type".FromInteger(PaymentRegistrationSetup."Bal. Account Type");
                    "Bal. Account No." := PaymentRegistrationSetup."Bal. Account No.";
                    "External Document No." := CustLedgerEntry."External Document No.";
                    OnPopulateTableOnBeforeInsert(Rec, CustLedgerEntry);
                    Insert();
                end;
            until CustLedgerEntry.Next() = 0;

        if FindSet() then;
    end;

    procedure Navigate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Navigate: Page Navigate;
    begin
        CustLedgerEntry.Get("Ledger Entry No.");
        Navigate.SetDoc(CustLedgerEntry."Posting Date", CustLedgerEntry."Document No.");
        Navigate.Run();
    end;

    procedure Reload()
    var
        TempDataSavePmtRegnBuf: Record "Payment Registration Buffer" temporary;
        TempRecSavePmtRegnBuf: Record "Payment Registration Buffer" temporary;
    begin
        TempRecSavePmtRegnBuf.Copy(Rec, true);

        SaveUserValues(TempDataSavePmtRegnBuf);

        PopulateTable();

        RestoreUserValues(TempDataSavePmtRegnBuf);

        Copy(TempRecSavePmtRegnBuf);
        if Get("Ledger Entry No.") then;
    end;

    local procedure SaveUserValues(var TempSavePmtRegnBuf: Record "Payment Registration Buffer" temporary)
    var
        TempWorkPmtRegnBuf: Record "Payment Registration Buffer" temporary;
    begin
        TempWorkPmtRegnBuf.Copy(Rec, true);
        TempWorkPmtRegnBuf.Reset();
        TempWorkPmtRegnBuf.SetRange("Payment Made", true);
        if TempWorkPmtRegnBuf.FindSet() then
            repeat
                TempSavePmtRegnBuf := TempWorkPmtRegnBuf;
                TempSavePmtRegnBuf.Insert();
            until TempWorkPmtRegnBuf.Next() = 0;
    end;

    local procedure RestoreUserValues(var TempSavePmtRegnBuf: Record "Payment Registration Buffer" temporary)
    begin
        if TempSavePmtRegnBuf.FindSet() then
            repeat
                if Get(TempSavePmtRegnBuf."Ledger Entry No.") then begin
                    "Payment Made" := TempSavePmtRegnBuf."Payment Made";
                    "Date Received" := TempSavePmtRegnBuf."Date Received";
                    "Pmt. Discount Date" := TempSavePmtRegnBuf."Pmt. Discount Date";
                    SuggestAmountReceivedBasedOnDate();
                    "Remaining Amount" := TempSavePmtRegnBuf."Remaining Amount";
                    "Amount Received" := TempSavePmtRegnBuf."Amount Received";
                    "External Document No." := TempSavePmtRegnBuf."External Document No.";
                    OnRestoreUserValuesOnBeforeModify(Rec, TempSavePmtRegnBuf);
                    Modify();
                end;
            until TempSavePmtRegnBuf.Next() = 0;
    end;

    procedure GetPmtDiscStyle(): Text
    begin
        if ("Pmt. Discount Date" < "Date Received") and ("Remaining Amount" <> 0) and ("Date Received" < "Due Date") then
            exit('Unfavorable');
        exit('');
    end;

    procedure GetDueDateStyle() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDueDateStyle(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if "Due Date" < "Date Received" then
            exit('Unfavorable');
        exit('');
    end;

    procedure GetWarning(): Text
    begin
        if "Date Received" <= "Pmt. Discount Date" then
            exit('');

        if "Date Received" > "Due Date" then
            exit(DueDateMsg);

        if "Remaining Amount" <> 0 then
            exit(PmtDiscMsg);

        exit('');
    end;

    local procedure AutoFillDate()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if "Date Received" = 0D then begin
            PaymentRegistrationSetup.Get(UserId);
            if PaymentRegistrationSetup."Auto Fill Date Received" then
                "Date Received" := WorkDate();
        end;
    end;

    local procedure SuggestAmountReceivedBasedOnDate()
    begin
        "Amount Received" := GetMaximumPaymentAmountBasedOnDate();
        if "Date Received" = 0D then
            exit;
        "Remaining Amount" := 0;
    end;

    local procedure GetMaximumPaymentAmountBasedOnDate(): Decimal
    begin
        if "Date Received" = 0D then
            exit(0);

        if "Date Received" <= "Pmt. Discount Date" then
            exit("Rem. Amt. after Discount");

        exit("Original Remaining Amount");
    end;

    local procedure UpdateRemainingAmount()
    begin
        if "Date Received" = 0D then
            exit;
        if Abs("Amount Received") >= Abs("Original Remaining Amount") then
            "Remaining Amount" := 0
        else
            if "Date Received" <= "Pmt. Discount Date" then begin
                if "Amount Received" >= "Rem. Amt. after Discount" then
                    "Remaining Amount" := 0
                else
                    "Remaining Amount" := "Original Remaining Amount" - "Amount Received";
            end else
                "Remaining Amount" := "Original Remaining Amount" - "Amount Received";
    end;

    /// <summary>
    /// Integration event raised before inserting a payment registration buffer record during table population.
    /// Enables custom modifications to buffer data before record insertion.
    /// </summary>
    /// <param name="PaymentRegistrationBuffer">Payment registration buffer record being inserted</param>
    /// <param name="CustLedgerEntry">Source customer ledger entry for the buffer record</param>
    [IntegrationEvent(false, false)]
    local procedure OnPopulateTableOnBeforeInsert(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after applying filters to customer ledger entries during table population.
    /// Enables custom filter modifications for payment registration processing.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entry with applied filters</param>
    /// <param name="PaymentRegistrationBuffer">Payment registration buffer context</param>
    [IntegrationEvent(false, false)]
    local procedure OnPopulateTableOnAfterCustLedgerEntrySetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var PaymentRegistrationBuffer: Record "Payment Registration Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying a payment registration buffer record during user value restoration.
    /// Enables custom logic before restoring user-entered payment values.
    /// </summary>
    /// <param name="PaymentRegistrationBuffer">Payment registration buffer record being modified</param>
    /// <param name="TempSavePmtRegnBuf">Temporary buffer containing saved user values</param>
    [IntegrationEvent(false, false)]
    local procedure OnRestoreUserValuesOnBeforeModify(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; var TempSavePmtRegnBuf: Record "Payment Registration Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised before determining the due date style for payment registration display.
    /// Enables custom styling logic for due date visualization.
    /// </summary>
    /// <param name="PaymentRegistrationBuffer">Payment registration buffer record</param>
    /// <param name="ReturnValue">Style value to be returned</param>
    /// <param name="IsHandled">Set to true to skip standard style determination</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDueDateStyle(var PaymentRegistrationBuffer: Record "Payment Registration Buffer"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;
}
