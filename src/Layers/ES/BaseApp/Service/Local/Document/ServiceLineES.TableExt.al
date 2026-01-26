// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;

tableextension 10791 "Service Line ES" extends "Service Line"
{
    fields
    {
        field(10701; "EC %"; Decimal)
        {
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
        field(10709; "Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
    }
}