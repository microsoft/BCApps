// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 10002 SourceCodeSetupNA extends "Source Code Setup"
{
    Caption = 'Source Code Setup';

    fields
    {
        field(10002; "Bank Rec. Adjustment"; Code[10])
        {
            Caption = 'Bank Rec. Adjustment';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(10003; Deposits; Code[10])
        {
            Caption = 'Deposits';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
    }
}