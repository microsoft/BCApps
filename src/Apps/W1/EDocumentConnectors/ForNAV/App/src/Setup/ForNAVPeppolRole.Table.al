#if not CLEANSCHEMA33
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
    ObsoleteReason = 'Roles are no longer stored; role-based access is not used.';
#if not CLEAN30
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '33.0';
#endif

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
#endif