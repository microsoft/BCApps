// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using System.Security.AccessControl;

/// <summary>
/// Stores entries tracking issued reminders and finance charge memos for customer ledger entries.
/// </summary>
table 300 "Reminder/Fin. Charge Entry"
{
    Caption = 'Reminder/Fin. Charge Entry';
    DrillDownPageID = "Reminder/Fin. Charge Entries";
    LookupPageID = "Reminder/Fin. Charge Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique sequential number assigned to this reminder or finance charge entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
            NotBlank = true;
        }
        /// <summary>
        /// Specifies whether this entry is for a reminder or a finance charge memo.
        /// </summary>
        field(2; Type; Enum "Reminder/Fin.ChargeEntry Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies whether the entry comes from a reminder or a finance charge memo.';
        }
        /// <summary>
        /// Specifies the document number of the issued reminder or finance charge memo.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(Reminder)) "Issued Reminder Header"
            else
            if (Type = const("Finance Charge Memo")) "Issued Fin. Charge Memo Header";
        }
        /// <summary>
        /// Specifies the reminder level that was applied when the reminder was issued.
        /// </summary>
        field(4; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            ToolTip = 'Specifies the reminder level if the Type field contains Reminder.';
        }
        /// <summary>
        /// Specifies the date when the reminder or finance charge memo was posted.
        /// </summary>
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the reminder or finance charge memo.';
        }
        /// <summary>
        /// Specifies the date of the reminder or finance charge memo document.
        /// </summary>
        field(6; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        /// <summary>
        /// Indicates whether interest was posted to the general ledger for this entry.
        /// </summary>
        field(7; "Interest Posted"; Boolean)
        {
            Caption = 'Interest Posted';
            ToolTip = 'Specifies whether or not interest was posted to the customer account and a general ledger account when the reminder or finance charge memo was issued.';
        }
        /// <summary>
        /// Specifies the interest amount that was charged on the customer ledger entry.
        /// </summary>
        field(8; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Interest Amount';
        }
        /// <summary>
        /// Specifies the customer ledger entry number that this reminder or finance charge relates to.
        /// </summary>
        field(9; "Customer Entry No."; Integer)
        {
            Caption = 'Customer Entry No.';
            ToolTip = 'Specifies the number of the customer ledger entry on the reminder line or finance charge memo line.';
            TableRelation = "Cust. Ledger Entry";
        }
        /// <summary>
        /// Specifies the document type of the original customer ledger entry, such as invoice or credit memo.
        /// </summary>
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the customer entry on the reminder line or finance charge memo line.';
        }
        /// <summary>
        /// Specifies the document number of the original customer ledger entry.
        /// </summary>
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of the customer entry on the reminder line or finance charge memo line.';
        }
        /// <summary>
        /// Specifies the remaining amount on the customer ledger entry at the time the reminder or finance charge was issued.
        /// </summary>
        field(12; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the remaining amount of the customer ledger entry this reminder or finance charge memo entry is for.';
        }
        /// <summary>
        /// Specifies the customer number associated with this reminder or finance charge entry.
        /// </summary>
        field(13; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the user who created the reminder or finance charge memo.
        /// </summary>
        field(14; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Specifies the due date of the original customer ledger entry.
        /// </summary>
        field(15; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Indicates whether this entry has been canceled, typically through a reversal or credit memo.
        /// </summary>
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
            ToolTip = 'Specifies if the issued reminder or finance charge has been canceled.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.")
        {
        }
        key(Key3; "Customer Entry No.", Type)
        {
        }
        key(Key4; Type, "No.")
        {
        }
        key(Key5; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Opens the Navigate page to show all related ledger entries for this reminder or finance charge entry.
    /// </summary>
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    local procedure GetCurrencyCode(): Code[10]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        IsHandled: Boolean;
    begin
        OnBeforeGetCurrencyCode(Rec, CurrencyCode, IsHandled);
        if IsHandled then
            exit(CurrencyCode);

        if "Customer Entry No." = CustLedgEntry."Entry No." then
            exit(CustLedgEntry."Currency Code");

        if CustLedgEntry.Get("Customer Entry No.") then
            exit(CustLedgEntry."Currency Code");

        exit('');
    end;

    /// <summary>
    /// Retrieves the highest entry number in the reminder or finance charge entry table.
    /// </summary>
    /// <returns>The last entry number, or 0 if no entries exist.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Reminder/Fin. Charge Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    /// <summary>
    /// Raised before the currency code is retrieved from the customer ledger entry.
    /// </summary>
    /// <param name="ReminderFinChargeEntry">Specifies the reminder or finance charge entry record.</param>
    /// <param name="CurrencyCode">Specifies the currency code that can be set.</param>
    /// <param name="IsHandled">Set to true to skip the default currency code retrieval.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCurrencyCode(ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; var CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

