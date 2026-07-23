// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 13400 SourceCodeSetupFI extends "Source Code Setup"
{
    Caption = 'Source Code Setup';

    fields
    {
#if not CLEANSCHEMA32
#pragma warning disable AA0232
        field(13400; "Depr. Difference"; Code[10])
        {
            Caption = 'Depr. Difference';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
            ObsoleteReason = 'Moved to Depreciation Differences FI app.';
#if not CLEAN29
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#endif
        }
#pragma warning restore AA0232
#endif
    }
}