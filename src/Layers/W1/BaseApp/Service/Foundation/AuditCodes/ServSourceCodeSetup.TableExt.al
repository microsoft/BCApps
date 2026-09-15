// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

tableextension 6467 "Serv. Source Code Setup" extends "Source Code Setup"
{
    fields
    {
#pragma warning disable AS0125
        field(5900; "Service Management"; Code[10])
        {
            Caption = 'Service Management';
            DataClassification = CustomerContent;
            TableRelation = "Source Code";
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
#pragma warning restore AS0125
    }
}
