// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

tableextension 13472 "Source Code Setup DeprDiff FI" extends "Source Code Setup"
{
    fields
    {
        field(13481; "Depreciation Difference"; Code[10])
        {
            Caption = 'Depr. Difference';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
        }
    }
}
