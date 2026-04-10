// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;
table 6411 "Fornav Peppol Role"
{
    DataClassification = SystemMetadata;
    Caption = 'ForNAV Peppol Roles';
    Access = Internal;

    fields
    {
        field(1; "Role"; Code[20])
        {
            Caption = 'Role';
            ToolTip = 'Specifies the roles that you have on the ForNAV Peppol network.';
        }
    }

    keys
    {
        key(Key1; Role)
        {
            Clustered = true;
        }
    }
}