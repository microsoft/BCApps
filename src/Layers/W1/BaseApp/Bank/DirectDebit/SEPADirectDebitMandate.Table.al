// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

/// <summary>
/// Stores SEPA direct debit mandates that authorize automated collection of payments from customer accounts.
/// Manages mandate validity periods, payment types, usage counters, and compliance with SEPA regulations.
/// </summary>
table 1230 "SEPA Direct Debit Mandate"
{
    Caption = 'Direct Debit Mandate';
    DataCaptionFields = ID, "Customer Bank Account Code";
    DrillDownPageID = "SEPA Direct Debit Mandates";
    LookupPageID = "SEPA Direct Debit Mandates";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the direct debit mandate, typically assigned automatically from number series.
        /// </summary>
        field(1; ID; Code[35])
        {
            Caption = 'ID';

            trigger OnValidate()
            var
                SalesSetup: Record "Sales & Receivables Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if ID <> xRec.ID then begin
                    SalesSetup.Get();
                    NoSeries.TestManual(SalesSetup."Direct Debit Mandate Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        /// <summary>
        /// Customer who has granted authorization for direct debit collections through this mandate.
        /// </summary>
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if (xRec."Customer No." <> '') and ("Customer No." <> xRec."Customer No.") then begin
                    TestField("Date of Signature", 0D);
                    TestField("Debit Counter", 0);
                    "Customer Bank Account Code" := '';
                end;
            end;
        }
        /// <summary>
        /// Bank account code from which direct debit collections will be processed.
        /// </summary>
        field(3; "Customer Bank Account Code"; Code[20])
        {
            Caption = 'Customer Bank Account Code';
            NotBlank = true;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Customer No."));
        }
        /// <summary>
        /// Start date from which the mandate becomes valid for direct debit collections.
        /// </summary>
        field(4; "Valid From"; Date)
        {
            Caption = 'Valid From';

            trigger OnValidate()
            begin
                ValidateDates();
            end;
        }
        /// <summary>
        /// End date after which the mandate is no longer valid for direct debit collections.
        /// </summary>
        field(5; "Valid To"; Date)
        {
            Caption = 'Valid To';

            trigger OnValidate()
            begin
                ValidateDates();
            end;
        }
        /// <summary>
        /// Date when the customer signed the mandate, required for SEPA compliance.
        /// </summary>
        field(6; "Date of Signature"; Date)
        {
            Caption = 'Date of Signature';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies whether this is a one-off or recurrent mandate for multiple collections.
        /// </summary>
        field(7; "Type of Payment"; Option)
        {
            Caption = 'Type of Payment';
            OptionCaption = 'OneOff,Recurrent';
            OptionMembers = OneOff,Recurrent;

            trigger OnValidate()
            begin
                if ("Type of Payment" = "Type of Payment"::OneOff) then begin
                    if "Debit Counter" > 1 then
                        Error(MandateChangeErr);
                    "Expected Number of Debits" := 1;
                    "Ignore Exp. Number of Debits" := false;
                end;
            end;
        }
        /// <summary>
        /// Indicates whether the mandate is blocked and cannot be used for new collections.
        /// </summary>
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Expected total number of debits to be processed under this mandate.
        /// </summary>
        field(9; "Expected Number of Debits"; Integer)
        {
            Caption = 'Expected Number of Debits';
            InitValue = 1;
            MinValue = 1;

            trigger OnValidate()
            begin
                if DoesDebitCounterExceedExpectedNumber() then
                    Error(InvalidNumberOfDebitsTxt);
                if ("Type of Payment" = "Type of Payment"::OneOff) and ("Expected Number of Debits" > 1) then
                    Error(InvalidOneOffNumOfDebitsErr);
                SetClosed();
            end;
        }
        /// <summary>
        /// Current count of how many times this mandate has been used for direct debit collections.
        /// </summary>
        field(10; "Debit Counter"; Integer)
        {
            Caption = 'Debit Counter';
            Editable = false;

            trigger OnValidate()
            begin
                if DoesDebitCounterExceedExpectedNumber() then begin
                    Message(InvalidNumberOfDebitsTxt);
                    FieldError("Debit Counter");
                end;
            end;
        }
        /// <summary>
        /// Number series code used for automatic generation of mandate IDs.
        /// </summary>
        field(11; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Indicates whether the mandate has reached its expected number of debits and is closed.
        /// </summary>
        field(12; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        /// <summary>
        /// When enabled, allows collections to exceed the expected number of debits without closing the mandate.
        /// </summary>
        field(13; "Ignore Exp. Number of Debits"; Boolean)
        {
            Caption = 'Ignore Expected Number of Debits';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Type of Payment" = "Type of Payment"::OneOff then
                    "Ignore Exp. Number of Debits" := false;
            end;

        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Customer No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; ID, "Customer Bank Account Code", "Valid From", "Valid To", "Type of Payment")
        {
        }
    }

    trigger OnInsert()
    begin
        if not IsOnInsertHandled() then
            InsertNoSeries();
    end;

    trigger OnModify()
    begin
        if not IsOnModifyHandled() then
            if xRec.Blocked then
                TestField(Blocked, false);
    end;

    var
        DateErr: Label 'The Valid To date must be after the Valid From date.';
        InvalidNumberOfDebitsTxt: Label 'The Debit Counter cannot be greater than the Number of Debits.';
        InvalidOneOffNumOfDebitsErr: Label 'The Number of Debits for OneOff Sequence Type cannot be greater than one.';
        MandateChangeErr: Label 'SequenceType cannot be set to OneOff, since the Mandate has already been used.';

    local procedure InsertNoSeries()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if ID = '' then begin
            SalesSetup.Get();
            SalesSetup.TestField("Direct Debit Mandate Nos.");
            if NoSeries.AreRelated(SalesSetup."Direct Debit Mandate Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := SalesSetup."Direct Debit Mandate Nos.";
            ID := NoSeries.GetNextNo("No. Series");
        end;
    end;

    /// <summary>
    /// Checks if the mandate is active and valid for the specified transaction date.
    /// </summary>
    /// <param name="TransactionDate">Date to check mandate validity against</param>
    /// <returns>True if mandate is active and valid for the transaction date</returns>
    procedure IsMandateActive(TransactionDate: Date): Boolean
    begin
        if ("Valid To" <> 0D) and ("Valid To" < TransactionDate) or ("Valid From" > TransactionDate) or Blocked or Closed then
            exit(false);
        exit(true)
    end;

    local procedure DoesDebitCounterExceedExpectedNumber(): Boolean;
    begin
        exit(not "Ignore Exp. Number of Debits" and ("Debit Counter" > "Expected Number of Debits"));
    end;

    /// <summary>
    /// Finds the default active mandate for a customer on a specific due date.
    /// Prioritizes customer's preferred bank account if specified.
    /// </summary>
    /// <param name="CustomerNo">Customer number to find mandate for</param>
    /// <param name="DueDate">Due date to validate mandate against</param>
    /// <returns>ID of the default mandate, or empty if none found</returns>
    procedure GetDefaultMandate(CustomerNo: Code[20]; DueDate: Date): Code[35]
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Customer: Record Customer;
    begin
        SEPADirectDebitMandate.SetRange("Customer No.", CustomerNo);
        SEPADirectDebitMandate.SetFilter("Valid From", '%1|<=%2', 0D, DueDate);
        SEPADirectDebitMandate.SetFilter("Valid To", '%1|>=%2', 0D, DueDate);
        SEPADirectDebitMandate.SetRange(Blocked, false);
        SEPADirectDebitMandate.SetRange(Closed, false);
        if SEPADirectDebitMandate.FindFirst() then;
        if Customer.Get(CustomerNo) and (Customer."Preferred Bank Account Code" <> '') then
            SEPADirectDebitMandate.SetRange("Customer Bank Account Code", Customer."Preferred Bank Account Code");
        if SEPADirectDebitMandate.FindFirst() then;
        exit(SEPADirectDebitMandate.ID);
    end;

    /// <summary>
    /// Increments the debit counter when the mandate is used and updates the closed status.
    /// </summary>
    procedure UpdateCounter()
    begin
        TestField(Blocked, false);
        Validate("Debit Counter", "Debit Counter" + 1);
        SetClosed();
        Modify();
    end;

    /// <summary>
    /// Determines the SEPA sequence type based on mandate type and usage history.
    /// </summary>
    /// <returns>Sequence type: One Off, First, Recurring, or Last</returns>
    procedure GetSequenceType(): Integer
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.Init();
        if "Type of Payment" = "Type of Payment"::OneOff then
            exit(DirectDebitCollectionEntry."Sequence Type"::"One Off");
        if "Debit Counter" = 0 then
            exit(DirectDebitCollectionEntry."Sequence Type"::First);
        if not "Ignore Exp. Number of Debits" then
            if "Debit Counter" >= "Expected Number of Debits" - 1 then
                exit(DirectDebitCollectionEntry."Sequence Type"::Last);
        exit(DirectDebitCollectionEntry."Sequence Type"::Recurring);
    end;

    /// <summary>
    /// Decrements the debit counter when a collection is rejected or rolled back.
    /// </summary>
    procedure RollBackSequenceType()
    begin
        if "Debit Counter" <= 0 then
            exit;

        "Debit Counter" -= 1;
        SetClosed();
        Modify();
    end;

    local procedure SetClosed()
    begin
        if not "Ignore Exp. Number of Debits" then
            Closed := "Debit Counter" >= "Expected Number of Debits";
    end;

    local procedure ValidateDates()
    begin
        if ("Valid To" <> 0D) and ("Valid From" > "Valid To") then
            Error(DateErr);
    end;

    local procedure IsOnInsertHandled() IsHandled: boolean;
    begin
        OnBeforeInsert(IsHandled, Rec);
    end;

    local procedure IsOnModifyHandled() IsHandled: boolean;
    begin
        OnBeforeModify(IsHandled, Rec);
    end;

    /// <summary>
    /// Integration event triggered before inserting a new mandate record.
    /// </summary>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    /// <param name="SEPADirectDebitMandate">The mandate record being inserted</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert(var IsHandled: boolean; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    begin
    end;

    /// <summary>
    /// Integration event triggered before modifying a mandate record.
    /// </summary>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    /// <param name="SEPADirectDebitMandate">The mandate record being modified</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var IsHandled: boolean; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    begin
    end;
}
