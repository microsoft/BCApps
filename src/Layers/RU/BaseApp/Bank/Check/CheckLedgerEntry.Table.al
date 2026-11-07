// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;
using System.Security.AccessControl;

/// <summary>
/// Tracks the lifecycle and status of physical and electronic checks issued from bank accounts.
/// Maintains complete audit trail from creation through voiding with bank reconciliation support.
/// </summary>
/// <remarks>
/// Integrates with Bank Account Ledger Entry, Bank Account Reconciliation, and Positive Pay functionality.
/// Supports check printing, electronic payment transmission, and financial voiding processes.
/// Extensible through OnAfterCopyFromBankAccLedgEntry and OnAfterGetPayee events.
/// </remarks>
table 272 "Check Ledger Entry"
{
    Caption = 'Check Ledger Entry';
    DrillDownPageID = "Check Ledger Entries";
    LookupPageID = "Check Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique sequential identifier for the check ledger entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        /// <summary>
        /// Bank account from which the check was issued or payment was made.
        /// </summary>
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            ToolTip = 'Specifies the number of the bank account used for the check ledger entry.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Reference to the corresponding bank account ledger entry that created this check.
        /// </summary>
        field(3; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            ToolTip = 'Specifies the entry number of the bank account ledger entry from which the check ledger entry was created.';
            TableRelation = "Bank Account Ledger Entry";
        }
        /// <summary>
        /// Date when the check transaction was posted to the general ledger.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the check ledger entry.';
        }
        /// <summary>
        /// Type of document that generated the check (typically Payment or Refund).
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type linked to the check ledger entry. For example, Payment.';
        }
        /// <summary>
        /// Document number associated with the check transaction.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number on the check ledger entry.';
        }
        /// <summary>
        /// Descriptive text explaining the purpose or payee of the check.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a printing description for the check ledger entry.';
        }
        /// <summary>
        /// Amount of the check in the bank account's currency.
        /// </summary>
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount on the check ledger entry.';
        }
        /// <summary>
        /// Date printed or written on the physical check.
        /// </summary>
        field(9; "Check Date"; Date)
        {
            Caption = 'Check Date';
            ToolTip = 'Specifies the check date if a check is printed.';
        }
        /// <summary>
        /// Check number as printed on the physical check or assigned for electronic payments.
        /// </summary>
        field(10; "Check No."; Code[20])
        {
            Caption = 'Check No.';
            ToolTip = 'Specifies the check number if a check is printed.';
        }
        /// <summary>
        /// Indicates whether this represents a complete check or partial check payment.
        /// </summary>
        field(11; "Check Type"; Option)
        {
            Caption = 'Check Type';
            ToolTip = 'Specifies the type check, such as Manual.';
            OptionCaption = 'Total Check,Partial Check';
            OptionMembers = "Total Check","Partial Check";
        }
        /// <summary>
        /// Method of payment transmission (Manual Check, Computer Check, Electronic Payment).
        /// </summary>
        field(12; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';
            ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
        }
        /// <summary>
        /// Current lifecycle status of the check from creation through final disposition.
        /// </summary>
        field(13; "Entry Status"; Option)
        {
            Caption = 'Entry Status';
            ToolTip = 'Specifies the printing (and posting) status of the check ledger entry.';
            OptionCaption = ',Printed,Voided,Posted,Financially Voided,Test Print,Exported,Transmitted';
            OptionMembers = ,Printed,Voided,Posted,"Financially Voided","Test Print",Exported,Transmitted;
        }
        /// <summary>
        /// Original status before any voiding or status changes occurred.
        /// </summary>
        field(14; "Original Entry Status"; Option)
        {
            Caption = 'Original Entry Status';
            ToolTip = 'Specifies the status of the entry before you changed it.';
            OptionCaption = ' ,Printed,Voided,Posted,Financially Voided';
            OptionMembers = " ",Printed,Voided,Posted,"Financially Voided";
        }
        /// <summary>
        /// Type of account being paid (Vendor, Customer, G/L Account, etc.).
        /// </summary>
        field(15; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
        }
        /// <summary>
        /// Account number of the payee receiving the check payment.
        /// </summary>
        field(16; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        /// <summary>
        /// Indicates whether the check entry has outstanding amounts requiring reconciliation.
        /// </summary>
        field(17; Open; Boolean)
        {
            Caption = 'Open';
            ToolTip = 'Specifies whether the entry has been fully applied to.';
        }
        /// <summary>
        /// Status of check reconciliation with bank statements.
        /// </summary>
        field(18; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            ToolTip = 'Specifies that the structure of the lines is based on the chart of cost types. You define up to seven cost centers and cost objects that appear as columns in the report.';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        /// <summary>
        /// Bank statement number where this check was reconciled.
        /// </summary>
        field(19; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            ToolTip = 'Specifies the bank account statement that the check ledger entry has been applied to, if the Statement Status is Bank Account Ledger Applied or Check Ledger Applied.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        /// <summary>
        /// Line number within the bank statement where this check appears.
        /// </summary>
        field(20; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            ToolTip = 'Specifies the statement line that the check ledger entry has been applied to, if the Statement Status is Bank Account Ledger Applied or Check Ledger Applied.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." where("Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."));
        }
        /// <summary>
        /// User who last modified the check ledger entry.
        /// </summary>
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// External reference number from the original source document.
        /// </summary>
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        /// <summary>
        /// Reference to data exchange entry for electronic payment processing.
        /// </summary>
        field(23; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        /// <summary>
        /// Reference to data exchange entry used when voiding electronic payments.
        /// </summary>
        field(24; "Data Exch. Voided Entry No."; Integer)
        {
            Caption = 'Data Exch. Voided Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        /// <summary>
        /// Indicates whether check information has been exported for positive pay file.
        /// </summary>
        field(25; "Positive Pay Exported"; Boolean)
        {
            Caption = 'Positive Pay Exported';
        }
#if not CLEANSCHEMA27
        field(26; "Record ID to Print"; RecordId)
        {
            Caption = 'Record ID to Print';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Print Gen Jnl Line SystemId field';
            ObsoleteTag = '27.0';
        }
#endif
        /// <summary>
        /// SystemId reference to the General Journal Line used for check printing operations.
        /// </summary>
        field(27; "Print Gen Jnl Line SystemId"; Guid)
        {
            Caption = 'SystemId to Print';
            DataClassification = SystemMetadata;
        }
        field(12400; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(12401; "Beneficiary Bank Code"; Code[20])
        {
            Caption = 'Beneficiary Bank Code';
            TableRelation = if ("Bal. Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Bal. Account No."))
            else
            if ("Bal. Account Type" = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Bal. Account No."));
        }
        field(12402; "Payment Purpose"; Text[250])
        {
            Caption = 'Payment Purpose';
        }
        field(12403; "Cash Order Including"; Text[250])
        {
            Caption = 'Cash Order Including';
        }
        field(12404; "Cash Order Supplement"; Text[100])
        {
            Caption = 'Cash Order Supplement';
        }
        field(12405; "Payment Method"; Option)
        {
            Caption = 'Payment Method';
            OptionCaption = ' ,Mail,Telegraph,Through Moscow,Clearing';
            OptionMembers = " ",Mail,Telegraph,"Through Moscow",Clearing;
        }
        field(12406; "Payment Before Date"; Date)
        {
            Caption = 'Payment Before Date';
        }
        field(12407; "Payment Subsequence"; Text[2])
        {
            Caption = 'Payment Subsequence';
        }
        field(12408; "Payment Code"; Text[20])
        {
            Caption = 'Payment Code';
        }
        field(12409; "Payment Assignment"; Text[15])
        {
            Caption = 'Payment Assignment';
        }
        field(12410; "Payment Type"; Text[5])
        {
            Caption = 'Payment Type';
        }
        field(12411; "Payer BIC"; Text[20])
        {
            Caption = 'Payer BIC';
        }
        field(12412; "Payer Corr. Account No."; Text[20])
        {
            Caption = 'Payer Corr. Account No.';
        }
        field(12413; "Payer Bank Account No."; Text[20])
        {
            Caption = 'Payer Bank Account No.';
        }
        field(12414; "Payer Name"; Text[100])
        {
            Caption = 'Payer Name';
        }
        field(12415; "Payer Bank"; Text[100])
        {
            Caption = 'Payer Bank';
        }
        field(12416; "Payer VAT Reg. No."; Text[12])
        {
            Caption = 'Payer VAT Reg. No.';
        }
        field(12417; "Beneficiary BIC"; Text[20])
        {
            Caption = 'Beneficiary BIC';
        }
        field(12418; "Beneficiary Corr. Acc. No."; Text[20])
        {
            Caption = 'Beneficiary Corr. Acc. No.';
        }
        field(12419; "Beneficiary Bank Acc. No."; Text[20])
        {
            Caption = 'Beneficiary Bank Acc. No.';
        }
        field(12420; "Beneficiary Name"; Text[100])
        {
            Caption = 'Beneficiary Name';
        }
        field(12421; "Beneficiary VAT Reg No."; Text[12])
        {
            Caption = 'Beneficiary VAT Reg No.';
        }
        field(12422; "Cashier Report Printed"; Integer)
        {
            Caption = 'Cashier Report Printed';
            Editable = true;
        }
        field(12423; "Cashier Report No."; Code[20])
        {
            Caption = 'Cashier Report No.';
        }
        field(12424; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        field(12425; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        field(12427; "Bank Account Type"; Option)
        {
            CalcFormula = lookup("Bank Account"."Account Type" where("No." = field("Bank Account No.")));
            Caption = 'Bank Account Type';
            FieldClass = FlowField;
            OptionCaption = 'Bank Account,Cash Account';
            OptionMembers = "Bank Account","Cash Account";
        }
        field(12428; "Payer KPP"; Code[10])
        {
            Caption = 'Payer KPP';
        }
        field(12429; "Beneficiary KPP"; Code[10])
        {
            Caption = 'Beneficiary KPP';
        }
        field(12430; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if ("Bal. Account Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Bal. Account Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account Posting Group"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "FA Posting Group";
        }
        field(12480; KBK; Code[20])
        {
            Caption = 'KBK';
            TableRelation = KBK;
        }
        field(12481; OKATO; Code[11])
        {
            Caption = 'OKATO';
            TableRelation = OKATO;
        }
        field(12482; "Period Code"; Option)
        {
            Caption = 'Period Code';
            OptionCaption = ' ,0,D1-payment for the first decade of month,D2-payment for the second decade of month,D3-payment for the third decade of month,MH-monthly payments,QT-quarter payment,HY-half-year payments,YR-year payments';
            OptionMembers = " ","0",D1,D2,D3,MH,QT,HY,YR;
        }
        field(12483; "Payment Reason Code"; Code[10])
        {
            Caption = 'Payment Reason Code';
            TableRelation = "Payment Order Code".Code where(Type = const("Payment Reason"));
        }
        field(12484; "Reason Document No."; Code[10])
        {
            Caption = 'Reason Document No.';
        }
        field(12485; "Reason Document Date"; Date)
        {
            Caption = 'Reason Document Date';
        }
        field(12486; "Tax Payment Type"; Code[10])
        {
            Caption = 'Tax Payment Type';
            TableRelation = "Payment Order Code".Code where(Type = const("Tax Payment Type"));
        }
        field(12487; "Tax Period"; Code[10])
        {
            Caption = 'Tax Period';
        }
        field(12488; "Reason Document Type"; Option)
        {
            Caption = 'Reason Document Type';
            OptionCaption = ' ,TR-Number of requirement about taxes payment from TA,RS-Number of decision about installment,OT-Number of decision about deferral,VU-Number of act of materials in court,PR-Number of decision about suspension of penalty,AP-Number of control act,AR-number of executive document';
            OptionMembers = " ",TR,RS,OT,VU,PR,AP,AR;
        }
        field(12489; "Taxpayer Status"; Option)
        {
            Caption = 'Taxpayer Status';
            OptionCaption = ' ,01-taxpayer (charges payer),02-tax agent,03-collector of taxes and charges,04-tax authority,05-service of officers of justice of Department of Justice of Russian Federation,06-participant of foreign-economic activity,07-tax authority,08-payer of other mandatory payments';
            OptionMembers = " ","01","02","03","04","05","06","07","08";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Check Date")
        {
        }
        key(Key3; "Bank Account No.", "Entry Status", "Check No.", "Statement Status")
        {
        }
        key(Key4; "Bank Account Ledger Entry No.")
        {
        }
        key(Key5; "Bank Account No.", Open)
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
        key(Key7; "Print Gen Jnl Line SystemId")
        {
        }
    }

    fieldgroups
    {
    }

    var
        NothingToExportErr: Label 'There is nothing to export.';

    /// <summary>
    /// Retrieves the currency code from the associated bank account for formatting amounts.
    /// </summary>
    /// <returns>Currency code from the bank account, or empty string if not found</returns>
    procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    /// <summary>
    /// Initializes check ledger entry fields from corresponding bank account ledger entry data.
    /// Sets default values for check-specific fields and status information.
    /// </summary>
    /// <param name="BankAccLedgEntry">Source bank account ledger entry to copy data from</param>
    procedure CopyFromBankAccLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        "Bank Account No." := BankAccLedgEntry."Bank Account No.";
        "Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
        "Posting Date" := BankAccLedgEntry."Posting Date";
        "Document Type" := BankAccLedgEntry."Document Type";
        "Document No." := BankAccLedgEntry."Document No.";
        "External Document No." := BankAccLedgEntry."External Document No.";
        Description := BankAccLedgEntry.Description;
        "Bal. Account Type" := BankAccLedgEntry."Bal. Account Type";
        "Bal. Account No." := BankAccLedgEntry."Bal. Account No.";
        "Entry Status" := "Entry Status"::Posted;
        Open := true;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Check Date" := BankAccLedgEntry."Posting Date";
        "Check No." := BankAccLedgEntry."Document No.";

        OnAfterCopyFromBankAccLedgEntry(Rec, BankAccLedgEntry);
    end;

    /// <summary>
    /// Exports check entries to a positive pay file format for bank fraud prevention.
    /// Uses bank account configuration to determine export method and codeunit.
    /// </summary>
    procedure ExportCheckFile()
    var
        BankAcc: Record "Bank Account";
    begin
        if not FindSet() then
            Error(NothingToExportErr);

        if not BankAcc.Get("Bank Account No.") then
            Error(NothingToExportErr);

        if BankAcc.GetPosPayExportCodeunitID() > 0 then
            CODEUNIT.Run(BankAcc.GetPosPayExportCodeunitID(), Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Pos. Pay", Rec);
    end;

    /// <summary>
    /// Determines the payee name based on the balancing account type and number.
    /// Returns the appropriate name from customer, vendor, G/L account, or other account types.
    /// </summary>
    /// <returns>Name of the payee for this check</returns>
    procedure GetPayee() Payee: Text[100]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
    begin
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                if "Bal. Account No." <> '' then begin
                    GLAccount.Get("Bal. Account No.");
                    Payee := GLAccount.Name;
                end;
            "Bal. Account Type"::Customer:
                if "Bal. Account No." <> '' then begin
                    Customer.Get("Bal. Account No.");
                    Payee := Customer.Name;
                end;
            "Bal. Account Type"::Vendor:
                if "Bal. Account No." <> '' then begin
                    Vendor.Get("Bal. Account No.");
                    Payee := Vendor.Name;
                end;
            "Bal. Account Type"::"Bank Account":
                if "Bal. Account No." <> '' then begin
                    BankAccount.Get("Bal. Account No.");
                    Payee := BankAccount.Name;
                end;
            "Bal. Account Type"::"Fixed Asset":
                Payee := "Bal. Account No.";
            "Bal. Account Type"::Employee:
                if "Bal. Account No." <> '' then begin
                    Employee.Get("Bal. Account No.");
                    Payee := Employee.FullName();
                end;
        end;

        OnAfterGetPayee(Rec, Payee);
    end;

    /// <summary>
    /// Applies filter to show only open check entries for a specific bank account.
    /// Sets optimized key for efficient querying of open entries.
    /// </summary>
    /// <param name="BankAccNo">Bank account number to filter by</param>
    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset();
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

    /// <summary>
    /// Integration event raised after copying data from bank account ledger entry to check ledger entry.
    /// Enables additional field initialization or custom processing during check entry creation.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry that was populated with bank account data</param>
    /// <param name="BankAccountLedgerEntry">Source bank account ledger entry used for copying data</param>
    /// <remarks>
    /// Raised from CopyFromBankAccLedgEntry procedure after copying standard fields from bank ledger entry.
    /// This is a public event publisher that can be raised and subscribed to from anywhere.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromBankAccLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after retrieving the payee name for a check.
    /// Enables custom logic for determining or modifying the payee name based on account type and number.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry containing balance account information</param>
    /// <param name="Payee">Payee name retrieved from the balance account (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from GetPayee procedure after determining payee name based on balance account type.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPayee(CheckLedgerEntry: Record "Check Ledger Entry"; var Payee: Text[100])
    begin
    end;
}
