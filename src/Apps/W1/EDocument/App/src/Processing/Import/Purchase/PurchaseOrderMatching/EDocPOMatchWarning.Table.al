// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

table 6115 "E-Doc PO Match Warning"
{
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    TableType = Temporary;

    fields
    {
        field(1; "E-Doc. Purchase Line SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'E-Doc. Purchase Line SystemId';
            Editable = false;
        }
        field(2; "Warning Type"; Enum "E-Doc PO Match Warning")
        {
            DataClassification = SystemMetadata;
            Caption = 'Warning Type';
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "E-Doc. Purchase Line SystemId", "Warning Type")
        {
            Clustered = true;
        }
    }
}