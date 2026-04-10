#if not CLEANSCHEMA26 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 9551 "Document Service Cache"
{
    DataPerCompany = false;
    Extensible = false;
    ReplicateData = false;
    ObsoleteReason = 'No longer required';
    ObsoleteState = Removed;
    ObsoleteTag = '26.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Service Id"; Guid)
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Use Cached Token"; Boolean)
        {
            Caption = 'Use Cached Token';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Document Service Id")
        {
            Clustered = true;
        }
    }
}
 
#endif
