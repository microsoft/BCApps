// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Represents individual direct debit transactions within a collection, linking customer ledger entries
/// to specific direct debit mandates and managing the transaction lifecycle from creation to posting.
/// </summary>
table 1208 "Direct Debit Collection Entry"
{
    Caption = 'Direct Debit Collection Entry';
    DataCaptionFields = "Customer No.", "Transaction ID";
    DrillDownPageID = "Direct Debit Collect. Entries";
    LookupPageID = "Direct Debit Collect. Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the parent direct debit collection that contains this entry.
        /// </summary>
        field(1; "Direct Debit Collection No."; Integer)
        {
            Caption = 'Direct Debit Collection No.';
            TableRelation = "Direct Debit Collection";
        }
        /// <summary>
        /// Sequential entry number within the direct debit collection.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Customer from whom the direct debit amount will be collected.
        /// </summary>
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if xRec."Customer No." <> '' then
                    TestField(Status, Status::New);
            end;
        }
        /// <summary>
        /// Customer ledger entry that this direct debit entry applies to, typically an invoice or reminder.
        /// </summary>
        field(4; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
            TableRelation = "Cust. Ledger Entry" where("Customer No." = field("Customer No."),
                                                        "Document Type" = filter(Invoice | "Finance Charge Memo" | Reminder),
                                                        Open = const(true));

            trigger OnValidate()
            var
                CustLedgerEntry: Record "Cust. Ledger Entry";
                DirectDebitCollection: Record "Direct Debit Collection";
                AllowedDocumentType: Boolean;
            begin
                if xRec."Applies-to Entry No." <> "Applies-to Entry No." then begin
                    TestField("Customer No.");
                    CustLedgerEntry.Get("Applies-to Entry No.");
                    CustLedgerEntry.TestField("Customer No.", "Customer No.");
                    CustLedgerEntry.TestField(Open);

                    AllowedDocumentType :=
                      (CustLedgerEntry."Document Type" in
                       [CustLedgerEntry."Document Type"::Invoice,
                        CustLedgerEntry."Document Type"::"Finance Charge Memo",
                        CustLedgerEntry."Document Type"::Reminder]);
                    OnBeforeDocTypeErr(CustLedgerEntry, AllowedDocumentType);
                    if not AllowedDocumentType then
                        Error(DocTypeErr);

                    CustLedgerEntry.CalcFields("Remaining Amount");
                    CheckCustLedgerEntryAmountPositive(CustLedgerEntry);

                    "Transfer Date" := CustLedgerEntry."Due Date";
                    "Currency Code" := CustLedgerEntry."Currency Code";
                    "Transfer Amount" := CustLedgerEntry."Remaining Amount" - GetAmountInActiveCollections();
                    Validate("Mandate ID", CustLedgerEntry."Direct Debit Mandate ID");
                    OnValidateAppliesToEntryNoOnAfterTransferCustLedgerEntryFields(Rec, xRec, CustLedgerEntry);

                    DirectDebitCollection.Get("Direct Debit Collection No.");
                    "Transaction ID" := StrSubstNo('%1/%2', DirectDebitCollection.Identifier, "Entry No.");
                end;
            end;
        }
        /// <summary>
        /// Scheduled date when the direct debit collection will be processed.
        /// </summary>
        field(5; "Transfer Date"; Date)
        {
            Caption = 'Transfer Date';
        }
        /// <summary>
        /// Currency code of the transaction, inherited from the customer ledger entry.
        /// </summary>
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Amount to be collected via direct debit from the customer.
        /// </summary>
        field(7; "Transfer Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Transfer Amount';

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTransferAmount(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Transfer Amount" <= 0 then
                    Error(AmountMustBePositiveErr);
                TestField("Applies-to Entry No.");
                CustLedgEntry.Get("Applies-to Entry No.");
                CustLedgEntry.CalcFields("Remaining Amount");
                if "Transfer Amount" > CustLedgEntry."Remaining Amount" - GetAmountInActiveCollections() then
                    Error(LargerThanRemainingErr, CustLedgEntry."Remaining Amount", CustLedgEntry."Currency Code");
            end;
        }
        /// <summary>
        /// Unique identifier for the transaction, used in SEPA XML files for tracking purposes.
        /// </summary>
        field(8; "Transaction ID"; Text[35])
        {
            Caption = 'Transaction ID';
            Editable = false;
        }
        /// <summary>
        /// SEPA sequence type indicating whether this is a one-off, first, recurring, or last transaction.
        /// </summary>
        field(9; "Sequence Type"; Option)
        {
            Caption = 'Sequence Type';
            Editable = false;
            OptionCaption = 'One Off,First,Recurring,Last';
            OptionMembers = "One Off",First,Recurring,Last;
        }
        /// <summary>
        /// Current processing status of the direct debit entry.
        /// </summary>
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'New,File Created,Rejected,Posted';
            OptionMembers = New,"File Created",Rejected,Posted;
        }
        /// <summary>
        /// SEPA direct debit mandate identifier that authorizes this collection.
        /// </summary>
        field(11; "Mandate ID"; Code[35])
        {
            Caption = 'Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate".ID where("Customer No." = field("Customer No."));

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                if "Mandate ID" = '' then
                    exit;
                SEPADirectDebitMandate.Get("Mandate ID");
                "Sequence Type" := SEPADirectDebitMandate.GetSequenceType();
            end;
        }
        /// <summary>
        /// Payment type specified in the mandate (one-off or recurrent), calculated from the mandate.
        /// </summary>
        field(12; "Mandate Type of Payment"; Option)
        {
            CalcFormula = lookup("SEPA Direct Debit Mandate"."Type of Payment" where(ID = field("Mandate ID")));
            Caption = 'Mandate Type of Payment';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'One Off,Recurrent';
            OptionMembers = "One Off",Recurrent;
        }
        /// <summary>
        /// Name of the customer, retrieved from the customer master data.
        /// </summary>
        field(13; "Customer Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Caption = 'Customer Name';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Document number of the customer ledger entry this collection applies to.
        /// </summary>
        field(14; "Applies-to Entry Document No."; Code[20])
        {
            CalcFormula = lookup("Cust. Ledger Entry"."Document No." where("Entry No." = field("Applies-to Entry No.")));
            Caption = 'Applies-to Entry Document No.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Description of the customer ledger entry this collection applies to.
        /// </summary>
        field(15; "Applies-to Entry Description"; Text[100])
        {
            CalcFormula = lookup("Cust. Ledger Entry".Description where("Entry No." = field("Applies-to Entry No.")));
            Caption = 'Applies-to Entry Description';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Posting date of the customer ledger entry this collection applies to.
        /// </summary>
        field(16; "Applies-to Entry Posting Date"; Date)
        {
            CalcFormula = lookup("Cust. Ledger Entry"."Posting Date" where("Entry No." = field("Applies-to Entry No.")));
            Caption = 'Applies-to Entry Posting Date';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Currency code of the customer ledger entry this collection applies to.
        /// </summary>
        field(17; "Applies-to Entry Currency Code"; Code[10])
        {
            CalcFormula = lookup("Cust. Ledger Entry"."Currency Code" where("Entry No." = field("Applies-to Entry No.")));
            Caption = 'Applies-to Entry Currency Code';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = Currency;
        }
        /// <summary>
        /// Total amount of the customer ledger entry this collection applies to.
        /// </summary>
        field(18; "Applies-to Entry Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Cust. Ledger Entry No." = field("Applies-to Entry No."),
                                                                         "Entry Type" = filter("Initial Entry" | "Unrealized Loss" | "Unrealized Gain" | "Realized Loss" | "Realized Gain" | "Payment Discount" | "Payment Discount (VAT Excl.)" | "Payment Discount (VAT Adjustment)" | "Payment Tolerance" | "Payment Discount Tolerance" | "Payment Tolerance (VAT Excl.)" | "Payment Tolerance (VAT Adjustment)" | "Payment Discount Tolerance (VAT Excl.)" | "Payment Discount Tolerance (VAT Adjustment)")));
            Caption = 'Applies-to Entry Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Remaining amount on the customer ledger entry that this collection applies to.
        /// </summary>
        field(19; "Applies-to Entry Rem. Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Cust. Ledger Entry No." = field("Applies-to Entry No.")));
            Caption = 'Applies-to Entry Rem. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether the customer ledger entry this collection applies to is still open.
        /// </summary>
        field(20; "Applies-to Entry Open"; Boolean)
        {
            CalcFormula = lookup("Cust. Ledger Entry".Open where("Entry No." = field("Applies-to Entry No.")));
            Caption = 'Applies-to Entry Open';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Status of the parent direct debit collection, retrieved from the collection header.
        /// </summary>
        field(21; "Direct Debit Collection Status"; Option)
        {
            CalcFormula = lookup("Direct Debit Collection".Status where("No." = field("Direct Debit Collection No.")));
            Caption = 'Direct Debit Collection Status';
            FieldClass = FlowField;
            OptionCaption = 'New,Canceled,File Created,Posted,Closed';
            OptionMembers = New,Canceled,"File Created",Posted,Closed;
        }
        /// <summary>
        /// Payment reference from the customer ledger entry, used for reconciliation purposes.
        /// </summary>
        field(22; "Payment Reference"; Code[50])
        {
            CalcFormula = lookup("Cust. Ledger Entry"."Payment Reference" where("Entry No." = field("Applies-to Entry No.")));
            Caption = 'Payment Reference';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Optional message to be included in the direct debit instruction for the recipient.
        /// </summary>
        field(23; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
    }

    keys
    {
        key(Key1; "Direct Debit Collection No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Applies-to Entry No.", Status)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePaymentFileErrors();
    end;

    trigger OnInsert()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        if "Entry No." = 0 then begin
            DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "Direct Debit Collection No.");
            LockTable();
            if DirectDebitCollectionEntry.FindLast() then;
            "Entry No." := DirectDebitCollectionEntry."Entry No." + 1;
        end;
    end;

    trigger OnModify()
    begin
        TestField(Status, Status::New);
        CalcFields("Direct Debit Collection Status");
        TestField("Direct Debit Collection Status", "Direct Debit Collection Status"::New);
    end;

    var
        DocTypeErr: Label 'The customer ledger entry must be of type Invoice, Finance Charge Memo, or Reminder.';
        AmountMustBePositiveErr: Label 'The amount must be positive.';
        LargerThanRemainingErr: Label 'You cannot collect an amount that is larger than the remaining amount for the invoice (%1 %2) that is not on other collection entries.', Comment = '%1 = an amount. %2 = currency code, e.g. 123.45 EUR';
        RejectQst: Label 'Do you want to reject this collection entry?';

    /// <summary>
    /// Creates a new direct debit collection entry based on a customer ledger entry.
    /// </summary>
    /// <param name="DirectDebitCollectionNo">Collection number to associate this entry with</param>
    /// <param name="CustLedgerEntry">Customer ledger entry to create the collection for</param>
    procedure CreateNew(DirectDebitCollectionNo: Integer; CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        "Direct Debit Collection No." := DirectDebitCollectionNo;
        SetRange("Direct Debit Collection No.", DirectDebitCollectionNo);
        LockTable();
        if FindLast() then;
        "Entry No." += 1;
        Init();
        Validate("Customer No.", CustLedgerEntry."Customer No.");
        Validate("Applies-to Entry No.", CustLedgerEntry."Entry No.");
        OnCreateNewOnBeforeInsert(CustLedgerEntry, Rec);
        Insert();
        OnCreateNewOnAfterInsert(CustLedgerEntry, Rec);

        IsHandled := false;
        OnBeforeCheckSEPA(Rec, IsHandled);
        if not IsHandled then
            CODEUNIT.Run(CODEUNIT::"SEPA DD-Check Line", Rec);
    end;

    /// <summary>
    /// Removes payment file errors associated with this collection entry.
    /// </summary>
    procedure DeletePaymentFileErrors()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TransferPKToGenJnlLine(GenJnlLine);
        GenJnlLine.DeletePaymentFileErrors();
    end;

    /// <summary>
    /// Checks if any payment file errors exist for this collection entry.
    /// </summary>
    /// <returns>True if payment file errors are found</returns>
    procedure HasPaymentFileErrors(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TransferPKToGenJnlLine(GenJnlLine);
        exit(GenJnlLine.HasPaymentFileErrors());
    end;

    /// <summary>
    /// Initiates SEPA direct debit export process for this collection entry.
    /// </summary>
    procedure ExportSEPA()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportSEPA(Rec, IsHandled);
        if not IsHandled then
            CODEUNIT.Run(CODEUNIT::"SEPA DD-Export File", Rec);
    end;

    /// <summary>
    /// Creates a payment file error entry with specified text.
    /// </summary>
    /// <param name="Text">Error message text</param>
    procedure InsertPaymentFileError(Text: Text)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TransferPKToGenJnlLine(GenJnlLine);
        GenJnlLine.InsertPaymentFileError(Text);
    end;

    /// <summary>
    /// Creates a payment file error entry with additional details.
    /// </summary>
    /// <param name="ErrorText">Primary error message</param>
    /// <param name="AddnlInfo">Additional information about the error</param>
    procedure InsertPaymentFileErrorWithDetails(ErrorText: Text; AddnlInfo: Text)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TransferPKToGenJnlLine(GenJnlLine);
        GenJnlLine.InsertPaymentFileErrorWithDetails(ErrorText, AddnlInfo, '');
    end;

    /// <summary>
    /// Rejects the collection entry and rolls back the mandate sequence type if applicable.
    /// </summary>
    procedure Reject()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        TestField(Status, Status::"File Created");
        if not Confirm(RejectQst) then
            exit;
        Status := Status::Rejected;
        Modify();
        if "Mandate ID" = '' then
            exit;
        SEPADirectDebitMandate.Get("Mandate ID");
        SEPADirectDebitMandate.RollBackSequenceType();
    end;

    local procedure CheckCustLedgerEntryAmountPositive(var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustLedgerEntryAmountPositive(CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if CustLedgEntry."Remaining Amount" <= 0 then
            Error(AmountMustBePositiveErr);
    end;

    local procedure TransferPKToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferPKToGenJnlLine(Rec, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine."Document No." := CopyStr(Format("Direct Debit Collection No.", 0, 9), 1, MaxStrLen(GenJnlLine."Document No."));
        GenJnlLine."Line No." := "Entry No.";
    end;

    /// <summary>
    /// Calculates the total amount already allocated to other active collections for the same customer ledger entry.
    /// </summary>
    /// <returns>Amount already allocated in other collections</returns>
    procedure GetAmountInActiveCollections(): Decimal
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        AmountAlreadyInCollection: Decimal;
    begin
        if "Applies-to Entry No." = 0 then
            exit(0);

        DirectDebitCollectionEntry.SetRange("Applies-to Entry No.", "Applies-to Entry No.");
        DirectDebitCollectionEntry.SetFilter(Status, '%1|%2', Status::New, Status::"File Created");
        if DirectDebitCollectionEntry.FindSet() then
            repeat
                if (DirectDebitCollectionEntry."Direct Debit Collection No." <> "Direct Debit Collection No.") or
                   (DirectDebitCollectionEntry."Entry No." <> "Entry No.")
                then
                    AmountAlreadyInCollection += DirectDebitCollectionEntry."Transfer Amount";
            until DirectDebitCollectionEntry.Next() = 0;
        exit(AmountAlreadyInCollection);
    end;

    /// <summary>
    /// Updates transfer dates to today for all overdue entries in the same collection.
    /// </summary>
    procedure SetTodayAsTransferDateForOverdueEnries()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "Direct Debit Collection No.");
        DirectDebitCollectionEntry.SetRange(Status, DirectDebitCollectionEntry.Status::New);
        DirectDebitCollectionEntry.SetFilter("Transfer Date", '<%1', Today());
        if DirectDebitCollectionEntry.FindSet(true) then
            repeat
                DirectDebitCollectionEntry.Validate("Transfer Date", Today());
                DirectDebitCollectionEntry.Modify(true);
                Codeunit.Run(Codeunit::"SEPA DD-Check Line", DirectDebitCollectionEntry);
            until DirectDebitCollectionEntry.Next() = 0;
    end;

    /// <summary>
    /// Integration event that allows customization of SEPA validation checks.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being validated</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSEPA(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of customer ledger entry amount validation.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry being validated</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustLedgerEntryAmountPositive(var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of document type validation logic.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry being validated</param>
    /// <param name="AlllowedDocumentType">Whether the document type is allowed</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDocTypeErr(CustLedgerEntry: Record "Cust. Ledger Entry"; var AlllowedDocumentType: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of SEPA export processing.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being exported</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportSEPA(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event for customizing primary key transfer to general journal line.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being processed</param>
    /// <param name="GenJnlLine">The general journal line receiving the primary key</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferPKToGenJnlLine(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of transfer amount validation.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being validated</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferAmount(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event triggered before inserting a new collection entry.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry used to create the collection</param>
    /// <param name="DirectDebitCollectionEntry">The collection entry being created</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateNewOnBeforeInsert(CustLedgerEntry: Record "Cust. Ledger Entry"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
    end;

    /// <summary>
    /// Integration event triggered after inserting a new collection entry.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry used to create the collection</param>
    /// <param name="DirectDebitCollectionEntry">The collection entry that was created</param>
    [IntegrationEvent(false, false)]
    local procedure OnCreateNewOnAfterInsert(CustLedgerEntry: Record "Cust. Ledger Entry"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
    end;

    /// <summary>
    /// Integration event triggered after transferring fields from customer ledger entry during validation.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being validated</param>
    /// <param name="xDirectDebitCollectionEntry">The previous state of the collection entry</param>
    /// <param name="CustLedgerEntry">The customer ledger entry being applied</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesToEntryNoOnAfterTransferCustLedgerEntryFields(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; xDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}
