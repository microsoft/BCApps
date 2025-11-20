// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using System.Globalization;

table 462 "Payment Term Translation"
{
    Caption = 'Payment Term Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Payment Term"; Code[10])
        {
            Caption = 'Payment Term';
            TableRelation = "Payment Terms";
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
        key(Key1; "Payment Term", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

