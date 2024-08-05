// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

tableextension 6635 ObsoleteReturnReasonExt extends "Return Reason"
{
    fields
    {
        field(3; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The Audit Codes module cannot reference the Inventory Management feature.';
            ObsoleteState = Moved;
            ObsoleteTag = '25.0';
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(4; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The Audit Codes module cannot reference the Inventory Management feature.';
            ObsoleteState = Moved;
            ObsoleteTag = '25.0';
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
    }
}

