// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

table 227 "VAT Registration Log Details"
{
    Caption = 'VAT Registration Log Details';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Log Entry No."; Integer)
        {
            Caption = 'Log Entry No.';
            TableRelation = "VAT Registration Log";
        }
        field(2; "Field Name"; Enum "VAT Reg. Log Details Field")
        {
            Caption = 'Field Name';
            ToolTip = 'Specifies the name of the field that has been validated by the VAT registration no. validation service.';
        }
        field(10; "Account Type"; Enum "VAT Registration Log Account Type")
        {
            Caption = 'Account Type';
        }
        field(11; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(20; "Requested"; Text[150])
        {
            Caption = 'Requested';
            ToolTip = 'Specifies the requested value.';
        }
        field(21; "Response"; Text[150])
        {
            Caption = 'Response';
            ToolTip = 'Specifies the value that was returned by the service.';
        }
        field(22; "Current Value"; Text[150])
        {
            Caption = 'Current Value';
            ToolTip = 'Specifies the current value.';
        }
        field(23; Status; Enum "VAT Reg. Log Details Field Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the field validation.';
        }
    }

    keys
    {
        key(PK; "Log Entry No.", "Field Name")
        {
            Clustered = true;
        }
    }
}
