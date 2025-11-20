// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using System.Globalization;

table 327 "Tax Jurisdiction Translation"
{
    Caption = 'Tax Jurisdiction Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Tax Jurisdiction Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

