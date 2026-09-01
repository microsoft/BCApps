// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

tableextension 7000140 "SII No Taxable Entry" extends "No Taxable Entry"
{
    fields
    {
        field(10708; "Ignore In SII"; Boolean)
        {
            Caption = 'Ignore In SII';
            DataClassification = CustomerContent;
        }
    }
}