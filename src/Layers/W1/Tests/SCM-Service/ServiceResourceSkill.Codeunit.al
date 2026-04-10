// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Item;
using Microsoft.Service.Item;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;

codeunit 136126 "Service Resource Skill"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Resource Skill] [Service]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ErrorResourceSkillFound: Label '%1 must not exist.';
        ErroResourceSkillChanged: Label 'Skill Code must not be same.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Resource Skill");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Resource Skill");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Resource Skill");
    end;

    [Test]
    [HandlerFunctions('ConfirmServiceItem')]
    [Scope('OnPrem')]
    procedure AssignSkillCodesOnServiceItem()
    var
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        SkillCode: Code[10];
    begin
        // Covers document number TC141402 - refer to TFS ID 172907.
        // The Test Case assign the Resource Skill in Service Item through Service Item Group.

        // Setup: Create a new Service Item, Create Service Item Group and modify the Service Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        AttachItemGroupToServiceItem(ServiceItem, ServiceItemGroup.Code);
        SkillCode := CreateResourceSkill(ServiceItem."No.", ResourceSkill.Type::"Service Item");

        // Exercise: Create the Resource Skill for Service Item Group.
        CreateResourceSkillsItemGroup(SkillCode, ServiceItemGroup.Code);

        // Verify: Verify the Resource Skill of Service Item with Service Item Group.
        VerifyResourceSkill(ServiceItem."No.", ServiceItemGroup.Code, ResourceSkill.Type::"Service Item");
    end;

    [Test]
    [HandlerFunctions('ConfirmServiceItem')]
    [Scope('OnPrem')]
    procedure AssignSkillCodesOnItem()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        ServiceItemGroup: Record "Service Item Group";
        LibraryInventory: Codeunit "Library - Inventory";
        SkillCode: Code[10];
    begin
        // Covers document number TC141402 - refer to TFS ID 172907.
        // The Test Case assign the Resource Skill in Item through Service Item Group.

        // Setup: Create a Service Item Group, create an Item, modify the Item and create the Resource Skill for Item.
        Initialize();
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        LibraryInventory.CreateItem(Item);
        AttachServiceItemGroupOnItem(Item, ServiceItemGroup.Code);

        // Exercise: Create the Resource Skill for Item and Service Item Group.
        SkillCode := CreateResourceSkill(Item."No.", ResourceSkill.Type::Item);
        CreateResourceSkillsItemGroup(SkillCode, ServiceItemGroup.Code);

        // Verify: Verify the Resource Skill of Item with Service Item Group.
        VerifyResourceSkill(Item."No.", ServiceItemGroup.Code, ResourceSkill.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSkillCodeOnItem()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        LibraryInventory: Codeunit "Library - Inventory";
        SkillCode: Code[10];
    begin
        // Covers document number TC141402 - refer to TFS ID 172907.
        // The Test Case checks that the Resource Skill is modified on Item.

        // Setup: Create a new Item.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Exercise: Change the Resource Skill on Item.
        SkillCode := CreateResourceSkill(Item."No.", ResourceSkill.Type::Item);
        RenameResourceSkill(Item."No.", SkillCode);

        // Verify: Verify the Resource Skill has changed on Item.
        VerifyResourceSkillChange(Item."No.", SkillCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmServiceItem')]
    [Scope('OnPrem')]
    procedure DeleteServiceItem()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Covers document number TC141402 - refer to TFS ID 172907.
        // The Test Case checks the deletion of Service Item from Resource Skill.

        // Setup: Create a new Service Item Group, Create a new Item and modify the Item, Create Resource Skill on Item, create a new
        // Service Item and modify the Service Item with Item No.
        Initialize();
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        LibraryInventory.CreateItem(Item);
        AttachServiceItemGroupOnItem(Item, ServiceItemGroup.Code);
        CreateResourceSkill(Item."No.", ResourceSkill.Type::Item);
        LibraryService.CreateServiceItem(ServiceItem, '');
        AttachItemToServiceItem(ServiceItem, Item."No.");

        // Exercise: Delete the Service Item.
        ServiceItem.Delete(true);

        // Verify: Verify the Service Item in Resource Skill.
        VerifyResourceSkillDelete(ServiceItem."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmServiceItem,StringMenuHandlerWithAll')]
    [Scope('OnPrem')]
    procedure DeleteServiceItemGroupCode()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemGroup: Record "Service Item Group";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Covers document number TC141402 - refer to TFS ID 172907.
        // The Test Case checks the deletion of Resource Skill from Service Item Group without deleting the Resource Skill from item and
        // Service Item.

        // Setup: Create a new Item, find Skill Code, create Service Item Group, create Resource Skill, modify the Item with Service
        // Item Group, Create Service Item and modify the Service Item with Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        CreateResourceSkill(ServiceItemGroup.Code, ResourceSkill.Type::"Service Item Group");
        AttachServiceItemGroupOnItem(Item, ServiceItemGroup.Code);
        LibraryService.CreateServiceItem(ServiceItem, '');
        AttachItemToServiceItem(ServiceItem, Item."No.");

        // Exercise: Delete the Service Item Group from Item.
        AttachServiceItemGroupOnItem(Item, '');

        // Verify: Verify that Service Item Group must be blank in Item.
        Item.TestField("Service Item Group", '');
    end;

    [Normal]
    local procedure CreateResourceSkillsItemGroup(SkillCode2: Code[10]; ServiceItemGroupCode: Code[10])
    var
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        LibraryResource: Codeunit "Library - Resource";
        Counter: Integer;
    begin
        // Creating Resource Skill and Skill Codes.
        Clear(ResourceSkill);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItemGroupCode, SkillCode2);

        // Use RANDOM for creating Resource Skill between 1 to 5.
        for Counter := 1 to 1 + LibraryRandom.RandInt(4) do begin
            Clear(ResourceSkill);
            Clear(SkillCode);
            LibraryResource.CreateSkillCode(SkillCode);
            LibraryResource.CreateResourceSkill(
              ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItemGroupCode, SkillCode.Code);
        end;
    end;

    [Normal]
    local procedure CreateResourceSkill(No: Code[20]; Type: Enum "Resource Skill Type"): Code[10]
    var
        ResourceSkill: Record "Resource Skill";
        SkillCode: Record "Skill Code";
        LibraryResource: Codeunit "Library - Resource";
    begin
        FindSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, Type, No, SkillCode.Code);
        exit(SkillCode.Code);
    end;

    [Normal]
    local procedure FindSkillForServiceItemGroup(var ResourceSkill: Record "Resource Skill"; ServiceItemGroup: Code[10])
    begin
        ResourceSkill.SetRange(Type, ResourceSkill.Type::"Service Item Group");
        ResourceSkill.SetRange("No.", ServiceItemGroup);
        ResourceSkill.FindSet();
    end;

    [Normal]
    local procedure FindResourceSkillForItem(var ResourceSkill: Record "Resource Skill"; No: Code[20]; Type: Enum "Resource Skill Type")
    begin
        ResourceSkill.SetRange(Type, Type);
        ResourceSkill.SetRange("No.", No);
        ResourceSkill.FindSet();
    end;

    [Normal]
    local procedure FindSkillCode(var SkillCode: Record "Skill Code")
    begin
        SkillCode.FindFirst();
    end;

    [Normal]
    local procedure AttachServiceItemGroupOnItem(var Item: Record Item; ServiceItemGroupCode: Code[10])
    begin
        Item.Validate("Service Item Group", ServiceItemGroupCode);
        Item.Modify(true);
    end;

    [Normal]
    local procedure RenameResourceSkill(ItemNo: Code[20]; "Code": Code[10])
    var
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
    begin
        ResourceSkill.Get(ResourceSkill.Type::Item, ItemNo, Code);
        SkillCode.Init();
        SkillCode.SetFilter(Code, '<> %1', ResourceSkill."Skill Code");
        SkillCode.FindFirst();

        ResourceSkill.Rename(ResourceSkill.Type::Item, ItemNo, SkillCode.Code);
    end;

    [Normal]
    local procedure AttachItemToServiceItem(var ServiceItem: Record "Service Item"; ItemNo: Code[20])
    begin
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    [Normal]
    local procedure AttachItemGroupToServiceItem(var ServiceItem: Record "Service Item"; ServiceItemGroupCode: Code[10])
    begin
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItem.Modify(true);
    end;

    [Normal]
    local procedure VerifyResourceSkillChange(ItemNo: Code[20]; SkillCode: Code[10])
    var
        ResourceSkill: Record "Resource Skill";
    begin
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Item);
        ResourceSkill.SetRange("No.", ItemNo);
        ResourceSkill.FindFirst();
        Assert.AreNotEqual(ResourceSkill."Skill Code", SkillCode, ErroResourceSkillChanged);
    end;

    [Normal]
    local procedure VerifyResourceSkillDelete(ServiceItemNo: Code[20])
    var
        ResourceSkill: Record "Resource Skill";
    begin
        ResourceSkill.SetRange(Type, ResourceSkill.Type::"Service Item");
        ResourceSkill.SetRange("No.", ServiceItemNo);
        Assert.IsFalse(ResourceSkill.FindFirst(), StrSubstNo(ErrorResourceSkillFound, ResourceSkill.TableCaption()));
    end;

    [Normal]
    local procedure VerifyResourceSkill(ItemNo: Code[20]; ServiceItemGroup: Code[10]; Type: Enum "Resource Skill Type")
    var
        ResourceSkill: Record "Resource Skill";
        ResourceSkill2: Record "Resource Skill";
    begin
        FindSkillForServiceItemGroup(ResourceSkill2, ServiceItemGroup);
        FindResourceSkillForItem(ResourceSkill, ItemNo, Type);
        repeat
            ResourceSkill.TestField("Skill Code", ResourceSkill2."Skill Code");
            ResourceSkill2.Next();
        until ResourceSkill.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmServiceItem(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandlerWithAll(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;
}

