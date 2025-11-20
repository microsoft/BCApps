// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.StandardCost;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Utilities;

codeunit 137109 "SCM Kitting - Std Cost Wksheet"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Cost Standard] [Standard Cost Worksheet] [SCM]
        isInitialized := false;
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryTrees: Codeunit "Library - Trees";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        GLBStandardCostAdj: Decimal;
        GLBIndirectCostAdj: Decimal;
        GLBOverheadRateAdj: Decimal;
        GLBDirectResourceNo: Code[20];
        GLBCompItemNo: Code[20];
        GLBParentItemNo: Code[20];
        GLBRoundingMethod: Code[10];
        ERRWrongCost: Label 'Wrong %1.';

    [Test]
    [HandlerFunctions('SuggestItemStdCostHandler,SuggestWorkMachCtrResStdCostHandler')]
    [Scope('OnPrem')]
    procedure TopItemProducedSuggest()
    begin
        MixedTreeStdCostWorksheet(Item."Replenishment System"::"Prod. Order", 2, true, false, false);
    end;

    [Test]
    [HandlerFunctions('SuggestItemStdCostHandler,SuggestWorkMachCtrResStdCostHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssembledSuggest()
    begin
        MixedTreeStdCostWorksheet(Item."Replenishment System"::Assembly, 2, true, false, false);
    end;

    [Test]
    [HandlerFunctions('SuggestItemStdCostHandler,SuggestWorkMachCtrResStdCostHandler,RollupStdCostHandler,StdCostMsgHandler')]
    [Scope('OnPrem')]
    procedure TopItemProducedRollup()
    begin
        MixedTreeStdCostWorksheet(Item."Replenishment System"::"Prod. Order", 2, true, true, false);
    end;

    [Test]
    [HandlerFunctions('SuggestItemStdCostHandler,SuggestWorkMachCtrResStdCostHandler,RollupStdCostHandler,StdCostMsgHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssembledRollup()
    begin
        MixedTreeStdCostWorksheet(Item."Replenishment System"::Assembly, 2, true, true, false);
    end;

    [Test]
    [HandlerFunctions('SuggestItemStdCostHandler,SuggestWorkMachCtrResStdCostHandler,RollupStdCostHandler,ImplementStdCostHandler,StdCostMsgHandler')]
    [Scope('OnPrem')]
    procedure TopItemProducedImplement()
    begin
        MixedTreeStdCostWorksheet(Item."Replenishment System"::"Prod. Order", 2, true, true, true);
    end;

    [Test]
    [HandlerFunctions('SuggestItemStdCostHandler,SuggestWorkMachCtrResStdCostHandler,RollupStdCostHandler,ImplementStdCostHandler,StdCostMsgHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssembledImplement()
    begin
        MixedTreeStdCostWorksheet(Item."Replenishment System"::Assembly, 2, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCostShareWithZeroNewStandardCost()
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 201072] New cost shares in the standard cost worksheet are set to 0 when "New Standard Cost" field is validated with 0 amount

        Initialize();

        StandardCostWorksheet.Init();
        StandardCostWorksheet.Validate(Type, StandardCostWorksheet.Type::Item);
        StandardCostWorksheet.Validate("Standard Cost", LibraryRandom.RandDec(100, 2));
        StandardCostWorksheet.Validate("New Standard Cost", 0);
        StandardCostWorksheet.TestField("New Single-Lvl Material Cost", 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Std Cost Wksheet");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Std Cost Wksheet");

        LibraryERMCountryData.CreateVATData();
        SourceCodeSetup.Get();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Std Cost Wksheet");
    end;

    local procedure MixedTreeStdCostWorksheet(TopItemReplSystem: Enum "Replenishment System"; TreeDepth: Integer; Suggest: Boolean; Rollup: Boolean; Implement: Boolean)
    var
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        Item: Record Item;
        Overhead: Decimal;
    begin
        Initialize();

        // Setup: Create mixed tree and rollup the cost.
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, TreeDepth, 2, 0);
        GetTree(TempItem, TempResource, Overhead, Overhead, Overhead, Overhead, Overhead, Overhead, Item);

        // Set report parameters.
        SetGlobalParameters(TempItem, TempResource, Item."No.");

        // Make sure tree nodes contain indirect costs and overhead.
        AddOverhead(TempItem, TempResource);

        // Add inventory to allow revaluation journal line generation.
        AddItemInventory(GLBCompItemNo);
        AddItemInventory(GLBParentItemNo);

        // Exercise: Suggest new standard costs, rollup and implement cost changes.
        TestStdCostWksheet(Suggest, Rollup, Implement);
    end;

    local procedure TestStdCostWksheet(Suggest: Boolean; Rollup: Boolean; Implement: Boolean)
    var
        StdCostWorksheet: Record "Standard Cost Worksheet";
        StdCostWorksheetPage: TestPage "Standard Cost Worksheet";
    begin
        StdCostWorksheet.DeleteAll(true);
        Commit();

        StdCostWorksheetPage.OpenEdit();
        Commit();

        if Suggest then begin
            StdCostWorksheetPage."Suggest I&tem Standard Cost".Invoke(); // Suggest item standard cost for leaves.

            // Verify: Suggested item cost is correct.
            VerifyStdCostWksheetLine(StdCostWorksheet.Type::Item, GLBCompItemNo, false, GLBRoundingMethod);

            StdCostWorksheetPage."Suggest &Capacity Standard Cost".Invoke(); // Suggest work center / machine center / resource standard cost.

            // Verify: Suggested resource cost is correct.
            VerifyStdCostWksheetLine(StdCostWorksheet.Type::Resource, GLBDirectResourceNo, false, GLBRoundingMethod);
        end;

        if Rollup then begin
            StdCostWorksheetPage."Roll Up Standard Cost".Invoke(); // Rollup standard cost for the top item.

            // Verify: Rollup standard cost is correct for top item.
            VerifyStdCostWksheetLine(StdCostWorksheet.Type::Item, GLBParentItemNo, false, '');
        end;

        if Implement then begin
            StdCostWorksheetPage."&Implement Standard Cost Changes".Invoke(); // Implement standard cost change for top item.

            // Verify: Changes were implemented in the item/resource cards. Revaluation Jnl Line was generated correctly.
            VerifyCard(BOMComponent.Type::Item, GLBParentItemNo);
            VerifyCard(BOMComponent.Type::Item, GLBCompItemNo);
            VerifyCard(BOMComponent.Type::Resource, GLBDirectResourceNo);
            VerifyRevalJnlLine(GLBCompItemNo);
            VerifyRevalJnlLine(GLBParentItemNo);
        end;

        StdCostWorksheetPage.OK().Invoke();
    end;

    local procedure VerifyStdCostWksheetLine(Type: Enum "Standard Cost Source Type"; No: Code[20]; Implemented: Boolean; RndMethodCode: Code[10])
    var
        StdCostWorksheet: Record "Standard Cost Worksheet";
        Item: Record Item;
        Resource: Record Resource;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        RolledUpMaterialCost: Decimal;
        RolledUpCapacityCost: Decimal;
        RolledUpCapOvhd: Decimal;
        SglLevelMaterialCost: Decimal;
        SglLevelCapCost: Decimal;
        SglLevelCapOvhd: Decimal;
    begin
        StdCostWorksheet.SetRange(Type, Type);
        StdCostWorksheet.SetRange("No.", No);
        StdCostWorksheet.FindFirst();
        StdCostWorksheet.TestField(Implemented, Implemented);
        case StdCostWorksheet.Type of
            StdCostWorksheet.Type::Item:
                begin
                    Item.Get(No);
                    StdCostWorksheet.TestField("Replenishment System", Item."Replenishment System");
                    StdCostWorksheet.TestField("Standard Cost", Item."Standard Cost");
                    StdCostWorksheet.TestField("Indirect Cost %", Item."Indirect Cost %");
                    StdCostWorksheet.TestField("Overhead Rate", Item."Overhead Rate");

                    Assert.AreNearlyEqual(
                      GetRoundedAmount(
                        GetTree(
                          TempItem, TempResource, RolledUpMaterialCost, RolledUpCapacityCost, RolledUpCapOvhd, SglLevelMaterialCost,
                          SglLevelCapCost, SglLevelCapOvhd, Item), RndMethodCode), StdCostWorksheet."New Standard Cost",
                      LibraryERM.GetAmountRoundingPrecision(), 'Std. cost Adj factor:' + Format(GLBStandardCostAdj));
                    Assert.AreNearlyEqual(
                      GetRoundedAmount(StdCostWorksheet."Indirect Cost %" * GLBIndirectCostAdj, RndMethodCode),
                      StdCostWorksheet."New Indirect Cost %", LibraryERM.GetAmountRoundingPrecision(),
                      'Ind. cost Adj factor:' + Format(GLBIndirectCostAdj));
                    Assert.AreNearlyEqual(
                      GetRoundedAmount(StdCostWorksheet."Overhead Rate" * GLBOverheadRateAdj, RndMethodCode),
                      StdCostWorksheet."New Overhead Rate", LibraryERM.GetAmountRoundingPrecision(),
                      'Ovhd. Rate Adj factor:' + Format(GLBOverheadRateAdj));
                    Assert.AreNearlyEqual(
                      SglLevelMaterialCost, StdCostWorksheet."New Single-Lvl Material Cost", 1, 'Incorrect sgl. level Material Cost.');
                    Assert.AreNearlyEqual(SglLevelCapCost, StdCostWorksheet."New Single-Lvl Cap. Cost", 1, 'Incorrect sgl. level Cap. Cost.');
                    Assert.AreNearlyEqual(
                      SglLevelCapOvhd, StdCostWorksheet."New Single-Lvl Cap. Ovhd Cost", 1, 'Incorrect sgl. level Cap. Ovhd. Cost.');
                    Assert.AreNearlyEqual(
                      RolledUpMaterialCost, StdCostWorksheet."New Rolled-up Material Cost", 1, 'Incorrect Rolled Up Material Cost.');
                    Assert.AreNearlyEqual(
                      RolledUpCapacityCost, StdCostWorksheet."New Rolled-up Cap. Cost", 1, 'Incorrect Rolled Up Capacity Cost.');
                    Assert.AreNearlyEqual(
                      RolledUpCapOvhd, StdCostWorksheet."New Rolled-up Cap. Ovhd Cost", 1, 'Incorrect Rolled Up Cap. Overhead.');
                    Assert.AreNearlyEqual(
                      StdCostWorksheet."New Standard Cost",
                      RolledUpMaterialCost + RolledUpCapacityCost + RolledUpCapOvhd + StdCostWorksheet."New Rolled-up Mfg. Ovhd Cost", 1,
                      'Incorrect Mfg. Ovhd.');
                    Assert.AreNearlyEqual(
                      StdCostWorksheet."New Standard Cost",
                      SglLevelMaterialCost + SglLevelCapCost + SglLevelCapOvhd + StdCostWorksheet."New Single-Lvl Mfg. Ovhd Cost", 1,
                      'Incorrect sgl. lvl. Mfg. Ovhd.');
                end;
            StdCostWorksheet.Type::Resource:
                begin
                    Resource.Get(StdCostWorksheet."No.");
                    StdCostWorksheet.TestField("Standard Cost", Resource."Unit Cost");
                    StdCostWorksheet.TestField("Indirect Cost %", Resource."Indirect Cost %");
                    StdCostWorksheet.TestField("Overhead Rate", 0);

                    Assert.AreNearlyEqual(
                      GetRoundedAmount(StdCostWorksheet."Standard Cost" * GLBStandardCostAdj, RndMethodCode),
                      StdCostWorksheet."New Standard Cost", LibraryERM.GetAmountRoundingPrecision(),
                      'Unit cost Adj factor:' + Format(GLBStandardCostAdj));
                    Assert.AreNearlyEqual(
                      GetRoundedAmount(StdCostWorksheet."Indirect Cost %" * GLBIndirectCostAdj, RndMethodCode),
                      StdCostWorksheet."New Indirect Cost %", LibraryERM.GetAmountRoundingPrecision(),
                      'Ind. cost Adj factor:' + Format(GLBIndirectCostAdj));
                    Assert.AreNearlyEqual(0, StdCostWorksheet."New Overhead Rate", LibraryERM.GetAmountRoundingPrecision(), '');
                end;
        end;
    end;

    local procedure VerifyRevalJnlLine(ItemNo: Code[20])
    var
        StdCostWorksheet: Record "Standard Cost Worksheet";
        ItemJournalLine: Record "Item Journal Line";
        RevalJnlTemplateName: Code[20];
        RevalJnlBatchName: Code[20];
    begin
        StdCostWorksheet.SetRange(Type, StdCostWorksheet.Type::Item);
        StdCostWorksheet.SetRange("No.", ItemNo);
        if StdCostWorksheet.FindFirst() then begin
            GetRevalJournalNames(RevalJnlTemplateName, RevalJnlBatchName);
            ItemJournalLine.SetRange("Journal Template Name", RevalJnlTemplateName);
            ItemJournalLine.SetRange("Journal Batch Name", RevalJnlBatchName);
            ItemJournalLine.SetRange("Item No.", ItemNo);
            ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
            ItemJournalLine.SetRange("Source Code", SourceCodeSetup."Revaluation Journal");
            Assert.AreEqual(1, ItemJournalLine.Count, 'Filters:' + ItemJournalLine.GetFilters);
            ItemJournalLine.FindFirst();
            Assert.AreNearlyEqual(
              StdCostWorksheet."Standard Cost", ItemJournalLine."Unit Cost (Calculated)", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ERRWrongCost, ItemJournalLine.FieldCaption("Unit Cost (Calculated)")));
            Assert.AreNearlyEqual(
              StdCostWorksheet."New Standard Cost", ItemJournalLine."Unit Cost (Revalued)", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ERRWrongCost, ItemJournalLine.FieldCaption("Unit Cost (Revalued)")));
            Assert.AreNearlyEqual(
              StdCostWorksheet."New Standard Cost" * ItemJournalLine."Quantity (Base)", ItemJournalLine."Inventory Value (Revalued)",
              LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ERRWrongCost, ItemJournalLine.FieldCaption("Inventory Value (Revalued)")));
        end;
    end;

    local procedure VerifyCard(Type: Enum "BOM Component Type"; No: Code[20])
    var
        StdCostWorksheet: Record "Standard Cost Worksheet";
        Item: Record Item;
        Resource: Record Resource;
    begin
        StdCostWorksheet.SetRange("No.", No);
        case Type of
            BOMComponent.Type::Item:
                begin
                    StdCostWorksheet.SetRange(Type, StdCostWorksheet.Type::Item);
                    Item.Get(No);
                    if StdCostWorksheet.FindFirst() then begin
                        Item.TestField("Standard Cost", StdCostWorksheet."New Standard Cost");
                        Item.TestField("Indirect Cost %", StdCostWorksheet."New Indirect Cost %");
                        Item.TestField("Overhead Rate", StdCostWorksheet."New Overhead Rate");
                        Item.TestField("Single-Level Material Cost", StdCostWorksheet."New Single-Lvl Material Cost");
                        Item.TestField("Single-Level Capacity Cost", StdCostWorksheet."New Single-Lvl Cap. Cost");
                        Item.TestField("Single-Level Subcontrd. Cost", StdCostWorksheet."New Single-Lvl Subcontrd Cost");
                        Item.TestField("Single-Level Cap. Ovhd Cost", StdCostWorksheet."New Single-Lvl Cap. Ovhd Cost");
                        Item.TestField("Single-Level Mfg. Ovhd Cost", StdCostWorksheet."New Single-Lvl Mfg. Ovhd Cost");
                        Item.TestField("Rolled-up Material Cost", StdCostWorksheet."New Rolled-up Material Cost");
                        Item.TestField("Rolled-up Capacity Cost", StdCostWorksheet."New Rolled-up Cap. Cost");
                        Item.TestField("Rolled-up Subcontracted Cost", StdCostWorksheet."New Rolled-up Subcontrd Cost");
                        Item.TestField("Rolled-up Mfg. Ovhd Cost", StdCostWorksheet."New Rolled-up Mfg. Ovhd Cost");
                        Item.TestField("Rolled-up Cap. Overhead Cost", StdCostWorksheet."New Rolled-up Cap. Ovhd Cost");
                    end;
                end;
            BOMComponent.Type::Resource:
                begin
                    StdCostWorksheet.SetRange(Type, StdCostWorksheet.Type::Resource);
                    Resource.Get(No);
                    if StdCostWorksheet.FindFirst() then begin
                        Resource.TestField("Unit Cost", StdCostWorksheet."New Standard Cost");
                        Resource.TestField("Indirect Cost %", StdCostWorksheet."New Indirect Cost %");
                    end;
                end;
        end;
    end;

    local procedure AddItemInventory(ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          LibraryRandom.RandInt(25));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure AddOverhead(var TempItem: Record Item temporary; var TempResource: Record Resource temporary)
    var
        Resource: Record Resource;
    begin
        if TempItem.FindSet() then
            repeat
                LibraryAssembly.ModifyItem(TempItem."No.", true, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
            until TempItem.Next() = 0;

        if TempResource.FindSet() then
            repeat
                Resource.Get(TempResource."No.");
                Resource.Validate("Indirect Cost %", LibraryRandom.RandInt(5));
                Resource.Modify(true);
            until TempResource.Next() = 0;
    end;

    local procedure GetTree(var TempItem: Record Item temporary; var TempResource: Record Resource temporary; var RolledUpMaterialCost: Decimal; var RolledUpCapacityCost: Decimal; var RolledUpCapOvhd: Decimal; var SglLevelMaterialCost: Decimal; var SglLevelCapCost: Decimal; var SglLevelCapOvhd: Decimal; Item: Record Item): Decimal
    var
        BOMComponent: Record "BOM Component";
        ProdBOMLine: Record "Production BOM Line";
        Item1: Record Item;
        Resource: Record Resource;
        LotSize: Decimal;
        Overhead: Decimal;
        IndirectCost: Decimal;
        TreeCost: Decimal;
        UnitCost: Decimal;
        LocalRolledUpMaterialCost: Decimal;
        LocalRolledUpCapCost: Decimal;
        LocalRolledUpCapOvhd: Decimal;
        LocalCost: Decimal;
        RoundingPrecision: Decimal;
    begin
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    BOMComponent.SetRange("Parent Item No.", Item."No.");
                    BOMComponent.SetRange(Type, BOMComponent.Type::Item);
                    if BOMComponent.FindSet() then
                        repeat
                            Item1.Get(BOMComponent."No.");
                            LocalRolledUpMaterialCost := 0;
                            LocalRolledUpCapCost := 0;
                            LocalRolledUpCapOvhd := 0;
                            LocalCost := 0;
                            TreeCost +=
                              BOMComponent."Quantity per" *
                              GetTree(
                                TempItem, TempResource, LocalRolledUpMaterialCost, LocalRolledUpCapCost, LocalRolledUpCapOvhd, LocalCost, LocalCost,
                                LocalCost, Item1);
                            SglLevelMaterialCost +=
                              BOMComponent."Quantity per" * (LocalRolledUpMaterialCost + LocalRolledUpCapCost + LocalRolledUpCapOvhd);
                            RolledUpMaterialCost += BOMComponent."Quantity per" * LocalRolledUpMaterialCost;
                            RolledUpCapacityCost += BOMComponent."Quantity per" * LocalRolledUpCapCost;
                            RolledUpCapOvhd += BOMComponent."Quantity per" * LocalRolledUpCapOvhd;
                        until BOMComponent.Next() = 0;

                    BOMComponent.SetRange(Type, BOMComponent.Type::Resource);
                    if BOMComponent.FindSet() then
                        repeat
                            Resource.Get(BOMComponent."No.");
                            TempResource := Resource;
                            TempResource.Insert();

                            if (BOMComponent."Resource Usage Type" = BOMComponent."Resource Usage Type"::Fixed) and (Item."Lot Size" <> 0) then
                                LotSize := Item."Lot Size"
                            else
                                LotSize := 1;

                            GetCostInformation(BOMComponent.Type::Resource, BOMComponent."No.", UnitCost, Overhead, IndirectCost);
                            TreeCost += BOMComponent."Quantity per" * UnitCost / LotSize;
                            SglLevelCapCost += BOMComponent."Quantity per" * (UnitCost - Overhead) / LotSize;
                            SglLevelCapOvhd += BOMComponent."Quantity per" * Overhead / LotSize;
                            RolledUpCapacityCost += BOMComponent."Quantity per" * (UnitCost - Overhead) / LotSize;
                            RolledUpCapOvhd += BOMComponent."Quantity per" * Overhead / LotSize;

                        until BOMComponent.Next() = 0;
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    ProdBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
                    ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
                    if ProdBOMLine.FindSet() then
                        repeat
                            Item1.Get(ProdBOMLine."No.");
                            LocalRolledUpMaterialCost := 0;
                            LocalRolledUpCapCost := 0;
                            LocalRolledUpCapOvhd := 0;
                            LocalCost := 0;
                            TreeCost +=
                              ProdBOMLine."Quantity per" *
                              GetTree(
                                TempItem, TempResource, LocalRolledUpMaterialCost, LocalRolledUpCapCost, LocalRolledUpCapOvhd, LocalCost, LocalCost,
                                LocalCost, Item1);
                            SglLevelMaterialCost +=
                              ProdBOMLine."Quantity per" * (LocalRolledUpMaterialCost + LocalRolledUpCapCost + LocalRolledUpCapOvhd);
                            RolledUpMaterialCost += ProdBOMLine."Quantity per" * LocalRolledUpMaterialCost;
                            RolledUpCapacityCost += ProdBOMLine."Quantity per" * LocalRolledUpCapCost;
                            RolledUpCapOvhd += ProdBOMLine."Quantity per" * LocalRolledUpCapOvhd;
                        until ProdBOMLine.Next() = 0;
                end;
            Item."Replenishment System"::Purchase:
                begin
                    TempItem := Item;
                    TempItem.Insert();
                    GetCostInformation(BOMComponent.Type::Item, Item."No.", UnitCost, Overhead, IndirectCost);
                    SglLevelMaterialCost := UnitCost;
                    RolledUpMaterialCost := UnitCost;
                    exit(UnitCost);
                end;
        end;

        RoundingPrecision := LibraryERM.GetUnitAmountRoundingPrecision();
        RolledUpMaterialCost := Round(RolledUpMaterialCost, RoundingPrecision);
        RolledUpCapacityCost := Round(RolledUpCapacityCost, RoundingPrecision);
        RolledUpCapOvhd := Round(RolledUpCapOvhd, RoundingPrecision);
        SglLevelMaterialCost := Round(SglLevelMaterialCost, RoundingPrecision);
        SglLevelCapCost := Round(SglLevelCapCost, RoundingPrecision);
        SglLevelCapOvhd := Round(SglLevelCapOvhd, RoundingPrecision);

        exit(Round(TreeCost * (1 + Item."Indirect Cost %" / 100) + Item."Overhead Rate", RoundingPrecision));
    end;

    local procedure GetCostInformation(Type: Enum "BOM Component Type"; No: Code[20]; var UnitCost: Decimal; var Overhead: Decimal; var IndirectCost: Decimal)
    begin
        LibraryAssembly.GetCostInformation(UnitCost, Overhead, IndirectCost, Type, No, '', '');
        if ((No = GLBDirectResourceNo) and (Type = BOMComponent.Type::Resource)) or
           ((No = GLBCompItemNo) and (Type = BOMComponent.Type::Item))
        then begin
            UnitCost := GetRoundedAmount(UnitCost * GLBStandardCostAdj, GLBRoundingMethod);
            IndirectCost := GetRoundedAmount(IndirectCost * GLBIndirectCostAdj, GLBRoundingMethod);

            if Type = BOMComponent.Type::Resource then
                Overhead := UnitCost * IndirectCost / (100 + IndirectCost)
            else
                Overhead := GetRoundedAmount(Overhead * GLBOverheadRateAdj, GLBRoundingMethod);
        end;
    end;

    local procedure GetRevalJournalNames(var RevalJournalTemplateName: Code[20]; var RevalJournalBatchName: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Revaluation);
        ItemJournalTemplate.SetRange(Recurring, false);
        if ItemJournalTemplate.FindFirst() then begin
            ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
            if ItemJournalBatch.FindFirst() then
                RevalJournalBatchName := ItemJournalBatch.Name;
            RevalJournalTemplateName := ItemJournalTemplate.Name;
        end;
    end;

    local procedure GetRoundedAmount(Amount: Decimal; RoundingMethodCode: Code[10]): Decimal
    var
        RoundingMethod: Record "Rounding Method";
    begin
        if RoundingMethod.Get(RoundingMethodCode) then
            Amount := Round(Abs(Amount), RoundingMethod.Precision, CopyStr('=><', RoundingMethod.Type + 1, 1));
        exit(Amount);
    end;

    local procedure SetGlobalParameters(var TempItem: Record Item temporary; var TempResource: Record Resource temporary; ParentItemNo: Code[20])
    var
        RoundingMethod: Record "Rounding Method";
    begin
        GLBStandardCostAdj := LibraryRandom.RandIntInRange(2, 5);
        GLBIndirectCostAdj := LibraryRandom.RandIntInRange(2, 5);
        GLBOverheadRateAdj := LibraryRandom.RandIntInRange(2, 5);
        GLBParentItemNo := ParentItemNo;
        if RoundingMethod.FindFirst() then
            GLBRoundingMethod := RoundingMethod.Code;

        TempItem.Next(LibraryRandom.RandInt(TempItem.Count));
        GLBCompItemNo := TempItem."No.";

        TempResource.Next(LibraryRandom.RandInt(TempResource.Count));
        GLBDirectResourceNo := TempResource."No.";
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestItemStdCostHandler(var SuggestItemStandardCost: TestRequestPage "Suggest Item Standard Cost")
    begin
        SuggestItemStandardCost."AmtAdjustFactor[1]".SetValue(GLBStandardCostAdj);
        SuggestItemStandardCost."AmtAdjustFactor[2]".SetValue(GLBIndirectCostAdj);
        SuggestItemStandardCost."AmtAdjustFactor[3]".SetValue(GLBOverheadRateAdj);
        SuggestItemStandardCost."RoundingMethod[1]".SetValue(GLBRoundingMethod);
        SuggestItemStandardCost."RoundingMethod[2]".SetValue(GLBRoundingMethod);
        SuggestItemStandardCost."RoundingMethod[3]".SetValue(GLBRoundingMethod);

        SuggestItemStandardCost.Item.SetFilter("No.", GLBCompItemNo);
        SuggestItemStandardCost.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestWorkMachCtrResStdCostHandler(var SuggestWorkMachCtrResStdCost: TestRequestPage "Suggest Capacity Standard Cost")
    begin
        SuggestWorkMachCtrResStdCost."AmtAdjustFactor[1]".SetValue(GLBStandardCostAdj);
        SuggestWorkMachCtrResStdCost."AmtAdjustFactor[2]".SetValue(GLBIndirectCostAdj);
        SuggestWorkMachCtrResStdCost."AmtAdjustFactor[3]".SetValue(GLBOverheadRateAdj);
        SuggestWorkMachCtrResStdCost."RoundingMethod[1]".SetValue(GLBRoundingMethod);
        SuggestWorkMachCtrResStdCost."RoundingMethod[2]".SetValue(GLBRoundingMethod);
        SuggestWorkMachCtrResStdCost."RoundingMethod[3]".SetValue(GLBRoundingMethod);

        SuggestWorkMachCtrResStdCost."Work Center".SetFilter("No.", '-');
        SuggestWorkMachCtrResStdCost."Machine Center".SetFilter("No.", '-');
        SuggestWorkMachCtrResStdCost.Resource.SetFilter("No.", GLBDirectResourceNo);
        SuggestWorkMachCtrResStdCost.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RollupStdCostHandler(var RollUpStandardCost: TestRequestPage "Roll Up Standard Cost")
    begin
        RollUpStandardCost.CalculationDate.SetValue(WorkDate());
        RollUpStandardCost.Item.SetFilter("No.", GLBParentItemNo);
        RollUpStandardCost.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImplementStdCostHandler(var ImplementStdCostChange: TestRequestPage "Implement Standard Cost Change")
    var
        RevalJnlTemplateName: Code[20];
        RevalJnlBatchName: Code[20];
    begin
        ImplementStdCostChange.PostingDate.SetValue(WorkDate());
        ImplementStdCostChange.DocumentNo.SetValue(GLBParentItemNo);
        GetRevalJournalNames(RevalJnlTemplateName, RevalJnlBatchName);
        ImplementStdCostChange.ItemJournalTemplate.SetValue(RevalJnlTemplateName);
        ImplementStdCostChange.ItemJournalBatchName.SetValue(RevalJnlBatchName);
        if Format(ImplementStdCostChange.DocumentNo) = '' then
            ImplementStdCostChange.DocumentNo.SetValue(GLBParentItemNo);
        ImplementStdCostChange."Standard Cost Worksheet".SetFilter(Type, '');
        ImplementStdCostChange."Standard Cost Worksheet".SetFilter(
          "No.", GLBParentItemNo + '|' + GLBCompItemNo + '|' + GLBDirectResourceNo);
        ImplementStdCostChange.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StdCostMsgHandler(Message: Text)
    begin
    end;
}

