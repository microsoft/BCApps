// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Sales.Customer;

table 5329 "CRM Redirect"
{
    Caption = 'CRM Redirect';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';
        }
        field(2; "Filter"; Text[128])
        {
            CalcFormula = lookup(Customer.Name);
            Caption = 'Filter';
            Description = 'Only to be used for passthrough of URL parameters';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

