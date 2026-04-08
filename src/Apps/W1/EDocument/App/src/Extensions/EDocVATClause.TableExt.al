// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Finance.VAT.Clause;

tableextension 6173 "E-Doc. VAT Clause" extends "VAT Clause"
{
    fields
    {
        field(6100; "VATEX Code"; Code[30])
        {
            Caption = 'VATEX Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the VATEX exemption reason code (BT-121) from the CEF VATEX code list, e.g. VATEX-EU-AE, VATEX-EU-G, VATEX-EU-IC.';
        }
    }
}
