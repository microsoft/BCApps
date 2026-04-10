// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

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
/// Stores line items for posted finance charge memos including amounts, interest rates, and VAT details.
/// </summary>
table 305 "Issued Fin. Charge Memo Line"
{
    Caption = 'Issued Fin. Charge Memo Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the issued finance charge memo number that this line belongs to.
        /// </summary>
        field(1; "Finance Charge Memo No."; Code[20])
        {
            Caption = 'Finance Charge Memo No.';
            TableRelation = "Issued Fin. Charge Memo Header";
        }
        /// <summary>
        /// Specifies the sequential line number within the issued finance charge memo.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Specifies the line number that this line is attached to, used for extended text lines.
        /// </summary>
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Issued Fin. Charge Memo Line"."Line No." where("Finance Charge Memo No." = field("Finance Charge Memo No."));
        }
        /// <summary>
        /// Specifies the line type: blank for text, G/L Account for fees, or Customer Ledger Entry for interest charges.
        /// </summary>
        field(4; Type; Option)
        {
            Caption = 'Type';
            ToolTip = 'Specifies the line type.';
            OptionCaption = ' ,G/L Account,Customer Ledger Entry';
            OptionMembers = " ","G/L Account","Customer Ledger Entry";
        }
        /// <summary>
        /// Specifies the customer ledger entry number for which interest was charged.
        /// </summary>
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                IssuedFinChrgMemoHeader.Get("Finance Charge Memo No.");
                SetCustLedgEntryFilter(CustLedgEntry, IssuedFinChrgMemoHeader, FieldNo("Entry No."));
                if CustLedgEntry.Get("Entry No.") then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
        }
        /// <summary>
        /// Specifies the posting date of the original customer ledger entry.
        /// </summary>
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the customer ledger entry that this finance charge memo line is for.';
        }
        /// <summary>
        /// Specifies the document date of the original customer ledger entry.
        /// </summary>
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
        /// <summary>
        /// Specifies the due date of the original customer ledger entry.
        /// </summary>
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the due date of the customer ledger entry this finance charge memo line is for.';
        }
        /// <summary>
        /// Specifies the document type of the original customer ledger entry.
        /// </summary>
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the customer ledger entry this finance charge memo line is for.';
        }
        /// <summary>
        /// Specifies the document number of the original customer ledger entry.
        /// </summary>
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of the customer ledger entry this finance charge memo line is for.';

            trigger OnLookup()
            begin
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                IssuedFinChrgMemoHeader.Get("Finance Charge Memo No.");
                SetCustLedgEntryFilter(CustLedgEntry, IssuedFinChrgMemoHeader, FieldNo("Document No."));
                if CustLedgEntry.Get("Entry No.") then;
                PAGE.RunModal(0, CustLedgEntry);
            end;
        }
        /// <summary>
        /// Specifies the description of the line, typically the customer ledger entry description or G/L account name.
        /// </summary>
        field(12; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies an entry description, based on the contents of the Type field.';
        }
        /// <summary>
        /// Specifies the original amount of the customer ledger entry before any payments.
        /// </summary>
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
            ToolTip = 'Specifies the original amount of the customer ledger entry that this finance charge memo line is for.';
        }
        /// <summary>
        /// Specifies the remaining unpaid amount of the customer ledger entry at the time of issue.
        /// </summary>
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the remaining amount of the customer ledger entry this finance charge memo line is for.';
        }
        /// <summary>
        /// Specifies the G/L account number for additional fees or the standard text code for text lines.
        /// </summary>
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account";
        }
        /// <summary>
        /// Specifies the interest amount or additional fee amount that was charged.
        /// </summary>
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount in the currency of the finance charge memo.';
        }
        /// <summary>
        /// Specifies the interest rate percentage that was used to calculate the finance charge.
        /// </summary>
        field(17; "Interest Rate"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the general product posting group used for posting the finance charge.
        /// </summary>
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Specifies the VAT percentage that was applied to the finance charge.
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
        /// Specifies the VAT amount that was calculated on the finance charge.
        /// </summary>
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        /// <summary>
        /// Specifies the tax group code used for sales tax calculation.
        /// </summary>
        field(22; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Specifies the VAT product posting group that was used for the memo line.
        /// </summary>
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Specifies the VAT identifier code from the VAT posting setup.
        /// </summary>
        field(24; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        /// <summary>
        /// Specifies the type of line: finance charge line, beginning text, ending text, or rounding.
        /// </summary>
        field(25; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionCaption = 'Finance Charge Memo Line,Beginning Text,Ending Text,Rounding';
            OptionMembers = "Finance Charge Memo Line","Beginning Text","Ending Text",Rounding;
        }
        /// <summary>
        /// Specifies the VAT clause code that provides explanatory text for VAT.
        /// </summary>
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        /// <summary>
        /// Indicates whether this line contains detailed interest rate breakdown when multiple rates applied.
        /// </summary>
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        /// <summary>
        /// Indicates whether this line was created automatically by the system.
        /// </summary>
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Finance Charge Memo No.", "Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
        }
        key(Key2; "Finance Charge Memo No.", Type, "Detailed Interest Rates Entry")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Finance Charge Memo No.", "Detailed Interest Rates Entry")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
    }

    fieldgroups
    {
    }

    var
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        CustLedgEntry: Record "Cust. Ledger Entry";

    /// <summary>
    /// Retrieves the currency code from the parent issued finance charge memo header.
    /// </summary>
    /// <returns>The currency code of the issued finance charge memo.</returns>
    procedure GetCurrencyCode(): Code[10]
    var
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        if "Finance Charge Memo No." = IssuedFinChrgMemoHeader."No." then
            exit(IssuedFinChrgMemoHeader."Currency Code");

        if IssuedFinChrgMemoHeader.Get("Finance Charge Memo No.") then
            exit(IssuedFinChrgMemoHeader."Currency Code");

        exit('');
    end;

    local procedure SetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header"; CalledByFieldNo: Integer)
    begin
        CustLedgEntry.SetCurrentKey("Customer No.");
        CustLedgEntry.SetRange("Customer No.", IssuedFinChrgMemoHeader."Customer No.");

        OnAfterSetCustLedgEntryFilter(CustLedgEntry, Rec, CalledByFieldNo);
    end;

    /// <summary>
    /// Raised after filters are set on customer ledger entries for lookup.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry record with filters applied.</param>
    /// <param name="IssuedFinChrgMemoLine">Specifies the issued finance charge memo line record.</param>
    /// <param name="CalledByFieldNo">Specifies the field number that triggered the filter setup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustLedgEntryFilter(var CustLedgEntry: Record "Cust. Ledger Entry"; var IssuedFinChrgMemoLine: Record "Issued Fin. Charge Memo Line"; CalledByFieldNo: Integer)
    begin
    end;
}

