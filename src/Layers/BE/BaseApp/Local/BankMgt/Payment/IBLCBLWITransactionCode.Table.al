// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 2000003 "IBLC/BLWI Transaction Code"
{
    Caption = 'IBLC/BLWI Transaction Code';
    DataCaptionFields = "Transaction Code";
    LookupPageID = "IBLC/BLWI Transaction Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transaction Code"; Code[3])
        {
            Caption = 'Transaction Code';
            Description = 'IBLC/BLWI Transaction Code';
            NotBlank = false;
            Numeric = true;
        }
        field(2; Description; Text[132])
        {
            Caption = 'Description';
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
            Description = 'Internal Usage';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Transaction Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

