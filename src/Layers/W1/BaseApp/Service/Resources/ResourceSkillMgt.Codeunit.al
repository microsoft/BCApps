// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

using Microsoft.Inventory.Item;
using Microsoft.Service.Item;
using System.Utilities;

codeunit 5931 "Resource Skill Mgt."
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Do you want to update the skill code on the related items and service items?';
        Text001: Label 'Do you want to update the skill code on the related service items?';
#pragma warning disable AA0470
        Text002: Label 'Do you want to assign the skill codes of %1 %2 to %3 %4?';
#pragma warning restore AA0470
        Text003: Label 'Do you want to delete skill codes on the related items and service items?';
        Text004: Label 'Do you want to delete skill codes on the related service items?';
        Text005: Label 'You have changed the skill code on the item.';
        Text006: Label 'How do you want to update the resource skill codes on the related service items?';
        Text007: Label 'Change the skill codes to the selected value.';
        Text008: Label 'Delete the skill codes or update their relation.';
        Text010: Label 'You have changed the skill code on the service item group.';
        Text011: Label 'How do you want to update the resource skill codes on the related items and service items?';
        Text012: Label 'Change the skill codes to the selected value.';
        Text013: Label 'Delete the skill codes or update their relation.';
        Text015: Label 'You have deleted the skill code(s) on the item.';
        Text016: Label 'How do you want to update the resource skill codes on the related service items?';
        Text017: Label 'Delete all the related skill codes.';
        Text018: Label 'Leave all the related skill codes.';
        Text019: Label 'You have deleted the skill code(s) on the service item group.';
        Text020: Label 'How do you want to update the resource skill codes on the related items and service items?';
        Text021: Label 'Delete all the related skill codes.';
        Text022: Label 'Leave all the related skill codes.';
        Text023: Label 'How do you want to update the resource skill codes assigned from Item and Service Item Group?';
        Text024: Label 'Delete old skill codes and assign new.';
        Text025: Label 'Leave old skill codes and do not assign new.';
        Text026: Label 'You have changed the service item group assigned to this service item/item.';
        Text027: Label 'You have changed Item No. on this service item.';
        Text028: Label 'Do you want to assign the skill codes of the item and its service item group to service item?';
        Text029: Label 'How do you want to update the resource skill codes assigned from Service Item Group?';
#pragma warning restore AA0074
        SkipValidationDialog: Boolean;
        Update2: Boolean;
        AssignCodesWithUpdate: Boolean;
#pragma warning disable AA0074
        Text030: Label '%1,%2', Comment = 'Delete all the related skill codes. Leave all the related skill codes.', Locked = true;
        Text031: Label '%1\\%2', Comment = 'You have deleted the skill code(s) on the item.\\How do you want to update the resource skill codes on the related service items?  ', Locked = true;
