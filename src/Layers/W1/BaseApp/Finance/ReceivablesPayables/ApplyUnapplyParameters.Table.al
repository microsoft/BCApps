// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Stores parameters for apply and unapply operations on customer, vendor, and employee ledger entries.
/// Temporary table used to pass ledger entry information between application procedures.
/// </summary>
/// <remarks>
/// Used by application engines to maintain consistent data during payment application and reversal operations.
/// Supports customer, vendor, and employee ledger entry processing with journal integration.
/// Provides extensibility through integration events for custom application logic.
/// </remarks>
table 579 "Apply Unapply Parameters"
{
    Caption = 'Apply Unapply Parameters';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Entry number from the source ledger entry.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Account type for the apply/unapply operation.
        /// </summary>
        field(2; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Account number for customer, vendor, or employee.
        /// </summary>
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Posting date from the source ledger entry.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document type from the source ledger entry.
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Document number from the source ledger entry.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Journal template name for posting the apply/unapply operation.
        /// </summary>
        field(48; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Journal batch name for posting the apply/unapply operation.
        /// </summary>
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        /// <summary>
        /// External document number from the source ledger entry.
        /// </summary>
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Copies information from a customer ledger entry to initialize apply/unapply parameters.
    /// Sets account type to customer and transfers entry details for application processing.
    /// </summary>
    /// <param name="CustLedgEntry">Customer ledger entry to copy information from</param>
    procedure CopyFromCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        "Entry No." := CustLedgEntry."Entry No.";
        "Account Type" := "Account Type"::Customer;
        "Account No." := CustLedgEntry."Customer No.";
        "Posting Date" := CustLedgEntry."Posting Date";
        "Document Type" := CustLedgEntry."Document Type";
        "Document No." := CustLedgEntry."Document No.";

        OnAfterCopyFromCustLedgerEntry(Rec, CustLedgEntry);
    end;

    /// <summary>
    /// Copies information from a vendor ledger entry to initialize apply/unapply parameters.
    /// Sets account type to vendor and transfers entry details for application processing.
    /// </summary>
    /// <param name="VendLedgEntry">Vendor ledger entry to copy information from</param>
    procedure CopyFromVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        "Entry No." := VendLedgEntry."Entry No.";
        "Account Type" := "Account Type"::Vendor;
        "Account No." := VendLedgEntry."Vendor No.";
        "Posting Date" := VendLedgEntry."Posting Date";
        "Document Type" := VendLedgEntry."Document Type";
        "Document No." := VendLedgEntry."Document No.";

        OnAfterCopyFromVendLedgerEntry(Rec, VendLedgEntry);
    end;

    /// <summary>
    /// Copies information from an employee ledger entry to initialize apply/unapply parameters.
    /// Sets account type to employee and transfers entry details for application processing.
    /// </summary>
    /// <param name="EmplLedgEntry">Employee ledger entry to copy information from</param>
    procedure CopyFromEmplLedgEntry(EmplLedgEntry: Record "Employee Ledger Entry")
    begin
        "Entry No." := EmplLedgEntry."Entry No.";
        "Account Type" := "Account Type"::Employee;
        "Account No." := EmplLedgEntry."Employee No.";
        "Posting Date" := EmplLedgEntry."Posting Date";
        "Document Type" := EmplLedgEntry."Document Type";
        "Document No." := EmplLedgEntry."Document No.";

        OnAfterCopyFromEmplLedgerEntry(Rec, EmplLedgEntry);
    end;

    /// <summary>
    /// Integration event raised after copying data from customer ledger entry.
    /// Enables custom field mapping and validation for customer-specific parameters.
    /// </summary>
    /// <param name="PostApplyParameters">Apply/unapply parameters record being populated</param>
    /// <param name="CustLedgerEntry">Source customer ledger entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustLedgerEntry(var PostApplyParameters: Record "Apply Unapply Parameters"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying data from vendor ledger entry.
    /// Allows custom field mapping and validation for vendor-specific parameters.
    /// </summary>
    /// <param name="PostApplyParameters">Apply/unapply parameters record being populated</param>
    /// <param name="VendorLedgerEntry">Source vendor ledger entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVendLedgerEntry(var PostApplyParameters: Record "Apply Unapply Parameters"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after copying data from employee ledger entry.
    /// Enables custom field mapping and validation for employee-specific parameters.
    /// </summary>
    /// <param name="PostApplyParameters">Apply/unapply parameters record being populated</param>
    /// <param name="EmployeeLedgerEntry">Source employee ledger entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromEmplLedgerEntry(var PostApplyParameters: Record "Apply Unapply Parameters"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;
}

