// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.DataAdministration;

table 135018 "Test Media Cleanup"
{
    DataClassification = CustomerContent;
    InherentPermissions = RIMDX;
    InherentEntitlements = RIMDX;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
        }
        field(2; "Test Media"; Media)
        {
        }
        field(3; "Test Media Set"; MediaSet)
        {
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
