// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

tableextension 254 "SII VAT Entry" extends "VAT Entry"
{
    fields
    {
        field(10724; "Do Not Send To SII"; Boolean)
        {
            Caption = 'Do Not Send To SII';
            DataClassification = CustomerContent;
        }
        field(10725; "Ignore In SII"; Boolean)
        {
            Caption = 'Ignore In SII';
            DataClassification = CustomerContent;
        }
        field(10726; "One Stop Shop Reporting"; Boolean)
        {
            Caption = 'One Stop Shop Reporting';
            DataClassification = CustomerContent;
        }
    }
}