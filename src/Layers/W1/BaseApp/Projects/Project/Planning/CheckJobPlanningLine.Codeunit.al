// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.Item;

codeunit 9135 "Check Job Planning Line"
{

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckDocuments', '', false, false)]
    local procedure ItemOnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text);
    begin
        CheckJobPlanningLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    procedure CheckJobPlanningLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;

    begin
        IsHandled := false;
        OnBeforeCheckJobPlanningLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckJobPlanningLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        JobPlanningLine.SetCurrentKey(Type, "No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetRange("No.", Item."No.");
        if not JobPlanningLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(
                    Item.GetCannotDeleteItemWithExistingDocumentLinesErr(),
                    Item.TableCaption(), Item."No.", JobPlanningLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", JobPlanningLine.TableCaption());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobPlanningLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}
