// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

table 6114 "E-Doc. Purchase Line PO Match"
{
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "E-Doc. Purchase Line SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'E-Doc. Purchase Line SystemId';
            TableRelation = "E-Document Purchase Line".SystemId;
            Editable = false;
        }
        field(2; "Purchase Line SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Purchase Line SystemId';
            TableRelation = "Purchase Line".SystemId;
            Editable = false;
        }
        field(3; "Receipt Line SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Receipt Line SystemId';
            TableRelation = "Purch. Rcpt. Line".SystemId;
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "E-Doc. Purchase Line SystemId", "Purchase Line SystemId", "Receipt Line SystemId")
        {
            Clustered = true;
        }
    }
}