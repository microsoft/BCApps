// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;

table 6937 "Expense Vendor"
{
    Access = Internal;
    Caption = 'Expense Vendor';
    LookupPageId = "Expense Vendors";
    DrillDownPageId = "Expense Vendors";
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ExpenseSetup.Get();
                    NoSeries.TestManual(ExpenseSetup."Expense Vendor Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the vendor''s name. You can enter a maximum of 30 characters, both numbers and letters.';
            OptimizeForTextSearch = true;
        }
        field(3; Status; Enum "Expense Vendor Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the matching and approval status of the expense vendor.';
            Editable = false;
        }
        field(4; "Approval Date"; Date)
        {
            Caption = 'Approval Date';
            ToolTip = 'Specifies the date on which the expense vendor was approved or rejected.';
            Editable = false;
        }
        field(5; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            ToolTip = 'Specifies the user ID of the accountant who approved or rejected the expense vendor.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Rejection Reason"; Text[250])
        {
            Caption = 'Rejection Reason';
            ToolTip = 'Specifies the reason the expense vendor was rejected.';
        }
        field(25; "Registration Number"; Text[50])
        {
            Caption = 'Registration No.';
            ToolTip = 'Specifies the registration number of the vendor. You can enter a maximum of 20 characters, both numbers and letters.';
            OptimizeForTextSearch = true;
        }
        field(86; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            ToolTip = 'Specifies the vendor''s VAT registration number.';
            OptimizeForTextSearch = true;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(190; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the Business Central vendor number linked to this expense vendor after matching or approval.';
            OptimizeForTextSearch = true;
            TableRelation = Vendor."No.";
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(VendorNo; "Vendor No.")
        {
        }
        key(RegistrationNumber; "Registration Number")
        {
        }
        key(VATRegistrationNo; "VAT Registration No.")
        {
        }
    }

    trigger OnInsert()
    var
        NoSeriesManagement: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            ExpenseSetup.Get();
            ExpenseSetup.TestField("Expense Vendor Nos.");
            "No." := NoSeriesManagement.GetNextNo(ExpenseSetup."Expense Vendor Nos.", WorkDate(), true);
            "No. Series" := ExpenseSetup."Expense Vendor Nos.";
        end;
    end;

    var
        ExpenseSetup: Record "Expense Agent Setup";
        NoSeries: Codeunit "No. Series";
}