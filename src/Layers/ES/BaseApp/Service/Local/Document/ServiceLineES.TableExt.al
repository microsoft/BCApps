// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

tableextension 10791 "Service Line ES" extends "Service Line"
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
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'EC Difference';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}