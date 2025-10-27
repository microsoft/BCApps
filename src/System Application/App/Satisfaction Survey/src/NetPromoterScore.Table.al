#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

table 1433 "Net Promoter Score"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteReason = 'This module is no longer used.';
#if not CLEAN28
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '31.0';
#endif

    fields
    {
        field(1; "User SID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(4; "Last Request Time"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Send Request"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "User SID")
        {
            Clustered = true;
        }
    }

}
#endif
