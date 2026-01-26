// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;
using System.Security.AccessControl;

table 9150 "My Customer"
{
    Caption = 'My Customer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the customer numbers that are displayed in the My Customer Cue on the Role Center.';

            trigger OnValidate()
            begin
                SetCustomerFields();
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
            ToolTip = 'Specifies the name of the customer.';
        }
        field(4; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            Editable = false;
            ToolTip = 'Specifies the customer''s phone number.';
        }
        field(5; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Customer No." = field("Customer No."),
                                                                                 "Excluded from calculation" = const(false)));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the payment amount that the customer owes for completed sales.';
        }
    }

    keys
    {
        key(Key1; "User ID", "Customer No.")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
        key(Key3; "Phone No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure SetCustomerFields()
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("Name", "Phone No.");
        if Customer.Get("Customer No.") then begin
            Name := Customer.Name;
            "Phone No." := Customer."Phone No.";
        end;
    end;
}

