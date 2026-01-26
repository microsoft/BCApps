// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

table 10702 "Non-Payment Period"
{
    Caption = 'Non-Payment Period';
    DrillDownPageID = "Non-Payment Periods";
    LookupPageID = "Non-Payment Periods";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'Company Information,Customer,Vendor';
            OptionMembers = "Company Information",Customer,Vendor;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; "From Date"; Date)
        {
            Caption = 'From Date';
            NotBlank = true;
        }
        field(4; "To Date"; Date)
        {
            Caption = 'To Date';
            NotBlank = true;
        }
        field(5; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Code", "From Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

