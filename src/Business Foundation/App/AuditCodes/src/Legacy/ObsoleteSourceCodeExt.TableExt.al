// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

tableextension 230 ObsoleteSourceCodeExt extends "Source Code"
{
    fields
    {
        field(10810; Simulation; Boolean)
        {
            Caption = 'Simulation';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Discontinued feature';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(10620; "SAFT Source Code"; Code[9])
        {
            Caption = 'SAF-T Source Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Moved to extension';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(28160; Simulation; Boolean)
        {
            Caption = 'Simulation';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Discontinued feature';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}