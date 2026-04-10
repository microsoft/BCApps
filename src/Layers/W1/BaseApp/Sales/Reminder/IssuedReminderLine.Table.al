// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

/// <summary>
/// Stores individual line items on an issued reminder document including posted entries, text, and fees.
/// </summary>
table 298 "Issued Reminder Line"
{
    Caption = 'Issued Reminder Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the issued reminder document to which this line belongs.
        /// </summary>
        field(1; "Reminder No."; Code[20])
        {
            Caption = 'Reminder No.';
            TableRelation = "Issued Reminder Header";
        }
        /// <summary>
        /// Specifies the sequential line number within the issued reminder document.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Specifies the line number to which this line is attached, such as for extended text.
        /// </summary>
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Issued Reminder Line"."Line No." where("Reminder No." = field("Reminder No."));
        }
        /// <summary>
        /// Specifies the type of content on this line: customer ledger entry, G/L account, text, or line fee.
        /// </summary>
        field(4; Type; Enum "Reminder Source Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the line type.';
        }
        /// <summary>
        /// Specifies the customer ledger entry number that this line references.
        /// </summary>
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                LookupCustomerLedgerEntry(FieldNo("Entry No."));
            end;
        }
        /// <summary>
        /// Specifies how many times the customer has been reminded about this entry.
        /// </summary>
        field(6; "No. of Reminders"; Integer)
        {
            Caption = 'No. of Reminders';
            ToolTip = 'Specifies a number that indicates the reminder level.';
        }
        /// <summary>
        /// Specifies the posting date of the original document that was reminded.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the customer ledger entry that this reminder line is for.';
        }
        /// <summary>
        /// Specifies the document date of the original document that was reminded.
        /// </summary>
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
        /// <summary>
        /// Specifies the due date of the original document that was reminded.
        /// </summary>
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the due date of the customer ledger entry this reminder line is for.';
        }
        /// <summary>
        /// Specifies the document type of the original entry, such as invoice or credit memo.
        /// </summary>
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the customer ledger entry this reminder line is for.';
        }
        /// <summary>
        /// Specifies the document number of the original entry that was reminded.
        /// </summary>
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of the customer ledger entry this reminder line is for.';

            trigger OnLookup()
            begin
                LookupDocNo();
            end;
        }
        /// <summary>
        /// Specifies a description of the issued reminder line content.
        /// </summary>
        field(12; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies an entry description, based on the contents of the Type field.';
        }
        /// <summary>
        /// Specifies the original amount of the document that was reminded.
        /// </summary>
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
            ToolTip = 'Specifies the original amount of the customer ledger entry that this reminder line is for.';
        }
        /// <summary>
        /// Specifies the amount that was still owed on the document when the reminder was issued.
        /// </summary>
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the remaining amount of the customer ledger entry this reminder line is for.';
        }
        /// <summary>
        /// Specifies the number of the G/L account, standard text, or fee account for this line.
        /// </summary>
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const("Line Fee")) "G/L Account";
        }
        /// <summary>
        /// Specifies the fee or interest amount that was charged on this line.
        /// </summary>
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount in the currency of the reminder.';
        }
        /// <summary>
        /// Specifies the interest rate percentage that was used to calculate finance charges.
        /// </summary>
        field(17; "Interest Rate"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the general product posting group used for VAT and cost allocation.
        /// </summary>
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Specifies the VAT percentage that was applied to this line.
        /// </summary>
        field(19; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies how VAT was calculated for this line.
        /// </summary>
        field(20; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        /// <summary>
        /// Specifies the VAT amount that was calculated for this line.
        /// </summary>
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader();
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the VAT amount in the currency of the reminder.';
        }
        /// <summary>
        /// Specifies the tax group code for sales tax calculation.
        /// </summary>
        field(22; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Specifies the VAT product posting group that was used for this line.
        /// </summary>
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Specifies the VAT identifier for reporting and grouping VAT entries.
        /// </summary>
        field(24; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        /// <summary>
        /// Specifies the purpose of the line, such as beginning text, reminder line, or additional fee.
        /// </summary>
        field(25; "Line Type"; Enum "Reminder Line Type")
        {
            Caption = 'Line Type';
        }
        /// <summary>
        /// Specifies a VAT clause code for special VAT treatments that appeared on the document.
        /// </summary>
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        /// <summary>
        /// Specifies the document type that the line fee applied to.
        /// </summary>
        field(27; "Applies-To Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-To Document Type';
            ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        /// <summary>
        /// Specifies the document number that the line fee applied to.
        /// </summary>
        field(28; "Applies-To Document No."; Code[20])
        {
            Caption = 'Applies-To Document No.';
            ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';

            trigger OnLookup()
            begin
                if Type <> Type::"Line Fee" then
                    exit;
                IssuedReminderHeader.Get("Reminder No.");
                CustLedgEntry.SetCurrentKey("Customer No.");
                CustLedgEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");
                CustLedgEntry.SetRange("Document Type", "Applies-To Document Type");
                CustLedgEntry.SetRange("Document No.", "Applies-To Document No.");
                if CustLedgEntry.FindLast() then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
        }
        /// <summary>
        /// Indicates whether this line contains detailed interest rate calculation information.
        /// </summary>
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        /// <summary>
        /// Indicates whether this issued reminder line has been canceled.
        /// </summary>
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether this line was automatically created by the system during reminder generation.
        /// </summary>
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Reminder No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Reminder No.", Type, "Line Type", "Detailed Interest Rates Entry")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Reminder No.", "Detailed Interest Rates Entry")
        {
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key4; "Reminder No.", Type)
        {
            SumIndexFields = "VAT Amount";
        }
    }

    fieldgroups
    {
    }

    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustLedgEntry: Record "Cust. Ledger Entry";

    /// <summary>
    /// Gets the currency code from the associated issued reminder header.
    /// </summary>
    /// <returns>The currency code from the header, or empty string if not found.</returns>
    procedure GetCurrencyCodeFromHeader(): Code[10]
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        if "Reminder No." = IssuedReminderHeader."No." then
            exit(IssuedReminderHeader."Currency Code");

        if IssuedReminderHeader.Get("Reminder No.") then
            exit(IssuedReminderHeader."Currency Code");

        exit('');
    end;

    /// <summary>
    /// Opens a lookup page to view the customer ledger entry associated with this line's document number.
    /// </summary>
    procedure LookupDocNo()
    var
        IsHandled: Boolean;
    begin
        OnBeforeLookupDocNo(Rec, IsHandled);
        if IsHandled then
            exit;

        LookupCustomerLedgerEntry(FieldNo("Document No."));
    end;

    local procedure LookupCustomerLedgerEntry(CalledByFieldNo: Integer)
    begin
        if Type <> Type::"Customer Ledger Entry" then
            exit;
        IssuedReminderHeader.Get("Reminder No.");
        SetCustLedgEntryFilter(CustLedgEntry, IssuedReminderHeader, CalledByFieldNo);
        if CustLedgEntry.Get("Entry No.") then;
        PAGE.RunModal(0, CustLedgEntry);
    end;

    local procedure SetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; IssuedReminderHeader: Record "Issued Reminder Header"; CalledByFieldNo: Integer)
    begin
        CustLedgEntry.SetCurrentKey("Customer No.");
        CustLedgEntry.SetRange("Customer No.", IssuedReminderHeader."Customer No.");

        OnAfterSetCustLedgEntryFilter(CustLedgEntry, Rec, CalledByFieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var IssuedReminderLine: Record "Issued Reminder Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; var IssuedReminderLine: Record "Issued Reminder Line"; CalledByFieldNo: Integer)
    begin
    end;
}

