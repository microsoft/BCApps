// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

#pragma warning disable AS0125
tableextension 11400 SourceCodeSetupNL extends "Source Code Setup"
{
    Caption = 'Source Code Setup';

    fields
    {
        field(11400; "Cash Journal"; Code[10])
        {
            Caption = 'Cash Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(11401; "Bank Journal"; Code[10])
        {
            Caption = 'Bank Journal';
            TableRelation = "Source Code";
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
    }
}