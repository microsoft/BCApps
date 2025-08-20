// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Table that contains the available Tenant No. Series and their properties.
/// These No. Series are used for functionality cross-company, for numbers per company, see No. Series.
/// </summary>
table 1263 "No. Series Tenant"
{
    Caption = 'No. Series Tenant';
    DataClassification = CustomerContent;
    DataPerCompany = false;
#if not CLEANSCHEMA27
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
#endif
    ReplicateData = false;
    InherentEntitlements = rX;
    InherentPermissions = rX;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Last Used number"; Code[10])
        {
            Caption = 'Last Used number';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

}