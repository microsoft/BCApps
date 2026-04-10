// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Automation;

/// <summary>
/// Stores the configuration settings for an automated create reminders action including customer and entry filters.
/// </summary>
table 6757 "Create Reminders Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique code identifying this create reminders setup.
        /// </summary>
        field(1; Code; Code[50])
        {
            ToolTip = 'Specifies a unique code for the Create Reminders Setup';
        }
        /// <summary>
        /// Specifies the reminder action group to which this setup belongs.
        /// </summary>
        field(2; "Action Group Code"; Code[50])
        {
        }
        /// <summary>
        /// Specifies a description of this create reminders setup.
        /// </summary>
        field(3; Description; Text[50])
        {
            ToolTip = 'Specifies a description for the Create Reminders Setup';
        }
        /// <summary>
        /// Indicates whether only overdue entries with outstanding amounts should be included.
        /// </summary>
        field(10; "Only Overdue Amount Entries"; Boolean)
        {
            ToolTip = 'Specifies if reminder should list all open entries or only entries with overdue amount';
        }
        /// <summary>
        /// Indicates whether entries that are on hold should be included in the reminder.
        /// </summary>
        field(11; "Include Entries On Hold"; Boolean)
        {
            ToolTip = 'Specifies if entries on hold should be included in the reminder';
        }
        /// <summary>
        /// Indicates whether the header level should be applied to all lines on the reminder.
        /// </summary>
        field(12; "Set Header Level to all Lines"; Boolean)
        {
            ToolTip = 'Specifies if the highest level should be set on all reminder lines. If this value is set, then all lines will get the highest line level. Otherwise each entry will get incremented individually.';
        }
        /// <summary>
        /// Stores the filter criteria for selecting customers when creating reminders.
        /// </summary>
        field(20; "Customer Filter"; Blob)
        {
        }
        /// <summary>
        /// Stores the filter criteria for selecting customer ledger entries to include.
        /// </summary>
        field(21; "Ledger Entries Filter"; Blob)
        {
        }
        /// <summary>
        /// Stores the filter criteria for selecting ledger entries for line fee calculation.
        /// </summary>
        field(22; "Issue Fee Ledg. Entries Filter"; Blob)
        {
        }
    }
    keys
    {
        key(Key1; Code, "Action Group Code")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Opens a filter page to allow the user to set the customer selection filter.
    /// </summary>
    procedure SetCustomerSelectionFilter()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        CustomerRecordRef: RecordRef;
        SelectionFilterOutStream: OutStream;
        ExistingFilter: Text;
    begin
        CustomerRecordRef.Open(Database::Customer);
        ExistingFilter := Rec.GetCustomerSelectionFilter();
        Clear(Rec."Customer Filter");
        Rec."Customer Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        if not RequestPageParametersHelper.OpenPageToGetFilter(CustomerRecordRef, SelectionFilterOutStream, ExistingFilter) then
            exit;

        Rec.Modify();
    end;

    /// <summary>
    /// Opens a filter page to allow the user to set the customer ledger entries selection filter.
    /// </summary>
    procedure SetCustomerLedgerEntriesSelectionFilter()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        CustLedgerEntryRecordRef: RecordRef;
        SelectionFilterOutStream: OutStream;
        ExistingFilter: Text;
    begin
        CustLedgerEntryRecordRef.Open(Database::"Cust. Ledger Entry");
        Clear(Rec."Ledger Entries Filter");
        Rec."Ledger Entries Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        ExistingFilter := Rec.GetCustomerLedgerEntriesSelectionFilter();
        if not RequestPageParametersHelper.OpenPageToGetFilter(CustLedgerEntryRecordRef, SelectionFilterOutStream, ExistingFilter) then
            exit;

        Rec.Modify();
    end;

    /// <summary>
    /// Opens a filter page to allow the user to set the fee customer ledger entries selection filter.
    /// </summary>
    procedure SetFeeCustomerLedgerEntriesSelectionFilter()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        CustLedgerEntryRecordRef: RecordRef;
        SelectionFilterOutStream: OutStream;
        ExistingFilter: Text;
    begin
        CustLedgerEntryRecordRef.Open(Database::"Cust. Ledger Entry");
        Clear(Rec."Issue Fee Ledg. Entries Filter");
        Rec."Issue Fee Ledg. Entries Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        ExistingFilter := Rec.GetFeeCustomerLegerEntriesSelectionFilter();
        if not RequestPageParametersHelper.OpenPageToGetFilter(CustLedgerEntryRecordRef, SelectionFilterOutStream, ExistingFilter) then
            exit;

        Rec.Modify();
    end;

    /// <summary>
    /// Gets the stored customer selection filter text.
    /// </summary>
    /// <returns>The customer selection filter text.</returns>
    procedure GetCustomerSelectionFilter(): Text
    var
        SelectionFilterInStream: InStream;
        SelectionFilterText: Text;
    begin
        Clear(SelectionFilterText);
        Rec.CalcFields("Customer Filter");
        Rec."Customer Filter".CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        if not Rec."Customer Filter".HasValue() then
            exit;

        SelectionFilterInStream.ReadText(SelectionFilterText);
        exit(SelectionFilterText);
    end;

    /// <summary>
    /// Gets the stored customer ledger entries selection filter text.
    /// </summary>
    /// <returns>The customer ledger entries selection filter text.</returns>
    procedure GetCustomerLedgerEntriesSelectionFilter(): Text
    var
        SelectionFilterInStream: InStream;
        SelectionFilterText: Text;
    begin
        Clear(SelectionFilterText);
        Rec.CalcFields("Ledger Entries Filter");
        Rec."Ledger Entries Filter".CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        if not Rec."Ledger Entries Filter".HasValue() then
            exit;

        SelectionFilterInStream.ReadText(SelectionFilterText);
        exit(SelectionFilterText);
    end;

    /// <summary>
    /// Gets the stored fee customer ledger entries selection filter text.
    /// </summary>
    /// <returns>The fee customer ledger entries selection filter text.</returns>
    procedure GetFeeCustomerLegerEntriesSelectionFilter(): Text
    var
        SelectionFilterInStream: InStream;
        SelectionFilterText: Text;
    begin
        Clear(SelectionFilterText);
        Rec.CalcFields("Issue Fee Ledg. Entries Filter");
        Rec."Issue Fee Ledg. Entries Filter".CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        if not Rec."Issue Fee Ledg. Entries Filter".HasValue() then
            exit;

        SelectionFilterInStream.ReadText(SelectionFilterText);
        exit(SelectionFilterText);
    end;

    /// <summary>
    /// Gets the display text for the customer selection filter.
    /// </summary>
    /// <returns>A formatted display text showing the filter criteria.</returns>
    procedure GetCustomerSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::Customer, Rec.FieldNo("Customer Filter")));
    end;

    /// <summary>
    /// Gets the display text for the customer ledger entries selection filter.
    /// </summary>
    /// <returns>A formatted display text showing the filter criteria.</returns>
    procedure GetCustomerLedgerEntriesSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Ledger Entries Filter")));
    end;

    /// <summary>
    /// Gets the display text for the fee customer ledger entries selection filter.
    /// </summary>
    /// <returns>A formatted display text showing the filter criteria.</returns>
    procedure GetFeeCustomerLedgerEntriesSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Issue Fee Ledg. Entries Filter")));
    end;

    /// <summary>
    /// Gets the view filter for the customer selection that can be applied to a record.
    /// </summary>
    /// <returns>The view filter string for customer records.</returns>
    procedure GetCustomerSelectionViewFilter(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::Customer, Rec.FieldNo("Customer Filter")));
    end;

    /// <summary>
    /// Gets the view filter for the customer ledger entries selection that can be applied to a record.
    /// </summary>
    /// <returns>The view filter string for customer ledger entry records.</returns>
    procedure GetCustomerLedgerEntriesSelectionViewFilter(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Ledger Entries Filter")));
    end;

    /// <summary>
    /// Gets the view filter for the fee customer ledger entries selection that can be applied to a record.
    /// </summary>
    /// <returns>The view filter string for fee customer ledger entry records.</returns>
    procedure GetFeeCustomerLedgerEntriesSelectionViewFilter(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Issue Fee Ledg. Entries Filter")));
    end;
}