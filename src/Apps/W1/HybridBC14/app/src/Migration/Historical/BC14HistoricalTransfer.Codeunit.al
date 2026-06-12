// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

codeunit 46882 "BC14 Historical Transfer"
{
    Access = Internal;

    /// <summary>
    /// Registers an AddFieldValue mapping on the given DataTransfer for every Normal-class field
    /// that exists on both source and destination with the same id and type. System fields
    /// (id &gt;= 2000000000) and any field not present on both sides are intentionally skipped so
    /// the platform can generate fresh SystemId / SystemCreatedAt / SystemModifiedAt values on the
    /// destination rows.
    /// </summary>
    internal procedure AddMatchingFieldMappings(var Transfer: DataTransfer; SrcTableId: Integer; DstTableId: Integer)
    var
        SrcRef: RecordRef;
        DstRef: RecordRef;
        SrcFld: FieldRef;
        DstFld: FieldRef;
        i: Integer;
    begin
        SrcRef.Open(SrcTableId);
        DstRef.Open(DstTableId);
        for i := 1 to DstRef.FieldCount() do begin
            DstFld := DstRef.FieldIndex(i);
            if DstFld.Number >= 2000000000 then
                continue;
            if DstFld.Class <> FieldClass::Normal then
                continue;
            if not SrcRef.FieldExist(DstFld.Number) then
                continue;
            SrcFld := SrcRef.Field(DstFld.Number);
            if Format(SrcFld.Type) <> Format(DstFld.Type) then
                continue;
            Transfer.AddFieldValue(SrcFld.Number, DstFld.Number);
        end;
        DstRef.Close();
        SrcRef.Close();
    end;
}
