// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

codeunit 13481 "Dep Diff FI Helper Procedures"
{
    Access = Internal;

    procedure TransferFields(TableId: Integer; TargetFieldNo: Integer; SourceFieldNo: Integer)
    var
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(TableId, TableId);
        DataTransfer.AddFieldValue(SourceFieldNo, TargetFieldNo);
        DataTransfer.UpdateAuditFields := false;
        DataTransfer.CopyFields();
    end;
}
