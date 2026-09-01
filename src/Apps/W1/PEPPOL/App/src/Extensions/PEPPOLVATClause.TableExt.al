// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Clause;

tableextension 37221 "PEPPOL VAT Clause" extends "VAT Clause"
{
    fields
    {
        field(37200; "VATEX Code"; Code[30])
        {
            Caption = 'VATEX Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the VATEX exemption reason code (BT-121) from the CEF VATEX code list, e.g. VATEX-EU-AE, VATEX-EU-G, VATEX-EU-IC.';
        }
    }
}
