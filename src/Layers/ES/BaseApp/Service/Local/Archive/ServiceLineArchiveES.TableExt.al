// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.EServices.EDocument;

tableextension 10711 "Service Line Archive ES" extends "Service Line Archive"
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
            Caption = 'EC Difference';
            DataClassification = CustomerContent;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
        }
        field(10709; "Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
    }
}