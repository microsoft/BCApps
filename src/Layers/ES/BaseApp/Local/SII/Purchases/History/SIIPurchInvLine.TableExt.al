// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.History;

tableextension 7000115 "SII Purch. Inv. Line" extends "Purch. Inv. Line"
{
    fields
    {
        field(10709; "Special Scheme Code"; Enum "SII Purch. Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
    }
}
