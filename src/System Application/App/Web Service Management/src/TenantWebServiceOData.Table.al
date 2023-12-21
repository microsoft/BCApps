// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

/// <summary>
/// Contains tenant web service OData clause entities.
/// </summary>
table 6710 "Tenant Web Service OData"
{
    Caption = 'Tenant Web Service OData';
    DataPerCompany = false;
    ReplicateData = false;
    Extensible = false;
    Access = Public;

    fields
    {
        field(1; TenantWebServiceID; RecordId)
        {
            Caption = 'Tenant Web Service ID';
            DataClassification = CustomerContent;
        }
        field(2; ODataSelectClause; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'OData Select Clause';
        }
        field(3; ODataFilterClause; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'OData Filter Clause';
        }
        field(4; ODataV4FilterClause; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'OData V4 Filter Clause';
        }
    }

    keys
    {
        key(Key1; TenantWebServiceID)
        {
            Clustered = true;
        }
    }

}

