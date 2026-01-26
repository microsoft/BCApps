// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.VAT.Ledger;

table 12149 "Reprint Info Fiscal Reports"
{
    Caption = 'Reprint Info Fiscal Reports';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report"; Option)
        {
            Caption = 'Report';
            OptionCaption = 'G/L Book - Print,VAT Register - Print';
            OptionMembers = "G/L Book - Print","VAT Register - Print";
        }
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(3; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(4; "Vat Register Code"; Code[10])
        {
            Caption = 'Vat Register Code';
            TableRelation = "VAT Register";
        }
        field(5; "First Page Number"; Integer)
        {
            Caption = 'First Page Number';
        }
    }

    keys
    {
        key(Key1; "Report", "Start Date", "End Date", "Vat Register Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

