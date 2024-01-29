// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Reflection;

codeunit 9558 "Table Key Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure DisableAll(TableNo: Integer): Boolean
    begin
        exit(AlterAll(TableNo, false));
    end;

    procedure EnableAll(TableNo: Integer): Boolean
    begin
        exit(AlterAll(TableNo, true));
    end;

    local procedure AlterAll(TableNo: Integer; Enable: Boolean): Boolean
    var
        TableMetadata: Record "Table Metadata";
        TableKey: Record "Key";
        RecordRef: RecordRef;
        KeyToDisable: KeyRef;
    begin
        // Disabling indexes for system tables is not supported
        if TableNo > 2000000000 then
            exit(false);

        if not TableMetadata.Get(TableNo) then
            exit(false);

        // Disabling indexes is only supported for Normal tables
        if TableMetadata.TableType <> TableMetadata.TableType::Normal then
            exit(false);

        RecordRef.Open(TableNo);

        TableKey.SetRange(TableNo, TableNo);
        TableKey.SetRange(TableKey.Enabled, true);
        TableKey.SetRange(Clustered, false);
        TableKey.SetRange(Unique, false);
        TableKey.SetRange(MaintainSIFTIndex, false);
        TableKey.SetRange(SumIndexFields, '');
        TableKey.SetFilter(TableKey.ObsoleteState, '%1|%2', TableKey.ObsoleteState::No, TableKey.ObsoleteState::Pending);

        if TableKey.FindSet() then
            repeat
                KeyToDisable := RecordRef.KeyIndex(TableKey."No.");
                Database.AlterKey(KeyToDisable, Enable);
            until TableKey.Next() = 0;

        // Disable SystemId index
        KeyToDisable := RecordRef.KeyIndex(RecordRef.KeyCount());
        Database.AlterKey(KeyToDisable, Enable);
        RecordRef.Close();

        exit(true);
    end;
}