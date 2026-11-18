// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

tableextension 7000067 "Sales Invoice Line ES" extends "Sales Invoice Line"
{
    fields
    {
        field(10701; "EC %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'EC %';
            DataClassification = CustomerContent;
        }
        field(10702; "EC Difference"; Decimal)
        {
            AutoFormatExpression = Rec.GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'EC Difference';
            DataClassification = CustomerContent;
            Editable = true;
        }
    }
}
