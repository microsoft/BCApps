// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Table 1206 "Credit Transfer Entry" stores individual payment entries for credit transfers.
/// Each entry represents a single payment within a credit transfer register, containing details
/// about the account, amount, recipient information, and applied ledger entries.
/// </summary>
/// <remarks>
/// Integrates with Credit Transfer Register for batch processing and supports customer, vendor,
/// and employee payment types. Provides extensibility through integration events for recipient data
/// population and applies-to entry retrieval.
/// </remarks>
table 1206 "Credit Transfer Entry"
{
    Caption = 'Credit Transfer Entry';
    DataCaptionFields = "Account Type", "Account No.", "Transaction ID";
    DrillDownPageID = "Credit Transfer Reg. Entries";
    LookupPageID = "Credit Transfer Reg. Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference number of the credit transfer register containing this entry.
        /// </summary>
        field(1; "Credit Transfer Register No."; Integer)
        {
            Caption = 'Credit Transfer Register No.';
            TableRelation = "Credit Transfer Register";
        }
        /// <summary>
        /// Sequential entry number within the credit transfer register.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Type of account for the credit transfer (Customer, Vendor, or Employee).
        /// </summary>
        field(3; "Account Type"; Enum "Credit Transfer Account Type")
        {
            Caption = 'Account Type';
        }
        /// <summary>
        /// Account number for the credit transfer recipient.
        /// </summary>
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor;
        }
        /// <summary>
        /// Ledger entry number that this credit transfer applies to.
        /// </summary>
        field(5; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
            TableRelation = if ("Account Type" = const(Customer)) "Cust. Ledger Entry"
            else
            if ("Account Type" = const(Vendor)) "Vendor Ledger Entry";
        }
        /// <summary>
        /// Date when the credit transfer should be processed.
        /// </summary>
        field(6; "Transfer Date"; Date)
        {
            Caption = 'Transfer Date';
        }
        /// <summary>
        /// Currency code for the credit transfer amount.
        /// </summary>
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        /// <summary>
        /// Amount to be transferred in the specified currency.
        /// </summary>
        field(8; "Transfer Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Transfer Amount';
        }
        /// <summary>
        /// Unique transaction identifier for the credit transfer.
        /// </summary>
        field(9; "Transaction ID"; Text[35])
        {
            Caption = 'Transaction ID';
        }
        /// <summary>
        /// Indicates whether the credit transfer has been canceled.
        /// </summary>
        field(10; Canceled; Boolean)
        {
            CalcFormula = exist("Credit Transfer Register" where("No." = field("Credit Transfer Register No."),
                                                                  Status = const(Canceled)));
            Caption = 'Canceled';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Bank account number of the recipient for the credit transfer.
        /// </summary>
        field(11; "Recipient Bank Acc. No."; Code[50])
        {
            Caption = 'Recipient Bank Account';
        }
        /// <summary>
        /// Message to be included with the credit transfer to the recipient.
        /// </summary>
        field(12; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
        /// <summary>
        /// International Bank Account Number (IBAN) of the recipient.
        /// </summary>
        field(13; "Recipient IBAN"; Code[50])
        {
            Caption = 'Recipient IBAN';
        }
        /// <summary>
        /// Bank account number of the recipient.
        /// </summary>
        field(14; "Recipient Bank Account No."; Code[30])
        {
            Caption = 'Recipient Bank Account No.';
        }
        /// <summary>
        /// Name of the credit transfer recipient.
        /// </summary>
        field(15; "Recipient Name"; Text[100])
        {
            Caption = 'Recipient Name';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Credit Transfer Register No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";

    /// <summary>
    /// Creates a new credit transfer entry with the specified parameters.
    /// </summary>
    /// <param name="RegisterNo">Credit transfer register number</param>
    /// <param name="EntryNo">Entry number (0 for auto-generation)</param>
    /// <param name="GenJnlAccountType">General journal account type</param>
    /// <param name="AccountNo">Account number for the transfer</param>
    /// <param name="LedgerEntryNo">Applied ledger entry number</param>
    /// <param name="TransferDate">Date of the transfer</param>
    /// <param name="CurrencyCode">Currency code for the transfer</param>
    /// <param name="TransferAmount">Amount to transfer</param>
    /// <param name="TransActionID">Transaction identifier</param>
    /// <param name="RecipientBankAccount">Recipient bank account code</param>
    /// <param name="MessageToRecipient">Message for the recipient</param>
    procedure CreateNew(RegisterNo: Integer; EntryNo: Integer; GenJnlAccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LedgerEntryNo: Integer; TransferDate: Date; CurrencyCode: Code[10]; TransferAmount: Decimal; TransActionID: Text[35]; RecipientBankAccount: Code[20]; MessageToRecipient: Text[140])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        "Credit Transfer Register No." := RegisterNo;
        if EntryNo = 0 then begin
            SetRange("Credit Transfer Register No.", RegisterNo);
            LockTable();
            if FindLast() then;
            "Entry No." += 1;
        end else
            "Entry No." := EntryNo;
        Init();
        GenJnlLine.Init();
        case GenJnlAccountType of
            GenJnlLine."Account Type"::Customer:
                "Account Type" := "Account Type"::Customer;
            GenJnlLine."Account Type"::Vendor:
                "Account Type" := "Account Type"::Vendor;
            GenJnlLine."Account Type"::Employee:
                "Account Type" := "Account Type"::Employee;
        end;
        OnCreateNewOnAfterInitAccountType(Rec, GenJnlAccountType);

        "Account No." := AccountNo;
        "Applies-to Entry No." := LedgerEntryNo;
        "Transfer Date" := TransferDate;
        "Currency Code" := CurrencyCode;
        "Transfer Amount" := TransferAmount;
        "Transaction ID" := TransActionID;
        "Recipient Bank Acc. No." := RecipientBankAccount;
        "Message to Recipient" := MessageToRecipient;
        FillRecipientData();
        Insert();
    end;

    /// <summary>
    /// Fills recipient data fields based on the account type and account number.
    /// Retrieves recipient name, IBAN, and bank account number from related tables.
    /// </summary>
    procedure FillRecipientData()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Employee: Record Employee;
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        if "Account No." = '' then begin
            "Recipient Name" := '';
            "Recipient IBAN" := '';
            "Recipient Bank Account No." := '';
            exit;
        end;
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if "Recipient Name" = '' then
                        if Customer.Get("Account No.") then
                            "Recipient Name" := Customer.Name;
                    if ("Recipient IBAN" = '') and ("Recipient Bank Account No." = '') then
                        if CustomerBankAccount.Get("Account No.", "Recipient Bank Acc. No.") then begin
                            "Recipient IBAN" := CustomerBankAccount.IBAN;
                            "Recipient Bank Account No." := CustomerBankAccount."Bank Account No.";
                        end;
                end;
            "Account Type"::Vendor:
                begin
                    if "Recipient Name" = '' then
                        if Vendor.Get("Account No.") then
                            "Recipient Name" := Vendor.Name;
                    if ("Recipient IBAN" = '') and ("Recipient Bank Account No." = '') then
                        if VendorBankAccount.Get("Account No.", "Recipient Bank Acc. No.") then begin
                            "Recipient IBAN" := VendorBankAccount.IBAN;
                            "Recipient Bank Account No." := VendorBankAccount."Bank Account No.";
                        end;
                end;
            "Account Type"::Employee:
                begin
                    if "Recipient Name" = '' then
                        if Employee.Get("Account No.") then
                            "Recipient Name" := Employee.FullName();
                    if ("Recipient IBAN" = '') and ("Recipient Bank Account No." = '') then begin
                        "Recipient IBAN" := Employee.IBAN;
                        "Recipient Bank Account No." := Employee."Bank Account No.";
                    end;
                end;
        end;

        OnAfterFillRecipientData(Rec);
    end;

    local procedure GetAppliesToEntry(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        CVLedgerEntryBuffer.Init();
        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if CustLedgerEntry."Entry No." <> "Applies-to Entry No." then
                        if CustLedgerEntry.Get("Applies-to Entry No.") then
                            CustLedgerEntry.CalcFields(Amount, "Remaining Amount")
                        else
                            Clear(CustLedgerEntry);
                    CVLedgerEntryBuffer.CopyFromCustLedgEntry(CustLedgerEntry)
                end;
            "Account Type"::Vendor:
                begin
                    if VendLedgerEntry."Entry No." <> "Applies-to Entry No." then
                        if VendLedgerEntry.Get("Applies-to Entry No.") then
                            VendLedgerEntry.CalcFields(Amount, "Remaining Amount")
                        else
                            Clear(VendLedgerEntry);
                    CVLedgerEntryBuffer.CopyFromVendLedgEntry(VendLedgerEntry)
                end;
            "Account Type"::Employee:
                begin
                    if EmployeeLedgerEntry."Entry No." <> "Applies-to Entry No." then
                        if EmployeeLedgerEntry.Get("Applies-to Entry No.") then
                            EmployeeLedgerEntry.CalcFields(Amount, "Remaining Amount")
                        else
                            Clear(EmployeeLedgerEntry);
                    CVLedgerEntryBuffer.CopyFromEmplLedgEntry(EmployeeLedgerEntry)
                end;
        end;

        OnAfterGetAppliesToEntry(Rec, CVLedgerEntryBuffer);
    end;

    /// <summary>
    /// Returns the document number from the applied ledger entry.
    /// </summary>
    /// <returns>Document number of the applied entry</returns>
    procedure AppliesToEntryDocumentNo(): Code[20]
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Document No.");
    end;

    /// <summary>
    /// Returns the description from the applied ledger entry.
    /// </summary>
    /// <returns>Description of the applied entry</returns>
    procedure AppliesToEntryDescription(): Text
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer.Description);
    end;

    /// <summary>
    /// Returns the posting date from the applied ledger entry.
    /// </summary>
    /// <returns>Posting date of the applied entry</returns>
    procedure AppliesToEntryPostingDate(): Date
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Posting Date");
    end;

    /// <summary>
    /// Returns the currency code from the applied ledger entry.
    /// </summary>
    /// <returns>Currency code of the applied entry</returns>
    procedure AppliesToEntryCurrencyCode(): Code[10]
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Currency Code");
    end;

    /// <summary>
    /// Returns the original amount from the applied ledger entry.
    /// </summary>
    /// <returns>Amount of the applied entry</returns>
    procedure AppliesToEntryAmount(): Decimal
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer.Amount);
    end;

    /// <summary>
    /// Returns the remaining amount from the applied ledger entry.
    /// </summary>
    /// <returns>Remaining amount of the applied entry</returns>
    procedure AppliesToEntryRemainingAmount(): Decimal
    var
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
    begin
        GetAppliesToEntry(CVLedgerEntryBuffer);
        exit(CVLedgerEntryBuffer."Remaining Amount");
    end;

    /// <summary>
    /// Integration event raised after filling recipient data from account information.
    /// Enables custom logic for populating additional recipient fields.
    /// </summary>
    /// <param name="CreditTransferEntry">Credit transfer entry being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillRecipientData(var CreditTransferEntry: Record "Credit Transfer Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after retrieving applies-to entry information.
    /// Enables modification of the CV ledger entry buffer before it is used.
    /// </summary>
    /// <param name="CreditTransferEntry">Credit transfer entry being processed</param>
    /// <param name="CVLedgerEntryBuffer">CV ledger entry buffer with applied entry data</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliesToEntry(var CreditTransferEntry: Record "Credit Transfer Entry"; var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    /// <summary>
    /// Integration event raised after initializing account type during CreateNew procedure.
    /// Enables custom logic for handling additional account type mappings.
    /// </summary>
    /// <param name="CreditTransferEntry">Credit transfer entry being created</param>
    /// <param name="GenJnlAccountType">General journal account type</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateNewOnAfterInitAccountType(var CreditTransferEntry: Record "Credit Transfer Entry"; GenJnlAccountType: Enum "Gen. Journal Account Type")
    begin
    end;
}
