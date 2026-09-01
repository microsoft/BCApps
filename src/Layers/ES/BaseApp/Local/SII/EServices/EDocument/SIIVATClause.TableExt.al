// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Clause;

tableextension 7000129 "SII VAT Clause" extends "VAT Clause"
{
    fields
    {
        field(10700; "SII Exemption Code"; Enum "SII Exemption Code")
        {
            Caption = 'SII Exemption Code';
            DataClassification = CustomerContent;
        }
    }
}
