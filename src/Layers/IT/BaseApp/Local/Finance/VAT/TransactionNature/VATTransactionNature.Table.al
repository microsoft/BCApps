// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.TransactionNature;

table 12202 "VAT Transaction Nature"
{
    Caption = 'VAT Transaction Nature';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "VAT Transaction Nature";
    LookupPageID = "VAT Transaction Nature";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[4])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

