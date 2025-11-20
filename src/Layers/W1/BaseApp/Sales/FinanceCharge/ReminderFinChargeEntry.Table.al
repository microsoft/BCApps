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

table 300 "Reminder/Fin. Charge Entry"
{
    Caption = 'Reminder/Fin. Charge Entry';
    DrillDownPageID = "Reminder/Fin. Charge Entries";
    LookupPageID = "Reminder/Fin. Charge Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            NotBlank = true;
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Reminder,Finance Charge Memo';
            OptionMembers = Reminder,"Finance Charge Memo";
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Reminder)) "Issued Reminder Header"
            else
            if (Type = const("Finance Charge Memo")) "Issued Fin. Charge Memo Header";
        }
        field(4; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(7; "Interest Posted"; Boolean)
        {
            Caption = 'Interest Posted';
        }
        field(8; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Interest Amount';
        }
        field(9; "Customer Entry No."; Integer)
        {
            Caption = 'Customer Entry No.';
            TableRelation = "Cust. Ledger Entry";
        }
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(12; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        field(13; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(14; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(15; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
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

    [InherentPermissions(PermissionObjectType::TableData, Database::"Reminder/Fin. Charge Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCurrencyCode(ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; var CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

