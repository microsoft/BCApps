// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

tableextension 11382 "G/L Entry NL" extends "G/L Entry"
{
    fields
    {
        field(11301; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(11302; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
            DataClassification = CustomerContent;
        }
        field(11303; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            DataClassification = CustomerContent;
        }
        field(11304; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
            DataClassification = CustomerContent;
        }
        field(11305; "Closed by Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
            DataClassification = CustomerContent;
        }
        field(11306; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key14; "Closed by Entry No.")
        {
        }
    }
}

