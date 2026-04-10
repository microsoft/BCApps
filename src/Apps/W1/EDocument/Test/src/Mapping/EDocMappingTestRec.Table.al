// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

table 139615 "E-Doc. Mapping Test Rec"
{
    Access = Internal;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key Field"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Text Value"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Code Value"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
#pragma warning disable AA0473
        field(4; "Decimal Value"; Decimal)
#pragma warning restore AA0473
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Key Field")
        {
            Clustered = true;
        }
    }

}