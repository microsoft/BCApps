// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;

codeunit 9133 "Check Planning Component"
{

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckDocuments', '', false, false)]
    local procedure ItemOnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text);
    begin
        CheckPlanningComponents(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    procedure CheckPlanningComponents(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        PlanningComponent: Record "Planning Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPlanningComponents(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckPlanningCompLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        PlanningComponent.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date", "Planning Line Origin");
        PlanningComponent.SetRange("Item No.", Item."No.");
        if not PlanningComponent.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(
                    Item.GetCannotDeleteItemWithExistingDocumentLinesErr(),
                    Item.TableCaption(), Item."No.", PlanningComponent.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", PlanningComponent.TableCaption());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPlanningComponents(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}
