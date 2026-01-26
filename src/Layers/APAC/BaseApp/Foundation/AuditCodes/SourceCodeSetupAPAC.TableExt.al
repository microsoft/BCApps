// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 28040 SourceCodeSetupAPAC extends "Source Code Setup"
{
    Caption = 'Source Code Setup';

    fields
    {
        field(28040; "WHT Settlement"; Code[10])
        {
            Caption = 'WHT Settlement';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
    }
}