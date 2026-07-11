// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

tableextension 13471 "Source Code Setup DeprDiff FI" extends "Source Code Setup"
{
    fields
    {
        field(13465; "Depreciation Difference Code"; Code[10])
        {
            Caption = 'Depr. Difference';
            DataClassification = CustomerContent;
            TableRelation = "Source Code";
        }
    }
}