#pragma warning restore AA0074

    procedure AddResSkill(var ResSkill: Record "Resource Skill")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if (ResSkill.Type = ResSkill.Type::"Service Item Group") or
           (ResSkill.Type = ResSkill.Type::Item)
        then
            if IsRelatedObjectsExist(ResSkill) then begin
                if not SkipValidationDialog then
                    case ResSkill.Type of
                        ResSkill.Type::"Service Item Group":
                            if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                                exit;
                        ResSkill.Type::Item:
                            if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                                exit;
                    end;
                AddResSkillWithUpdate(ResSkill);
            end;
    end;

    local procedure AddResSkillWithUpdate(var ResSkill: Record "Resource Skill")
    begin
        case ResSkill.Type of
            ResSkill.Type::"Service Item Group":
                begin
                    AddResSkillToServItems(ResSkill);
                    AddResSkillToItems(ResSkill);
                end;
            ResSkill.Type::Item:
                AddResSkillToServItems(ResSkill)
        end;
    end;

    local procedure AddResSkillToServItems(var ResSkill: Record "Resource Skill")
    var
        ServiceItem: Record "Service Item";
    begin
        case ResSkill.Type of
            ResSkill.Type::"Service Item Group":
                ServiceItem.SetRange("Service Item Group Code", ResSkill."No.");
            ResSkill.Type::Item:
                ServiceItem.SetRange("Item No.", ResSkill."No.");
        end;
        if ServiceItem.Find('-') then
            repeat
                UnifyResSkillCode(ResSkill.Type::"Service Item", ServiceItem."No.", ResSkill);
            until ServiceItem.Next() = 0;
    end;

    local procedure AddResSkillToItems(var ResSkill: Record "Resource Skill")
    var
        Item: Record Item;
        AddedResSkill: Record "Resource Skill";
    begin
        Item.SetRange(Item."Service Item Group", ResSkill."No.");
        if Item.Find('-') then
            repeat
                if UnifyResSkillCode(ResSkill.Type::Item, Item."No.", ResSkill) then
                    if AddedResSkill.Get(AddedResSkill.Type::Item, Item."No.", ResSkill."Skill Code") then
                        AddResSkillToServItems(AddedResSkill);
            until Item.Next() = 0;
    end;

    local procedure UnifyResSkillCode(ObjectType: Enum "Resource Skill Type"; ObjectNo: Code[20]; var UnifiedResSkill: Record "Resource Skill"): Boolean
    var
        NewResSkill: Record "Resource Skill";
        ExistingResSkill: Record "Resource Skill";
    begin
        if not ExistingResSkill.Get(ObjectType, ObjectNo, UnifiedResSkill."Skill Code") then begin
            NewResSkill.Init();
            NewResSkill.Type := ObjectType;
            NewResSkill."No." := ObjectNo;
            NewResSkill."Skill Code" := UnifiedResSkill."Skill Code";

            if UnifiedResSkill.Type = NewResSkill.Type::Item then
                NewResSkill."Assigned From" := NewResSkill."Assigned From"::Item;
            if UnifiedResSkill.Type = NewResSkill.Type::"Service Item Group" then
                NewResSkill."Assigned From" := NewResSkill."Assigned From"::"Service Item Group";

            if UnifiedResSkill."Source Type" = NewResSkill."Source Type"::" " then begin
                NewResSkill."Source Code" := UnifiedResSkill."No.";
                if UnifiedResSkill.Type = UnifiedResSkill.Type::Item then
                    NewResSkill."Source Type" := NewResSkill."Source Type"::Item;
                if UnifiedResSkill.Type = NewResSkill.Type::"Service Item Group" then
                    NewResSkill."Source Type" := NewResSkill."Source Type"::"Service Item Group";
            end else begin
                NewResSkill."Source Code" := UnifiedResSkill."Source Code";
                NewResSkill."Source Type" := UnifiedResSkill."Source Type";
            end;

            OnUnifyResSkillCodeOnBeforeInsert(NewResSkill, UnifiedResSkill);

            NewResSkill.Insert();
            exit(true);
        end;
        exit;
    end;

    procedure RemoveResSkill(var ResSkill: Record "Resource Skill"): Boolean
    var
        SelectedOption: Integer;
        RelatedResSkillsExist: Boolean;
        Update: Boolean;
    begin
        RelatedResSkillsExist := IsRelatedResSkillsExist(ResSkill);

        if not SkipValidationDialog then begin
            if RelatedResSkillsExist then begin
                case ResSkill.Type of
                    ResSkill.Type::Item:
                        SelectedOption := RunOptionDialog(Text015, Text016, Text017, Text018);
                    ResSkill.Type::"Service Item Group":
                        SelectedOption := RunOptionDialog(Text019, Text020, Text021, Text022);
                end;

                case SelectedOption of
                    0:
                        Update := true;
                    1:
                        Update := false;
                    2:
                        begin
                            SkipValidationDialog := false;
                            Update2 := false;
                            Error('');
                        end;
                end;
            end;
        end else
            Update := Update2;

        if RelatedResSkillsExist then begin
            case ResSkill.Type of
                ResSkill.Type::Item:
                    RemoveItemResSkill(ResSkill, Update, false);
                ResSkill.Type::"Service Item Group":
                    RemoveServItemGroupResSkill(ResSkill, Update);
            end;
            exit(true);
        end;
    end;

    procedure PrepareRemoveMultipleResSkills(var ResSkill: Record "Resource Skill")
    var
        SelectedOption: Integer;
    begin
        if not SkipValidationDialog then
            if ResSkill.Find('-') then
                repeat
                    if IsRelatedResSkillsExist(ResSkill) then begin
                        SkipValidationDialog := true;
                        case ResSkill.Type of
                            ResSkill.Type::Item:
                                SelectedOption := RunOptionDialog(Text015, Text016, Text017, Text018);
                            ResSkill.Type::"Service Item Group":
                                SelectedOption := RunOptionDialog(Text019, Text020, Text021, Text022);
                        end;

                        case SelectedOption of
                            0:
                                Update2 := true;
                            1:
                                Update2 := false;
                            2:
                                begin
                                    SkipValidationDialog := false;
                                    Update2 := false;
                                    Error('');
                                end;
                        end;
                        exit
                    end;
                until ResSkill.Next() = 0;
    end;

    local procedure RemoveItemResSkill(var ResSkill: Record "Resource Skill"; Update: Boolean; IsReassigned: Boolean)
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        if not IsReassigned then begin
            ExistingResSkill.SetCurrentKey("Assigned From", "Source Type", "Source Code");
            ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
            ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::Item);
            ExistingResSkill.SetRange("Source Code", ResSkill."No.");
            ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
            ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
            if ExistingResSkill.Find('-') then
                if Update then
                    ExistingResSkill.DeleteAll()
                else
                    ConvertResSkillsToOriginal(ExistingResSkill);
        end;

        ServItem.SetCurrentKey("Item No.");
        ServItem.SetRange("Item No.", ResSkill."No.");
        if ServItem.Find('-') then
            repeat
                ExistingResSkill.Reset();
                ExistingResSkill.SetCurrentKey("Assigned From", "Source Type", "Source Code");
                ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
                ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::"Service Item Group");
                ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
                ExistingResSkill.SetRange("No.", ServItem."No.");
                ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
                if ExistingResSkill.Find('-') then
                    repeat
                        ExistingResSkill2 := ExistingResSkill;
                        if ServItem."Service Item Group Code" = ExistingResSkill."Source Code" then begin
                            ExistingResSkill2."Assigned From" := ExistingResSkill."Assigned From"::"Service Item Group";
                            ExistingResSkill2.Modify();
                        end else
                            if Update then
                                ExistingResSkill2.Delete()
                            else
                                if IsReassigned then begin
                                    ExistingResSkill2."Source Type" := ExistingResSkill."Source Type"::Item;
                                    ExistingResSkill2."Source Code" := ResSkill."No.";
                                    ExistingResSkill2.Modify();
                                end else
                                    ConvertResSkillToOriginal(ExistingResSkill2, true);
                    until ExistingResSkill.Next() = 0;
            until ServItem.Next() = 0;
    end;

    local procedure RemoveServItemGroupResSkill(var ResSkill: Record "Resource Skill"; Update: Boolean)
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        if Update then begin
            ExistingResSkill.SetCurrentKey("Source Type", "Source Code");
            ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::"Service Item Group");
            ExistingResSkill.SetRange("Source Code", ResSkill."No.");
            ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
            ExistingResSkill.DeleteAll();
        end else begin
            ExistingResSkill.SetCurrentKey("Assigned From", "Source Type", "Source Code");
            ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::"Service Item Group");
            ExistingResSkill.SetRange("Source Code", ResSkill."No.");
            ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
            ConvertResSkillsToOriginal(ExistingResSkill);

            ExistingResSkill.Reset();
            ExistingResSkill.SetCurrentKey("Assigned From", "Source Type", "Source Code");
            ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
            ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::"Service Item Group");
            ExistingResSkill.SetRange("Source Code", ResSkill."No.");
            ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
            if ExistingResSkill.Find('-') then
                repeat
                    if ServItem.Get(ExistingResSkill."No.") then begin
                        ExistingResSkill2 := ExistingResSkill;
                        ExistingResSkill2."Source Type" := ExistingResSkill."Source Type"::Item;
                        ExistingResSkill2."Source Code" := ServItem."Item No.";
                        ExistingResSkill2.Modify();
                    end;
                until ExistingResSkill.Next() = 0;
        end;
    end;

    procedure ChangeResSkill(var ResSkill: Record "Resource Skill"; OldSkillCode: Code[10]): Boolean
    var
        TempOldResSkill: Record "Resource Skill" temporary;
        SelectedOption: Integer;
        Update: Boolean;
    begin
        TempOldResSkill := ResSkill;
        TempOldResSkill."Skill Code" := OldSkillCode;
        if (ResSkill."Assigned From" <> ResSkill."Assigned From"::" ") or
           (ResSkill."Source Type" <> ResSkill."Source Type"::" ")
        then
            ConvertResSkillToOriginal(ResSkill, false);

        if IsRelatedResSkillsExist(TempOldResSkill) then begin
            case TempOldResSkill.Type of
                ResSkill.Type::Item:
                    SelectedOption := RunOptionDialog(Text005, Text006, Text007, Text008);
                ResSkill.Type::"Service Item Group":
                    SelectedOption := RunOptionDialog(Text010, Text011, Text012, Text013);
                ResSkill.Type::"Service Item":
                    SelectedOption := 1;
            end;

            case SelectedOption of
                0:
                    Update := true;
                1:
                    Update := false;
                2:
                    exit;
            end;

            if ResSkill.Type <> ResSkill.Type::"Service Item" then
                if Update then
                    case ResSkill.Type of
                        ResSkill.Type::"Service Item Group":
                            ChangeServItemGroupResSkill(ResSkill, OldSkillCode);
                        ResSkill.Type::Item:
                            ChangeItemResSkill(ResSkill, OldSkillCode);
                    end
                else
                    RemoveResSkill(TempOldResSkill);
        end;

        exit(true);
    end;

    local procedure ChangeServItemGroupResSkill(var ResSkill: Record "Resource Skill"; OldSkillCode: Code[10])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ExistingResSkill3: Record "Resource Skill";
    begin
        ExistingResSkill.SetRange("Skill Code", OldSkillCode);
        ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::"Service Item Group");
        ExistingResSkill.SetRange("Source Code", ResSkill."No.");
        if ExistingResSkill.Find('-') then
            repeat
                ExistingResSkill3 := ExistingResSkill;
                if not ExistingResSkill2.Get(ExistingResSkill.Type, ExistingResSkill."No.", ResSkill."Skill Code") then
                    ExistingResSkill3.Rename(ExistingResSkill.Type, ExistingResSkill."No.", ResSkill."Skill Code")
                else
                    ExistingResSkill3.Delete();
            until ExistingResSkill.Next() = 0;
    end;

    local procedure ChangeItemResSkill(var ResSkill: Record "Resource Skill"; OldSkillCode: Code[10])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        ServItem.SetCurrentKey("Item No.");
        ServItem.SetRange("Item No.", ResSkill."No.");
        if ServItem.Find('-') then
            repeat
                ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
                ExistingResSkill.SetRange("No.", ServItem."No.");
                ExistingResSkill.SetRange("Skill Code", OldSkillCode);
                ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
                if ExistingResSkill.FindFirst() then
                    if not ExistingResSkill2.Get(ExistingResSkill.Type, ExistingResSkill."No.", ResSkill."Skill Code") then begin
                        ExistingResSkill.Rename(ExistingResSkill.Type, ExistingResSkill."No.", ResSkill."Skill Code");
                        ExistingResSkill."Source Type" := ExistingResSkill."Source Type"::Item;
                        ExistingResSkill."Source Code" := ResSkill."No.";
                        ExistingResSkill.Modify();
                    end else
                        ExistingResSkill.Delete();
            until ServItem.Next() = 0;
    end;

    procedure AssignServItemResSkills(var ServItem: Record "Service Item")
    var
        ResSkill: Record "Resource Skill";
        SrcType: Enum "Resource Skill Type";
    begin
        SrcType := ResSkill.Type::"Service Item";
        AssignResSkillRelationWithUpdate(SrcType, ServItem."No.", ResSkill.Type::Item, ServItem."Item No.");
        AssignResSkillRelationWithUpdate(SrcType, ServItem."No.", ResSkill.Type::"Service Item Group", ServItem."Service Item Group Code");
    end;

    local procedure AssignRelationConfirmation(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        ServItemGroup: Record "Service Item Group";
        ServItem: Record "Service Item";
        Item: Record Item;
        ResSkill: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        SrcTypeText: Text[30];
        DestTypeText: Text[30];
    begin
        ResSkill.SetRange(Type, DestType);
        ResSkill.SetRange("No.", DestCode);
        if ResSkill.FindFirst() then begin
            case DestType of
                ResSkill.Type::"Service Item Group":
                    DestTypeText := CopyStr(ServItemGroup.TableCaption(), 1, MaxStrlen(DestTypeText));
                ResSkill.Type::Item:
                    DestTypeText := CopyStr(Item.TableCaption(), 1, MaxStrlen(DestTypeText));
            end;

            case SrcType of
                ResSkill.Type::Item:
                    SrcTypeText := CopyStr(Item.TableCaption(), 1, MaxStrlen(SrcTypeText));
                ResSkill.Type::"Service Item":
                    SrcTypeText := CopyStr(ServItem.TableCaption(), 1, MaxStrlen(SrcTypeText));
            end;

            OnAfterAssignRelationConfirmation(ResSkill, SrcType, DestType, DestTypeText, SrcTypeText);

            exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text002, DestTypeText, DestCode, SrcTypeText, SrcCode), true));
        end;
    end;

    procedure AssignResSkillRelationWithUpdate(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20])
    var
        OriginalResSkill: Record "Resource Skill";
        AddedResSkill: Record "Resource Skill";
    begin
        OriginalResSkill.SetRange(Type, DestType);
        OriginalResSkill.SetRange("No.", DestCode);
        if OriginalResSkill.Find('-') then
            repeat
                if UnifyResSkillCode(SrcType, SrcCode, OriginalResSkill) then
                    if SrcType = OriginalResSkill.Type::Item then
                        if AddedResSkill.Get(SrcType, SrcCode, OriginalResSkill."Skill Code") then
                            AddResSkillToServItems(AddedResSkill);
            until OriginalResSkill.Next() = 0;
    end;

    procedure DeleteItemResSkills(ItemNo: Code[20])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ConfirmManagement: Codeunit "Confirm Management";
        Update: Boolean;
    begin
        ExistingResSkill.SetCurrentKey("Source Type", "Source Code");
        ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::Item);
        ExistingResSkill.SetRange("Source Code", ItemNo);
        if ExistingResSkill.Find('-') then
            Update := ConfirmManagement.GetResponseOrDefault(Text004, true)
        else
            Update := true;

        ExistingResSkill.LockTable();
        ExistingResSkill.Reset();
        ExistingResSkill.SetRange(Type, ExistingResSkill.Type::Item);
        ExistingResSkill.SetRange("No.", ItemNo);
        if ExistingResSkill.Find('-') then begin
            repeat
                ExistingResSkill2 := ExistingResSkill;
                RemoveItemResSkill(ExistingResSkill2, Update, false);
                ExistingResSkill2.Delete();
            until ExistingResSkill.Next() = 0;

            ServiceItem.Reset();
            ServiceItem.SetRange("Item No.", ItemNo);
            if ServiceItem.Find('-') then
                repeat
                    RemoveServItemGroupRelation(ServiceItem."No.", Update, ExistingResSkill.Type::"Service Item");
                until ServiceItem.Next() = 0;
        end;
    end;

    procedure DeleteServItemGrResSkills(ServItemGrCode: Code[10])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        Update: Boolean;
    begin
        ExistingResSkill.SetCurrentKey("Source Type", "Source Code");
        ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::"Service Item Group");
        ExistingResSkill.SetRange("Source Code", ServItemGrCode);
        if ExistingResSkill.Find('-') then
            Update := ConfirmManagement.GetResponseOrDefault(Text003, true)
        else
            Update := true;

        ExistingResSkill.LockTable();
        ExistingResSkill.Reset();
        ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item Group");
        ExistingResSkill.SetRange("No.", ServItemGrCode);
        if ExistingResSkill.Find('-') then
            repeat
                ExistingResSkill2 := ExistingResSkill;
                RemoveServItemGroupResSkill(ExistingResSkill2, Update);
                ExistingResSkill2.Delete();
            until ExistingResSkill.Next() = 0;
    end;

    procedure DeleteServItemResSkills(ServItemNo: Code[20])
    var
        ExistingResSkill: Record "Resource Skill";
    begin
        ExistingResSkill.LockTable();
        ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
        ExistingResSkill.SetRange("No.", ServItemNo);
        ExistingResSkill.DeleteAll();
    end;

    procedure ChangeResSkillRelationWithItem(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; RelationType: Enum "Resource Skill Type"; DestCode: Code[20]; OriginalCode: Code[20]; ServItemGroupCode: Code[10]): Boolean
    var
        Item: Record Item;
        ExistingResSkill: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        SelectedOption: Integer;
        RemoveWithUpdate: Boolean;
        AssignWithUpdate: Boolean;
        ResSkillCodesExistRelatedItem: Boolean;
        ResSkillCodesExistRelatedSIG: Boolean;
        ResSkillCodesItemExist: Boolean;
        IsHandled: Boolean;
    begin
        if not SkipValidationDialog then begin
            if OriginalCode <> '' then begin
                ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
                ExistingResSkill.SetRange("No.", SrcCode);
                ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
                ResSkillCodesExistRelatedItem := ExistingResSkill.FindFirst();
            end;
            if ServItemGroupCode <> '' then begin
                ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::"Service Item Group");
                ResSkillCodesExistRelatedSIG := ExistingResSkill.FindFirst();
            end;
            if ResSkillCodesExistRelatedItem or ResSkillCodesExistRelatedSIG then begin
                SelectedOption := RunOptionDialog(Text027, Text023, Text024, Text025);
                case SelectedOption of
                    0:
                        RemoveWithUpdate := true;
                    1:
                        RemoveWithUpdate := false;
                    2:
                        exit;
                end;
                AssignWithUpdate := RemoveWithUpdate;
            end else begin
                if DestCode <> '' then begin
                    ExistingResSkill.Reset();
                    ExistingResSkill.SetRange(Type, ExistingResSkill.Type::Item);
                    ExistingResSkill.SetRange("No.", DestCode);
                    ResSkillCodesItemExist := ExistingResSkill.FindFirst();
                    if not ResSkillCodesItemExist then
                        if Item.Get(DestCode) then
                            if Item."Service Item Group" <> '' then begin
                                ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item Group");
                                ExistingResSkill.SetRange("No.", Item."Service Item Group");
                                ResSkillCodesItemExist := not ExistingResSkill.IsEmpty();
                            end;
                    if ResSkillCodesItemExist then begin
                        IsHandled := false;
                        OnChangeResSkillRelationWithItemOnBeforeAssignWithUpdateGetResponse(Item, AssignWithUpdate, IsHandled);
                        if not IsHandled then
                            AssignWithUpdate := ConfirmManagement.GetResponseOrDefault(Text028, true);
                    end;
                end;
                if Item.Get(DestCode) and AssignWithUpdate then
                    if Item."Service Item Group" <> '' then
                        AssignCodesWithUpdate := true;
            end;
        end else
            AssignWithUpdate := AssignCodesWithUpdate;

        if ResSkillCodesExistRelatedItem then
            RemoveItemRelation(SrcCode, RemoveWithUpdate);

        if ResSkillCodesExistRelatedSIG then
            RemoveServItemGroupRelation(SrcCode, RemoveWithUpdate, SrcType);

        if (DestCode <> '') and AssignWithUpdate then
            AssignResSkillRelationWithUpdate(SrcType, SrcCode, RelationType, DestCode);

        exit(true);
    end;

    procedure ChangeResSkillRelationWithGroup(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; RelationType: Enum "Resource Skill Type"; DestCode: Code[20]; OriginalCode: Code[20]): Boolean
    var
        ExistingResSkill: Record "Resource Skill";
        SelectedOption: Integer;
        AssignWithUpdate: Boolean;
        RelatedResSkillCodesExist: Boolean;
        RemoveWithUpdate: Boolean;
    begin
        if not SkipValidationDialog then begin
            if OriginalCode <> '' then begin
                ExistingResSkill.SetRange(Type, SrcType);
                ExistingResSkill.SetRange("No.", SrcCode);
                ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::"Service Item Group");
                RelatedResSkillCodesExist := not ExistingResSkill.IsEmpty();
            end;
            if RelatedResSkillCodesExist then begin
                SelectedOption := RunOptionDialog(Text026, Text029, Text024, Text025);
                case SelectedOption of
                    0:
                        RemoveWithUpdate := true;
                    1:
                        RemoveWithUpdate := false;
                    2:
                        exit;
                end;
                AssignWithUpdate := RemoveWithUpdate;
            end else
                if DestCode <> '' then
                    AssignWithUpdate := AssignRelationConfirmation(SrcType, SrcCode, RelationType, DestCode);
        end else
            AssignWithUpdate := AssignCodesWithUpdate;

        if RelatedResSkillCodesExist then
            RemoveServItemGroupRelation(SrcCode, RemoveWithUpdate, SrcType);

        if (DestCode <> '') and AssignWithUpdate then
            AssignResSkillRelationWithUpdate(SrcType, SrcCode, RelationType, DestCode);

        exit(true);
    end;

    local procedure RemoveItemRelation(SrcCode: Code[20]; RemoveWithUpdate: Boolean)
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
        ExistingResSkill.SetRange("No.", SrcCode);
        ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
        if ExistingResSkill.Find('-') then
            repeat
                ExistingResSkill2 := ExistingResSkill;
                if ExistingResSkill."Source Type" = ExistingResSkill."Source Type"::Item then begin
                    if RemoveWithUpdate then
                        ExistingResSkill2.Delete()
                    else
                        ConvertResSkillsToOriginal(ExistingResSkill);
                end else
                    if ServItem.Get(ExistingResSkill."No.") then
                        if ServItem."Service Item Group Code" = ExistingResSkill."Source Code" then begin
                            ExistingResSkill2."Assigned From" := ExistingResSkill."Assigned From"::"Service Item Group";
                            ExistingResSkill2.Modify();
                        end else
                            if RemoveWithUpdate then
                                ExistingResSkill2.Delete()
                            else
                                ConvertResSkillToOriginal(ExistingResSkill2, true);
            until ExistingResSkill.Next() = 0;
    end;

    local procedure RemoveServItemGroupRelation(SrcCode: Code[20]; RemoveWithUpdate: Boolean; SrcType: Enum "Resource Skill Type")
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
    begin
        ExistingResSkill.SetRange(Type, SrcType);
        ExistingResSkill.SetRange("No.", SrcCode);
        ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::"Service Item Group");
        if ExistingResSkill.Find('-') then
            repeat
                ExistingResSkill2 := ExistingResSkill;
                if SrcType = ExistingResSkill.Type::Item then
                    RemoveItemResSkill(ExistingResSkill2, RemoveWithUpdate, true);
                if RemoveWithUpdate then
                    ExistingResSkill2.Delete()
                else
                    ConvertResSkillToOriginal(ExistingResSkill, true);
            until ExistingResSkill.Next() = 0;
    end;

    local procedure ConvertResSkillToOriginal(var ResSkill: Record "Resource Skill"; AllowModify: Boolean)
    begin
        ResSkill."Assigned From" := ResSkill."Assigned From"::" ";
        ResSkill."Source Type" := ResSkill."Source Type"::" ";
        ResSkill."Source Code" := '';
        if AllowModify then
            ResSkill.Modify();
    end;

    local procedure ConvertResSkillsToOriginal(var ResSkill: Record "Resource Skill")
    begin
        if ResSkill.Find('-') then
            repeat
                ConvertResSkillToOriginal(ResSkill, true);
            until ResSkill.Next() = 0;
    end;

    local procedure IsRelatedObjectsExist(var ResSkill: Record "Resource Skill"): Boolean
    var
        Item: Record Item;
        ServItem: Record "Service Item";
    begin
        case ResSkill.Type of
            ResSkill.Type::"Service Item Group":
                begin
                    ServItem.SetCurrentKey("Service Item Group Code");
                    ServItem.SetRange("Service Item Group Code", ResSkill."No.");
                    if not ServItem.IsEmpty() then
                        exit(true);

                    Item.SetCurrentKey("Service Item Group");
                    Item.SetRange("Service Item Group", ResSkill."No.");
                    exit(not Item.IsEmpty());
                end;
            ResSkill.Type::Item:
                begin
                    ServItem.SetCurrentKey("Item No.");
                    ServItem.SetRange("Item No.", ResSkill."No.");
                    exit(not ServItem.IsEmpty());
                end;
        end;
        exit
    end;

    local procedure IsRelatedResSkillsExist(var ResSkill: Record "Resource Skill"): Boolean
    var
        ExistingResSkill: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        case ResSkill.Type of
            ExistingResSkill.Type::Item:
                begin
                    ExistingResSkill.SetCurrentKey("Assigned From", "Source Type", "Source Code");
                    ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
                    ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::Item);
                    ExistingResSkill.SetRange("Source Code", ResSkill."No.");
                    ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
                    ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
                    if not ExistingResSkill.IsEmpty() then
                        exit(true);

                    ServItem.SetCurrentKey("Item No.");
                    ServItem.SetRange("Item No.", ResSkill."No.");
                    if ServItem.Find('-') then
                        repeat
                            ExistingResSkill.Reset();
                            ExistingResSkill.SetCurrentKey("Assigned From", "Source Type", "Source Code");
                            ExistingResSkill.SetRange("Assigned From", ExistingResSkill."Assigned From"::Item);
                            ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::"Service Item Group");
                            ExistingResSkill.SetRange(Type, ExistingResSkill.Type::"Service Item");
                            ExistingResSkill.SetRange("No.", ServItem."No.");
                            ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
                            if not ExistingResSkill.IsEmpty() then
                                exit(true);
                        until ServItem.Next() = 0;
                end;
            ExistingResSkill.Type::"Service Item Group":
                begin
                    ExistingResSkill.SetCurrentKey("Source Type", "Source Code");
                    ExistingResSkill.SetRange("Source Type", ExistingResSkill."Source Type"::"Service Item Group");
                    ExistingResSkill.SetRange("Source Code", ResSkill."No.");
                    ExistingResSkill.SetRange("Skill Code", ResSkill."Skill Code");
                    if not ExistingResSkill.IsEmpty() then
                        exit(true);
                end;
        end;
    end;

    local procedure RunOptionDialog(ProblemDescription: Text[200]; SolutionProposition: Text[200]; FirstStrategy: Text[200]; SecondStrategy: Text[200]): Integer
    var
        SelectedOption: Integer;
    begin
        SelectedOption := StrMenu(StrSubstNo(Text030, FirstStrategy, SecondStrategy), 1,
            StrSubstNo(Text031, ProblemDescription, SolutionProposition));

        if SelectedOption = 0 then
            exit(2);

        exit(SelectedOption - 1);
    end;

    procedure RevalidateResSkillRelation(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        AssignRelation: Boolean;
    begin
        if IsNewCodesAdded(SrcType, SrcCode, DestType, DestCode) then begin
            if not SkipValidationDialog then
                AssignRelation := RevalidateRelationConfirmation(SrcType, SrcCode, DestType, DestCode)
            else
                AssignRelation := true;

            if AssignRelation then begin
                AssignResSkillRelationWithUpdate(SrcType, SrcCode, DestType, DestCode);
                exit(true)
            end;
        end;
    end;

    local procedure RevalidateRelationConfirmation(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        ServItemGroup: Record "Service Item Group";
        ServItem: Record "Service Item";
        Item: Record Item;
        ResSkill: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        SrcTypeText: Text[30];
        DestTypeText: Text[30];
    begin
        case DestType of
            ResSkill.Type::"Service Item Group":
                DestTypeText := CopyStr(ServItemGroup.TableCaption(), 1, MaxStrlen(DestTypeText));
            ResSkill.Type::Item:
                DestTypeText := CopyStr(Item.TableCaption(), 1, MaxStrlen(DestTypeText));
        end;

        case SrcType of
            ResSkill.Type::Item:
                SrcTypeText := CopyStr(Item.TableCaption(), 1, MaxStrlen(SrcTypeText));
            ResSkill.Type::"Service Item":
                SrcTypeText := CopyStr(ServItem.TableCaption(), 1, MaxStrlen(SrcTypeText));
        end;

        OnAfterRevalidateRelationConfirmation(ResSkill, SrcType, DestType, DestTypeText, SrcTypeText);

        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text002, DestTypeText, DestCode, SrcTypeText, SrcCode), true));
    end;

    local procedure IsNewCodesAdded(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        DestResSkill: Record "Resource Skill";
        SrcResSkill: Record "Resource Skill";
    begin
        DestResSkill.SetRange(Type, DestType);
        DestResSkill.SetRange("No.", DestCode);
        if DestResSkill.Find('-') then
            repeat
                SrcResSkill.SetRange(Type, SrcType);
                SrcResSkill.SetRange("No.", SrcCode);
                SrcResSkill.SetRange("Skill Code", DestResSkill."Skill Code");
                if SrcResSkill.IsEmpty() then
                    exit(true);
            until DestResSkill.Next() = 0
    end;

    procedure DropGlobals()
    begin
        SkipValidationDialog := false;
        Update2 := false;
    end;

    procedure SkipValidationDialogs()
    begin
        SkipValidationDialog := true;
    end;

    procedure CloneObjectResourceSkills(ObjectType: Integer; SrcCode: Code[20]; DestCode: Code[20])
    var
        ResSkill: Record "Resource Skill";
        NewResSkill: Record "Resource Skill";
    begin
        ResSkill.SetRange(Type, ObjectType);
        ResSkill.SetRange("No.", SrcCode);
        if ResSkill.Find('-') then
            repeat
                NewResSkill.Init();
                NewResSkill := ResSkill;
                NewResSkill."No." := DestCode;
                NewResSkill.Insert();
            until ResSkill.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnifyResSkillCodeOnBeforeInsert(var NewResourceSkill: Record "Resource Skill"; var UnifiedResourceSkill: Record "Resource Skill")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignRelationConfirmation(var ResourceSkill: Record "Resource Skill"; SrcType: Enum "Resource Skill Type"; DestType: Enum "Resource Skill Type"; var SrcTypeText: Text[30]; var DestTypeText: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeResSkillRelationWithItemOnBeforeAssignWithUpdateGetResponse(Item: Record Item; var AssignWithUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRevalidateRelationConfirmation(var ResourceSkill: Record "Resource Skill"; SrcType: Enum "Resource Skill Type"; DestType: Enum "Resource Skill Type"; var SrcTypeText: Text[30]; var DestTypeText: Text[30])
    begin
    end;
}

