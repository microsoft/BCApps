// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;

table 12177 "Issued Customer Bill Header"
{
    Caption = 'Issued Customer Bill Header';
    LookupPageID = "List of Issued Cust. Bills";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(10; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method" where("Bill Code" = filter(<> ''));
        }
        field(15; Type; Enum "Customer Bill Type")
        {
            Caption = 'Type';
        }
        field(20; "List Date"; Date)
        {
            Caption = 'List Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(50; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(60; "Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Issued Customer Bill Line".Amount where("Customer Bill No." = field("No.")));
            Caption = 'Total Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Report Header"; Text[50])
        {
            Caption = 'Report Header';
        }
        field(71; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(132; "Partner Type"; Option)
        {
            Caption = 'Partner Type';
            OptionCaption = ' ,Company,Person';
            OptionMembers = " ",Company,Person;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.")
        {
        }
        key(Key3; "Posting Date", "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        IssuedCustomerBillLine.SetRange("Customer Bill No.", "No.");
        IssuedCustomerBillLine.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error(Text1130003, TableCaption);
    end;

    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
        Text1130003: Label 'You cannot rename a %1.';

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Posting Date", "No.");
        NavigateForm.Run();
    end;

    [Scope('OnPrem')]
    procedure ExportToFile()
    var
        SEPADDExportMgt: Codeunit "SEPA - DD Export Mgt.";
    begin
        SEPADDExportMgt.ExportBillToFile("No.", "Bank Account No.", "Partner Type", DATABASE::"Issued Customer Bill Header");
    end;

    procedure ExportToFloppyFile()
    var
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        IssuedCustBillsFloppy: Report "Issued Cust Bills Floppy";
    begin
        IssuedCustomerBillHeader.SetRange("No.", "No.");
        IssuedCustBillsFloppy.SetTableView(IssuedCustomerBillHeader);
        IssuedCustBillsFloppy.UseRequestPage(false);
        IssuedCustBillsFloppy.Run();
    end;
}

