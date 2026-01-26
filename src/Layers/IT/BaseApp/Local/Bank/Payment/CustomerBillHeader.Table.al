// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Setup;

table 12174 "Customer Bill Header"
{
    Caption = 'Customer Bill Header';
    LookupPageID = "List of Customer Bills";
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
        field(9; "Test Report"; Boolean)
        {
            Caption = 'Test Report';
        }
        field(10; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method" where("Bill Code" = filter(<> ''));

            trigger OnValidate()
            begin
                PaymentMethod.Get("Payment Method Code");
                PaymentMethod.TestField("Bill Code");
                "Report Header" := CopyStr(PaymentMethod.Description, 1, MaxStrLen("Report Header"));
            end;
        }
        field(12; "Customer Bill List"; Code[20])
        {
            Caption = 'Customer Bill List';
        }
        field(15; Type; Enum "Customer Bill Type")
        {
            Caption = 'Type';
        }
        field(20; "List Date"; Date)
        {
            Caption = 'List Date';

            trigger OnValidate()
            begin
                if "Posting Date" = 0D then
                    "Posting Date" := "List Date";
            end;
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
            CalcFormula = sum("Customer Bill Line".Amount where("Customer Bill No." = field("No.")));
            Caption = 'Total Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Report Header"; Text[30])
        {
            Caption = 'Report Header';
        }
        field(71; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(132; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
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
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CustomerBillLine.SetRange("Customer Bill No.", "No.");
        CustomerBillLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            SalesSetup.Get();
            SalesSetup.TestField("Temporary Bill List No.");
            "User ID" := UserId;
                "No. Series" := SalesSetup."Temporary Bill List No.";
                "No." := NoSeries.GetNextNo("No. Series");
        end;

        Validate("List Date", WorkDate());
    end;

    trigger OnRename()
    begin
        Error(Text1130003, TableCaption);
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
        PaymentMethod: Record "Payment Method";
        Text1130003: Label 'You cannot rename a %1.';

    [Scope('OnPrem')]
    procedure AssistEdit(OldCustomerBillHeader: Record "Customer Bill Header"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        CustomerBillHeader := Rec;
        SalesSetup.Get();
        SalesSetup.TestField("Temporary Bill List No.");
        if NoSeries.LookupRelatedNoSeries(SalesSetup."Temporary Bill List No.", OldCustomerBillHeader."No. Series", CustomerBillHeader."No. Series") then begin
            CustomerBillHeader."No." := NoSeries.GetNextNo(CustomerBillHeader."No. Series");
            Rec := CustomerBillHeader;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportToFile()
    var
        SEPADDExportMgt: Codeunit "SEPA - DD Export Mgt.";
    begin
        SEPADDExportMgt.ExportBillToFile("No.", "Bank Account No.", "Partner Type".AsInteger(), DATABASE::"Customer Bill Header");
    end;

    procedure ExportToFloppyFile()
    var
        CustBillHeader: Record "Customer Bill Header";
        CustBillsFloppy: Report "Cust Bills Floppy";
    begin
        CustBillHeader.SetRange("No.", "No.");
        CustBillsFloppy.SetTableView(CustBillHeader);
        CustBillsFloppy.UseRequestPage(false);
        CustBillsFloppy.Run();
    end;
}
