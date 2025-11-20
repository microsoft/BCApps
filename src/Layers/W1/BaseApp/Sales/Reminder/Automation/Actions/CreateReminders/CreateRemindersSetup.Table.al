// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Automation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 6757 "Create Reminders Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[50])
        {
        }
        field(2; "Action Group Code"; Code[50])
        {
        }
        field(3; Description; Text[50])
        {
        }
        field(10; "Only Overdue Amount Entries"; Boolean)
        {
        }
        field(11; "Include Entries On Hold"; Boolean)
        {
        }
        field(12; "Set Header Level to all Lines"; Boolean)
        {
        }
        field(20; "Customer Filter"; Blob)
        {
        }
        field(21; "Ledger Entries Filter"; Blob)
        {
        }
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

    procedure GetCustomerSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::Customer, Rec.FieldNo("Customer Filter")));
    end;

    procedure GetCustomerLedgerEntriesSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Ledger Entries Filter")));
    end;

    procedure GetFeeCustomerLedgerEntriesSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Issue Fee Ledg. Entries Filter")));
    end;

    procedure GetCustomerSelectionViewFilter(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::Customer, Rec.FieldNo("Customer Filter")));
    end;

    procedure GetCustomerLedgerEntriesSelectionViewFilter(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Ledger Entries Filter")));
    end;

    procedure GetFeeCustomerLedgerEntriesSelectionViewFilter(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::"Cust. Ledger Entry", Rec.FieldNo("Issue Fee Ledg. Entries Filter")));
    end;
}