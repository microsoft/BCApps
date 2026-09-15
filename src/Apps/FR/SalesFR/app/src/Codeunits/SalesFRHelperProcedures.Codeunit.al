// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

codeunit 10807 "Sales FR Helper Procedures"
{
    Access = Internal;

    procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer; DefaultValue: Variant)
    var
        DataTransfer: DataTransfer;
    begin
        DataTransfer.SetTables(TableId, TableId);
        DataTransfer.AddSourceFilter(SourceFieldNo, '<>%1', DefaultValue);
        DataTransfer.AddFieldValue(SourceFieldNo, TargetFieldNo);
        DataTransfer.UpdateAuditFields := false;
        DataTransfer.CopyFields();
    end;
}
