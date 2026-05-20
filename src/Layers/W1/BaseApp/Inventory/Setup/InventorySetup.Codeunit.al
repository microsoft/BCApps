// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

codeunit 24 "Inventory Setup"
{
    SingleInstance = true;

    var
        InventorySetup: Record "Inventory Setup";
        RecordHasBeenRead: Boolean;
        RecordWasReadTime: DateTime;

    internal procedure GetSetup(var NewInventorySetup: Record "Inventory Setup")
    begin
        if RecordWasReadTime = 0DT then
            RecordWasReadTime := CurrentDateTime(); // because time calculations not allowed when 0DT
        if not RecordHasBeenRead or (CurrentDateTime() > RecordWasReadTime + 60000) then begin
            InventorySetup.Get();
            RecordHasBeenRead := true;
            RecordWasReadTime := CurrentDateTime();
        end;
        NewInventorySetup := InventorySetup;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Setup", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnOnBeforeModifyInventorySetup(var Rec: Record "Inventory Setup"; var xRec: Record "Inventory Setup"; RunTrigger: Boolean)
    begin
        RecordHasBeenRead := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Setup", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnOnBeforeInsertInventorySetup(var Rec: Record "Inventory Setup"; RunTrigger: Boolean)
    begin
        RecordHasBeenRead := false;
    end;
#if not CLEAN29
    [EventSubscriber(ObjectType::Table, Database::"Inventory Setup", OnAfterValidateEvent, "Direct Transfer Posting", false, false)]
    local procedure OnAfterValidateInventorySetupDirectTransferPosting(var Rec: Record "Inventory Setup"; var xRec: Record "Inventory Setup"; CurrFieldNo: Integer)
    begin
        Rec.SyncDirectTransferPostingOptionToEnum(Rec."Direct Transfer Posting");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Setup", OnAfterValidateEvent, "Direct Transfer Posting Type", false, false)]
    local procedure OnAfterValidateInventorySetupDirectTransferPostingType(var Rec: Record "Inventory Setup"; var xRec: Record "Inventory Setup"; CurrFieldNo: Integer)
    begin
        Rec.SyncDirectTransferPostingEnumToOption(Rec."Direct Transfer Posting Type");
    end;
#endif
}
