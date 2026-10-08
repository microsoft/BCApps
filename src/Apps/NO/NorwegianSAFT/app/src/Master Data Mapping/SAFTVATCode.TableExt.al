// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.VAT.Setup;

#pragma warning disable AL0520 // Accepted: the base table is obsolete but this extension must remain for upgrade compatibility.
tableextension 10675 "SAF-T VAT Code" extends "VAT Code"
#pragma warning restore AL0520
{
    fields
    {
        field(10670; Compensation; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Compensation';
        }
    }
}
