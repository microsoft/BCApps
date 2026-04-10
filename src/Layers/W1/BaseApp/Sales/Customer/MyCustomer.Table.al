// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;
using System.Security.AccessControl;

/// <summary>
/// Stores user-specific favorite customers for quick access on the Role Center.
/// </summary>
table 9150 "My Customer"
{
    Caption = 'My Customer';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the ID of the user who added this customer to their favorites list.
        /// </summary>
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the number of the customer that appears in the user's favorites list on the Role Center.
        /// </summary>
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
        /// <summary>
        /// Stores the customer's name for display purposes in the favorites list.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
            ToolTip = 'Specifies the name of the customer.';
        }
        /// <summary>
        /// Stores the customer's phone number for quick reference in the favorites list.
        /// </summary>
        field(4; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            Editable = false;
            ToolTip = 'Specifies the customer''s phone number.';
        }
        /// <summary>
        /// Contains the customer's current balance in local currency, calculated from customer ledger entries.
        /// </summary>
        field(5; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Customer No." = field("Customer No.")));
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

    /// <summary>
    /// Populates the Name and Phone No. fields from the related Customer record.
    /// </summary>
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

