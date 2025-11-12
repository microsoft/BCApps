// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Utilities;
using System.Environment.Configuration;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.BOM;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Assembly.History;
using Microsoft.Inventory.Costing;
using Microsoft.Assembly.Posting;

codeunit 137092 "SCM Kitting - D3 - Part 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
    end;

    var
        AssemblySetup: Record "Assembly Setup";
        InventorySetup: Record "Inventory Setup";
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        LibraryERM: Codeunit "Library - ERM";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory to GL";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPlanning: Codeunit "Library - Planning";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards",Usage;
        BlockType: Option Dimension,"Dimension Value","Dimension Combination","None";
        PostingDateErr: Label 'Posting Date is not within your range of allowed posting dates. in Assembly Header Document Type=''Order'',No.=''%1''.';
        ClearType: Option "Posting Group","Location Posting Setup","Posting Group Setup";
        ItemPostGrErr: Label 'Inventory Posting Group must have a value in Item: No.=%1. It cannot be zero or empty.';
        ResPostGrErr: Label 'Gen. Prod. Posting Group must have a value in Resource: No.=%1. It cannot be zero or empty.';
        AsmItemPostingErr: Label 'Gen. Prod. Posting Group must have a value in Item Journal Line: Journal Template Name=, Journal Batch Name=, Line No.=0. It cannot be zero or empty.';
        isInitialized: Boolean;
        AvailCheckErr: Label 'You have insufficient quantity of Item %1 on inventory.';
        GlobalMaterialCost: Decimal;
        GlobalResourceCost: Decimal;
        GlobalResourceOvhd: Decimal;
        GlobalPartialPostFactor: Decimal;
        GlobalAsmOvhd: Decimal;
        GlobalPostedAsmStatValue: array[5, 5] of Decimal;
        WorkDate2: Date;
        MsgUpdateDim: Label 'Do you want to update the Dimensions on the lines?';
        ErrorSelectDimValue: Label 'The Dimension Value Code must be';
        ErrorInvalidDimensions: Label 'The dimensions that are used in Order ';
        NoSeriesErr: Label 'You have insufficient quantity of Item';
        NothingToPostTxt: Label 'There is nothing to post to the general ledger.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        UpdateDimensionOnLine: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - D3 - Part 1");
        // Initialize setup.
        ClearLastError();
        LibrarySetupStorage.Restore();
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '',
          AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card", LibraryUtility.GetGlobalNoSeriesCode());
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - D3 - Part 1");

        // Setup Demonstration data.
        isInitialized := true;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        WorkDate2 := LibraryPlanning.SetSafetyWorkDate(); // to avoid Due Date Before Work Date message.
        LibraryCosting.AdjustCostItemEntries('', '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate2, '');
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - D3 - Part 1");
    end;

    [Normal]
    local procedure DimensionPosting(DimensionsFrom: Option; OverrideDimensions: Boolean; HeaderBlockType: Option; CompBlockType: Option; DefaultHeaderValuePosting: Enum "Default Dimension Value Posting Type"; DefaultCompValuePosting: Enum "Default Dimension Value Posting Type")
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ExpectedError: Text[1024];
    begin
        // Setup.
        Initialize();
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', DimensionsFrom, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, '', true);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        // Exercise.
        LibraryAssembly.CheckOrderDimensions(AssemblyHeader, DimensionsFrom);
        if OverrideDimensions then
            LibraryAssembly.EditOrderDimensions(AssemblyHeader);
        ExpectedError := LibraryAssembly.BlockOrderDimensions(AssemblyHeader, HeaderBlockType, CompBlockType);

        if ExpectedError = '' then
            ExpectedError := AddAOItemDimension(AssemblyHeader, DefaultHeaderValuePosting, DefaultCompValuePosting);

        SetShortcutDimensions(AssemblyHeader, 1);
        SetShortcutDimensions(AssemblyHeader, 2);

        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ExpectedError);

        // Verify.
        if ExpectedError = '' then begin
            LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
            LibraryAssembly.VerifyPostedComments(AssemblyHeader);
            LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
            LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
            LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
            LibraryAssembly.VerifyCapEntries(TempAssemblyLine, AssemblyHeader);
            LibraryAssembly.VerifyItemRegister(AssemblyHeader);
        end;

        // Tear down.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange,NothingPostedMessageHandler')]
    [Scope('OnPrem')]
    procedure BlockHeaderDim()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension is blocked for header Item.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", false, BlockType::Dimension, BlockType::None,
          DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure BlockCompDim()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension is blocked for component Items.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card", false, BlockType::None, BlockType::Dimension,
          DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure BlockAllDim()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO]  Verify an error when posting Assembly Order, if Dimension is blocked for header and component Items.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", false, BlockType::Dimension, BlockType::Dimension,
          DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure BlockHeaderDimVal()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension Value is blocked for header Item.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", false, BlockType::"Dimension Value", BlockType::None,
          DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure BlockCompDimComb()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension Combination is blocked for component Items.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card", false, BlockType::None,
          BlockType::"Dimension Combination", DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure BlockHeaderDimComb()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension Combination is blocked for header Item.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card", false, BlockType::"Dimension Combination",
          BlockType::None, DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure BlockAllCombined1()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension is blocked for header Item and Dimension Value is blocked for component Items.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", false, BlockType::Dimension, BlockType::"Dimension Value",
          DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure BlockAllCombined2()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension Value is blocked for header Item and Dimension Combination is blocked for component Items.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", false, BlockType::"Dimension Value",
          BlockType::"Dimension Combination", DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure HeaderDimOverride()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify posted entries of Assembly Order, if Dimension Values are overrided in Assembly Order.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", true, BlockType::None, BlockType::None,
          DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure HeaderDimIncorrectValue()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension Value is restricted by Code for header Item and is incorrect in Assembly Order.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", false, BlockType::None, BlockType::None,
          DefaultDimension."Value Posting"::"Same Code", DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange')]
    [Scope('OnPrem')]
    procedure CompDimIncorrectValue()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO] Verify an error when posting Assembly Order, if Dimension Value is restricted by Code for component Items and is incorrect in Assembly Order.

        DimensionPosting(
          AssemblySetup."Copy Component Dimensions from"::"Order Header", false, BlockType::None, BlockType::None,
          DefaultDimension."Value Posting"::" ", DefaultDimension."Value Posting"::"Same Code");
    end;

    [Normal]
    local procedure InvalidPostingDate(DateDelay: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        PostingDate: Date;
    begin
        // Setup.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(CalcDate('<-30D>', WorkDate2), CalcDate('<+30D>', WorkDate2));
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, '', true);

        // Exercise.
        PostingDate := WorkDate2 + DateDelay;
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, PostingDate);

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(PostingDateErr, AssemblyHeader."No."));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BeforePostingAllowed()
    begin
        // [FEATURE] [Posting Date]
        // [SCENARIO] Verify an error when posting Assembly Order before allowed posting date range.

        InvalidPostingDate(-31);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AfterPostingAllowed()
    begin
        // [FEATURE] [Posting Date]
        // [SCENARIO] Verify an error when posting Assembly Order after allowed posting date range.

        InvalidPostingDate(31);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BoundaryPostingAllowed()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // [FEATURE] [Posting Date]
        // [SCENARIO] Verify cuccessful posting of Assembly Order inside allowed posting date range.

        // Setup.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(CalcDate('<-30D>', WorkDate2), CalcDate('<+30D>', WorkDate2));
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, '', true);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, CalcDate('<+30D>', WorkDate2));

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure MissingHeaderPostingGroups(HeaderClearType: Option)
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Location: Record Location;
        ExpectedError: Text[1024];
    begin
        // Setup.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, Location.Code, AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode());
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, Location.Code, true);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);
        ExpectedError :=
          LibraryAssembly.ClearOrderPostingSetup(HeaderClearType, AssemblyHeader."Inventory Posting Group",
            AssemblyHeader."Gen. Prod. Posting Group", AssemblyHeader."Location Code");

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ExpectedError);

        // Tear down.
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode());
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderLocationPostingSetup()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if appropriate Inventory Posting Setup does not exist within header Location and Inventory Posting Group.

        MissingHeaderPostingGroups(ClearType::"Location Posting Setup");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderPostingGrSetup()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if appropriate General Posting Setup does not exist within header Item.

        MissingHeaderPostingGroups(ClearType::"Posting Group Setup");
    end;

    [Normal]
    local procedure MissingCompPostingGrSetup(CompClearType: Option; CompType: Enum "BOM Component Type")
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        Location: Record Location;
        ExpectedError: Text[1024];
    begin
        // Setup.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, Location.Code, AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode());
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, Location.Code, true);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, CompType);
        if AssemblyLine.FindFirst() then
            ExpectedError :=
              LibraryAssembly.ClearOrderPostingSetup(CompClearType, AssemblyLine."Inventory Posting Group",
                AssemblyLine."Gen. Prod. Posting Group", AssemblyLine."Location Code");

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ExpectedError);

        // Tear down.
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode());
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompLocationPostingSetup()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if appropriate Inventory Posting Setup does not exist within component Location and Inventory Posting Group.

        MissingCompPostingGrSetup(ClearType::"Location Posting Setup", "BOM Component Type"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompPostingGroupSetup()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if appropriate General Posting Setup does not exist within component Item.

        MissingCompPostingGrSetup(ClearType::"Posting Group Setup", "BOM Component Type"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingHeaderItemPostingGroups()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if header Item does not have Gen. Prod. Posting Group.

        // Setup.
        Initialize();
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, '', true);
        Item.Get(AssemblyHeader."Item No.");
        Item.Validate("Inventory Posting Group", '');
        Item.Validate("Gen. Prod. Posting Group", '');
        Item.Modify(true);
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", '', 1, '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, AsmItemPostingErr);

        // Tear down.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure MissingCompPostingGroups(Type: Enum "BOM Component Type")
    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ExpectedError: Text[1024];
    begin
        // Setup.
        Initialize();
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, '', true);

        case Type of
            "BOM Component Type"::Item:
                begin
                    LibraryInventory.CreateItem(Item);
                    Item.Validate("Inventory Posting Group", '');
                    Item.Modify(true);
                    ExpectedError := StrSubstNo(ItemPostGrErr, Item."No.");
                    // Exercise.
                    asserterror
                      LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, Type, Item."No.",
                        LibraryAssembly.GetUnitOfMeasureCode(Type, Item."No.", true), 1, 0, '');
                    // Verify.
                    Assert.AreEqual(ExpectedError, GetLastErrorText, '');
                    ClearLastError();
                end;
            "BOM Component Type"::Resource:
                begin
                    LibraryAssembly.CreateResource(Resource, true, '');
                    Resource.Validate("Gen. Prod. Posting Group", '');
                    Resource.Modify(true);
                    ExpectedError := StrSubstNo(ResPostGrErr, Resource."No.");
                    // Exercise.
                    asserterror
                      LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, Type, Resource."No.",
                        LibraryAssembly.GetUnitOfMeasureCode(Type, Resource."No.", true), 1, 0, '');
                    // Verify.
                    Assert.AreEqual(ExpectedError, GetLastErrorText, '');
                    ClearLastError();
                end;
        end;
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingItemPostingGroups()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if component Item does not have Gen. Prod. Posting Group.

        MissingCompPostingGroups("BOM Component Type"::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingResourcePostingGroups()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if component Resource does not have Gen. Prod. Posting Group.

        MissingCompPostingGroups("BOM Component Type"::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingPostedDocNoSeries()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error when posting Assembly Order if Assembly Setup does not have "No. Series" for posted Assemblies.

        // Setup.
        Initialize();
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode());
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, '', true);

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(NoSeriesErr));

        // Tear down.
        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Order Header",
          LibraryUtility.GetGlobalNoSeriesCode());
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure SetShortcutDimensions(AssemblyHeader: Record "Assembly Header"; Num: Integer)
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ShortcutDimensionCode: Code[20];
        DimensionSetID: Integer;
    begin
        GeneralLedgerSetup.Get();
        if Num = 1 then
            ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 1 Code"
        else
            ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 2 Code";

        DimensionSetID := AssemblyHeader."Dimension Set ID";
        LibraryDimension.FindDimensionValue(DimensionValue, ShortcutDimensionCode);
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, ShortcutDimensionCode, DimensionValue.Code);
        AssemblyHeader.Validate("Dimension Set ID", DimensionSetID);
        AssemblyHeader.Modify(true);

        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, AssemblyHeader."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        DimensionSetEntry.FindFirst();

        if Num = 1 then
            AssemblyHeader.Validate(
              "Shortcut Dimension 1 Code",
              LibraryDimension.FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"))
        else
            AssemblyHeader.Validate(
              "Shortcut Dimension 2 Code",
              LibraryDimension.FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        AssemblyHeader.Modify(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailabilityCheck()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ItemNo: array[10] of Code[20];
        ResourceNo: array[10] of Code[20];
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error on Assembly Order posting if insufficient Quantity of components on stock.

        // Setup.
        Initialize();
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Average,
          Item."Replenishment System"::Assembly, '', true);
        LibraryAssembly.GetCompsToAdjust(ItemNo, ResourceNo, AssemblyHeader);

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, StrSubstNo(AvailCheckErr, ItemNo[1]));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure ModifyAssemblyLines(ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards",Usage; CostingMethod: Enum "Costing Method"; ComponentType: Enum "BOM Component Type"; NewComponentType: Enum "BOM Component Type"; UseBaseUnitOfMeasure: Boolean; UpdateUnitCost: Boolean; HeaderAdjustFactor: Decimal)
    var
        Item: Record Item;
        Resource: Record Resource;
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        NewComponentNo: Code[20];
    begin
        // Setup.
        Initialize();
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, CostingMethod, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', UpdateUnitCost);
        if NewComponentType = "BOM Component Type"::Item then
            NewComponentNo := LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase,
                AssemblyHeader."Gen. Prod. Posting Group", AssemblyHeader."Inventory Posting Group")
        else
            NewComponentNo := LibraryAssembly.CreateResource(Resource, true, AssemblyHeader."Gen. Prod. Posting Group");
        LibraryAssembly.EditAssemblyLines(ChangeType, ComponentType, NewComponentType, NewComponentNo,
          AssemblyHeader."No.", UseBaseUnitOfMeasure);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);
        if UpdateUnitCost then
            LibraryAssembly.UpdateOrderCost(AssemblyHeader);

        // Exercise.
        AssemblyHeader.Validate(Quantity, AssemblyHeader.Quantity * HeaderAdjustFactor);
        if CostingMethod <> Item."Costing Method"::Standard then
            AssemblyHeader.Validate("Unit Cost", AssemblyHeader."Unit Cost" * (1 + HeaderAdjustFactor));
        AssemblyHeader.Modify(true);
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyPostedComments(AssemblyHeader);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssemblyHeader."Quantity to Assemble");
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyCapEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);

        // Tear down.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemQtyPer()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Qty on Items changed and Unit Cost updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Edit, Item."Costing Method"::Average, "BOM Component Type"::Item, "BOM Component Type"::Item, true, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResQtyPer()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Qty on Resources changed.

        ModifyAssemblyLines(
          ChangeType::Edit, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true, false,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasure()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Qty on Items changed but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Edit, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, false, false, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceItemWItem()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Items changed and Unit Cost is updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Replace, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, true, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceItemWRes()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Items changed to Resources but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Replace, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Resource, true, false,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddItem()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Item added and Unit Cost cannot be updated in Assembly Order (Costing Method: Standard).

        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true, true, 1);
    end;

    [Normal]
    local procedure AddItemDimension(ItemNo: Code[20]; DefaultValuePosting: Enum "Default Dimension Value Posting Type"): Text[1024]
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        if DefaultValuePosting <> DefaultDimension."Value Posting"::" " then begin
            LibraryDimension.FindDefaultDimension(DefaultDimension, 27, ItemNo);
            DefaultDimension.Next(DefaultDimension.Count);

            LibraryDimension.CreateDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
            DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
            DefaultDimension.Validate("Value Posting", DefaultValuePosting);
            DefaultDimension.Modify(true);

            exit(ErrorInvalidDimensions);
        end;

        exit('');
    end;

    [Normal]
    local procedure AddAOItemDimension(AssemblyHeader: Record "Assembly Header"; DefaultHeaderValuePosting: Enum "Default Dimension Value Posting Type"; DefaultCompValuePosting: Enum "Default Dimension Value Posting Type") ExpectedError: Text[1024]
    begin
        ExpectedError := AddItemDimension(AssemblyHeader."Item No.", DefaultHeaderValuePosting);

        if ExpectedError = '' then begin
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
            AssemblyLine.SetRange(Type, "BOM Component Type"::Item);
            AssemblyLine.FindLast();
            ExpectedError := AddItemDimension(AssemblyLine."No.", DefaultCompValuePosting);
            if ExpectedError <> '' then
                ExpectedError := ErrorSelectDimValue;
        end;

        exit(ExpectedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddDirectRes()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Resource added (), but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, true, false,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddFixedRes()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Resource added (), but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, false,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItem()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Item deleted but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Delete, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, false, false,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRes()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Resource deleted but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Delete, Item."Costing Method"::FIFO, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, false,
          1);
    end;

    [Normal]
    local procedure DeleteAllUpdHeader(HeaderAdjFactor: Decimal)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        // Setup.
        Initialize();
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', true);

        // Exercise.
        LibraryAssembly.EditAssemblyLines(
          ChangeType::"Delete all", "BOM Component Type"::Item, "BOM Component Type"::Item, '', AssemblyHeader."No.", false);
        AssemblyHeader.Validate(Quantity, AssemblyHeader.Quantity * HeaderAdjFactor);
        AssemblyHeader.Modify(true);

        // Verify.
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, DocumentErrorsMgt.GetNothingToPostErrorMsg());
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAll()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error on posting Assembly Header, if components are empty and header Quantity is not zero.

        DeleteAllUpdHeader(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAllSetQtyToZero()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify an error on posting Assembly Header, if components are empty and header Quantity is zero.

        DeleteAllUpdHeader(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Usage()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Resource usage is changed (Direct <-> Fixed), but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Usage, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, false,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceItemWItemUpdCost()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Item is replaced and Unit Cost is updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Replace, Item."Costing Method"::FIFO, "BOM Component Type"::Item, "BOM Component Type"::Item, true, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddItemUpdCost()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Item added and Unit Cost cannot be updated in Assembly Order (Costing Method: Standard).

        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Item, "BOM Component Type"::Item, true, true, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddFixedResUpdCost()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Resource added (), and Unit Cost is updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, true,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteResUpdCost()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if components are edited: Resource added (), and Unit Cost is updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Delete, Item."Costing Method"::FIFO, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, true,
          1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderQty()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if header Item Quantity reduced and Unit Cost cannot be updated in Assembly Order (Costing Method: Standard).

        ModifyAssemblyLines(
          ChangeType::" ", Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, true,
          LibraryRandom.RandDec(1, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderQtyLineUpdate()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if header Item Quantity is reduced, Resource added, but Unit Cost is not updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::Add, Item."Costing Method"::Standard, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, false,
          LibraryRandom.RandDec(1, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderUnitCost()
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries of posted Assembly Order, if header Item Quantity and Unit Cost is updated in Assembly Order.

        ModifyAssemblyLines(
          ChangeType::" ", Item."Costing Method"::Average, "BOM Component Type"::Resource, "BOM Component Type"::Resource, false, true,
          LibraryRandom.RandDec(1, 2));
    end;

    [Normal]
    local procedure NormalPosting(ParentCostingMethod: Enum "Costing Method"; CompCostingMethod: Enum "Costing Method"; HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; ExpectedError: Text[1024]; IndirectCost: Decimal; PostWithoutAdj: Boolean): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ItemNo: array[10] of Code[20];
        ResourceNo: array[10] of Code[20];
        ItemFilter: Text[250];
        AssembledQty: Decimal;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant",
          InventorySetup."Average Cost Period"::Day);
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, ParentCostingMethod, CompCostingMethod,
          Item."Replenishment System"::Assembly, '', true);
        ItemFilter := LibraryAssembly.GetCompsToAdjust(ItemNo, ResourceNo, AssemblyHeader);
        LibraryAssembly.ModifyCostParams(AssemblyHeader."No.", false, IndirectCost, 0);
        LibraryAssembly.ModifyItem(AssemblyHeader."Item No.", false, IndirectCost * LibraryRandom.RandDec(10, 2), 0);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, HeaderQtyFactor, PartialPostFactor, true, WorkDate2);
        LibraryAssembly.CalcOrderCostAmount(GlobalMaterialCost, GlobalResourceCost, GlobalResourceOvhd, GlobalAsmOvhd, AssemblyHeader."No.");
        AssembledQty := AssemblyHeader."Quantity to Assemble";

        // Check statistics before posting: post factor is 0.
        GlobalPartialPostFactor := 0;
        CheckStatisticsPage(AssemblyHeader);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, ExpectedError);
        if not PostWithoutAdj then
            LibraryCosting.AdjustCostItemEntries(ItemFilter, '');

        // Verify.
        if ExpectedError = '' then begin
            if PartialPostFactor < 100 then begin
                // Check statistics after partial posting.
                GlobalPartialPostFactor := PartialPostFactor / 100;
                CheckStatisticsPage(AssemblyHeader);
            end;
            LibraryAssembly.VerifyPartialPosting(AssemblyHeader, HeaderQtyFactor);
            LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssembledQty);
            LibraryAssembly.VerifyPostedComments(AssemblyHeader);
            LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssembledQty);
            LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssembledQty);
            LibraryAssembly.VerifyIndirectCostEntries(AssemblyHeader);
            LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
            LibraryAssembly.VerifyCapEntries(TempAssemblyLine, AssemblyHeader);
            LibraryAssembly.VerifyItemRegister(AssemblyHeader);
        end;

        // Tear down.
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        NotificationLifecycleMgt.RecallAllNotifications();

        exit(AssemblyHeader."No.");
    end;

    [Normal]
    local procedure NormalPostGL(ParentCostingMethod: Enum "Costing Method"; CompCostingMethod: Enum "Costing Method"; HeaderQtyFactor: Decimal; PartialPostFactor: Decimal; PerPostingGroup: Boolean; IndirectCost: Decimal; PostWithoutAdj: Boolean)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblyHeaderNo: Code[20];
        DocNo: Code[20];
    begin
        // Setup.
        Initialize();
        AssemblyHeaderNo :=
          NormalPosting(ParentCostingMethod, CompCostingMethod, HeaderQtyFactor, PartialPostFactor, '', IndirectCost, PostWithoutAdj);
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant",
          InventorySetup."Average Cost Period"::Day);

        // Exercise.
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeaderNo);
        PostedAssemblyHeader.FindFirst();
        if PerPostingGroup then
            DocNo := PostedAssemblyHeader."No."
        else
            DocNo := '';
        LibraryPostInventoryToGL.PostInvtCostToGL(PerPostingGroup, PostedAssemblyHeader."Item No.", DocNo,
          TemporaryPath + PostedAssemblyHeader."No." + '.pdf');
        if PostWithoutAdj then
            LibraryCosting.AdjustCostItemEntries(PostedAssemblyHeader."Item No.", '');

        // Verify.
        LibraryAssembly.VerifyGLEntries(PostedAssemblyHeader, PerPostingGroup);

        // Tear down.
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineSTDAVG()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order (Adjust Cost after posting) when parent Item has Costing Method: Standard and child item has Costing Method: Average.

        NormalPosting(Item."Costing Method"::Standard, Item."Costing Method"::Average, 100, 100, '', 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PartialSTDFIFO()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order (partially Assemble and Consume, Adjust Cost after posting) when parent Item has Costing Method: Standard and child item has Costing Method: FIFO.

        NormalPosting(Item."Costing Method"::Standard, Item."Costing Method"::FIFO, 50, 25, '', 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyToAssemble()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify an error on posting Assembly Order (Adjust Cost after posting) when Qty to Assemble = 0.

        NormalPosting(Item."Costing Method"::Standard, Item."Costing Method"::Standard, 0, 100, DocumentErrorsMgt.GetNothingToPostErrorMsg(), 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyOnLines()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify an error on posting Assembly Order (Adjust Cost after posting) when Qty to Consume = 0.

        NormalPosting(Item."Costing Method"::Standard, Item."Costing Method"::Standard, 100, 0, DocumentErrorsMgt.GetNothingToPostErrorMsg(), 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure IndirectCostSTDSTD()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order (Adjust Cost after posting) when parent Item has Costing Method: Standard and child item has Costing Method: Standard, components with Indirect Cost.

        NormalPosting(Item."Costing Method"::Standard, Item."Costing Method"::Standard, 100, 100, '', 10, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineFIFOSTD()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order (Adjust Cost after posting) when parent Item has Costing Method: FIFO and child item has Costing Method: Standard.

        NormalPosting(Item."Costing Method"::FIFO, Item."Costing Method"::Standard, 100, 100, '', 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PartialAVGSTD()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order (partial assembly and consumption, Adjust Cost after posting) when parent Item has Costing Method: Average and child item has Costing Method: Standard.

        NormalPosting(Item."Costing Method"::Average, Item."Costing Method"::Standard, 50, 25, '', 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure IndirectCostFIFOAVG()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order (Adjust Cost after posting) when parent Item has Costing Method: FIFO and child item has Costing Method: Average, components with Indirect Cost.

        NormalPosting(Item."Costing Method"::FIFO, Item."Costing Method"::Average, 100, 100, '', 10, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineAVGFIFO()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Assembly] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order (Adjust Cost after posting) when parent Item has Costing Method: Average and child item has Costing Method: FIFO.

        NormalPosting(Item."Costing Method"::Average, Item."Costing Method"::FIFO, 100, 100, '', 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure SunshineGL()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Assembly] [Posting]
        // [SCENARIO] Verify GL entries on posted Assembly Order when parent Item has Costing Method: Standard and child item has Costing Method: Standard.

        NormalPostGL(Item."Costing Method"::Standard, Item."Costing Method"::Standard, 100, 100, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PartialGL()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Assembly] [Posting]
        // [SCENARIO] Verify GL entries on posted Assembly Order (partial assembly and consumption) when parent Item has Costing Method: Standard and child item has Costing Method: Standard.

        NormalPostGL(Item."Costing Method"::Standard, Item."Costing Method"::Standard, 50, 25, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure IndirectCostGL()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Assembly] [Posting]
        // [SCENARIO] Verify GL entries on posted Assembly Order when parent Item has Costing Method: Standard and child item has Costing Method: Standard, components with Indirect Cost.

        NormalPostGL(Item."Costing Method"::Standard, Item."Costing Method"::Standard, 100, 100, false, 10, false);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostBeforeAdj()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Assembly] [Posting]
        // [SCENARIO] Verify GL entries on posted Assembly Order when parent Item has Costing Method: Standard and child item has Costing Method: Standard, components with Indirect Cost, Adjust Cost AFTER Post to GL.

        NormalPostGL(Item."Costing Method"::Standard, Item."Costing Method"::Standard, 100, 100, false, 10, true);
    end;

    [Test]
    [HandlerFunctions('StatisticsPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PostNoAdjPerPostingGr()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory Cost To GL] [Assembly] [Posting]
        // [SCENARIO] Verify GL entries on posted Assembly Order (Post Inventory to GL method: Per Posting Group) when parent Item has Costing Method: Average and child item has Costing Method: Average.

        NormalPostGL(Item."Costing Method"::Average, Item."Costing Method"::Average, 100, 100, true, 0, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostFromPage()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // [FEATURE] [Posting]
        // [SCENARIO] Verify entries on posted Assembly Order when it is posted via page.

        // Setup.
        Initialize();
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          "Average Cost Calculation Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);
        LibraryAssembly.SetupAssemblyData(AssemblyHeader, WorkDate2, Item."Costing Method"::Standard, Item."Costing Method"::Standard,
          Item."Replenishment System"::Assembly, '', true);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate());
        CODEUNIT.Run(CODEUNIT::"Assembly-Post (Yes/No)", AssemblyHeader);

        // Verify.
        LibraryAssembly.VerifyPartialPosting(AssemblyHeader, 100);
        LibraryAssembly.VerifyPostedAssemblyHeader(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyPostedComments(AssemblyHeader);
        LibraryAssembly.VerifyILEs(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyValueEntries(TempAssemblyLine, AssemblyHeader, AssemblyHeader.Quantity);
        LibraryAssembly.VerifyIndirectCostEntries(AssemblyHeader);
        LibraryAssembly.VerifyResEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyCapEntries(TempAssemblyLine, AssemblyHeader);
        LibraryAssembly.VerifyItemRegister(AssemblyHeader);

        // Tear down.
        LibraryAssembly.UpdateInventorySetup(InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('PostedStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PostedOrderStatistics()
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        // [FEATURE] [Statistics]
        // [SCENARIO] Check that values are correct in Posted Asm. Order Statistics page.

        // Setup.
        InitPostedStatScenario(AssemblyHeader);

        // Exercise.
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // Verify.
        InitRefPostAsmStatisticsData();
        CheckPostedStatisticsPage(AssemblyHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure CheckStatisticsPage(AssemblyHeader: Record "Assembly Header")
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", AssemblyHeader."No.");
        AssemblyOrder.GotoRecord(AssemblyHeader);

        // Open statistics page.
        AssemblyOrder.Action14.Invoke();

        AssemblyOrder.OK().Invoke();
    end;

    [Normal]
    local procedure CheckPostedStatisticsPage(AssemblyHeader: Record "Assembly Header")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        PostedAssemblyOrder: TestPage "Posted Assembly Order";
    begin
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeader."No.");
        PostedAssemblyHeader.FindLast();
        PostedAssemblyOrder.OpenEdit();
        PostedAssemblyOrder.FILTER.SetFilter("No.", PostedAssemblyHeader."No.");
        PostedAssemblyOrder.GotoRecord(PostedAssemblyHeader);

        // Open statistics page.
        PostedAssemblyOrder.Statistics.Invoke();

        PostedAssemblyOrder.OK().Invoke();
    end;

    local procedure InitPostedStatScenario(var AssemblyHeader: Record "Assembly Header")
    var
        Item: Record Item;
        Resource: Record Resource;
        BOMComponent: Record "BOM Component";
        GenProdPostingGr: Code[20];
        AsmInvtPostingGr: Code[20];
        CompInvtPostingGr: Code[20];
        ItemNo: Code[20];
    begin
        Initialize();

        LibraryAssembly.SetupPostingToGL(GenProdPostingGr, AsmInvtPostingGr, CompInvtPostingGr, '');
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 1, 1, 0, 1, GenProdPostingGr, CompInvtPostingGr);

        ItemNo := Item."No.";
        Item.Validate("Unit Cost", 3);
        Item.Validate("Indirect Cost %", 100);
        Item.Validate("Overhead Rate", 5);
        Item.Validate("Single-Level Capacity Cost", 7);
        Item.Validate("Single-Level Cap. Ovhd Cost", 11);
        Item.Modify();

        BOMComponent.SetRange("Parent Item No.", Item."No.");
        if BOMComponent.FindSet() then
            repeat
                case BOMComponent.Type of
                    BOMComponent.Type::Item:
                        begin
                            Item.Get(BOMComponent."No.");
                            Item.Validate("Standard Cost", 13);
                            Item.Validate("Unit Price", 17);
                            Item.Modify(true);
                        end;
                    BOMComponent.Type::Resource:
                        begin
                            Resource.Get(BOMComponent."No.");
                            Resource.Validate("Unit Price", 19);
                            Resource.Validate("Direct Unit Cost", 23);
                            Resource.Validate("Indirect Cost %", 100);
                            Resource.Modify(true);
                        end
                end;
            until BOMComponent.Next() = 0;
        BOMComponent.ModifyAll("Quantity per", 1);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, ItemNo, '', 1, '');
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure InitRefPostAsmStatisticsData()
    var
        ColIdx: Option ,StdCost,ExpCost,ActCost,Dev,"Var";
        RowIdx: Option ,MatCost,ResCost,ResOvhd,AsmOvhd,Total;
    begin
        GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::MatCost] := 3;
        GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::ResCost] := 7;
        GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::ResOvhd] := 11;
        GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::AsmOvhd] := 26;
        GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::Total] := 47;

        GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::MatCost] := 13;
        GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::ResCost] := 23;
        GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::ResOvhd] := 23;
        GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::AsmOvhd] := 64;
        GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::Total] := 123;

        GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::MatCost] := 13;
        GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::ResCost] := 23;
        GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::ResOvhd] := 23;
        GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::AsmOvhd] := 64;
        GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::Total] := 123;

        GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::MatCost] := 333;
        GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::ResCost] := 229;
        GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::ResOvhd] := 109;
        GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::AsmOvhd] := 146;
        GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::Total] := 162;

        GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::MatCost] := 10;
        GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::ResCost] := 16;
        GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::ResOvhd] := 12;
        GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::AsmOvhd] := 38;
        GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::Total] := 76;
    end;

    [Normal]
    local procedure VerifyStatisticsField(ExpectedValue: Decimal; ActualValue: Decimal; ErrorMessage: Text[1024])
    begin
        Assert.AreNearlyEqual(ExpectedValue, ActualValue, LibraryERM.GetAmountRoundingPrecision(), ErrorMessage);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure StatisticsPageHandler(var AssemblyOrderStatistics: TestPage "Assembly Order Statistics")
    begin
        VerifyStatisticsField(
          GlobalMaterialCost,
          AssemblyOrderStatistics.ExpMatCost.AsDecimal(),
          'Wrong Material Cost on Statistics page');

        VerifyStatisticsField(
          GlobalResourceCost,
          AssemblyOrderStatistics.ExpResCost.AsDecimal(),
          'Wrong Resource Cost on Statistics page');

        VerifyStatisticsField(
          GlobalResourceOvhd,
          AssemblyOrderStatistics.ExpResOvhd.AsDecimal(),
          'Wrong Res. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalMaterialCost + GlobalResourceCost + GlobalResourceOvhd + GlobalAsmOvhd,
          AssemblyOrderStatistics.ExpTotalCost.AsDecimal(),
          'Wrong Cost Amount on Statistics page');

        VerifyStatisticsField(
          GlobalMaterialCost * GlobalPartialPostFactor,
          AssemblyOrderStatistics.ActMatCost.AsDecimal(),
          'Wrong Actual Material Cost on Statistics page');

        VerifyStatisticsField(
          GlobalResourceCost * GlobalPartialPostFactor,
          AssemblyOrderStatistics.ActResCost.AsDecimal(),
          'Wrong Actual Resource Cost on Statistics page');

        VerifyStatisticsField(
          GlobalResourceOvhd * GlobalPartialPostFactor,
          AssemblyOrderStatistics.ActResOvhd.AsDecimal(),
          'Wrong Actual Res. Overhead on Statistics page');

        VerifyStatisticsField(
          (GlobalMaterialCost + GlobalResourceCost + GlobalResourceOvhd + GlobalAsmOvhd) * GlobalPartialPostFactor,
          AssemblyOrderStatistics.ActTotalCost.AsDecimal(),
          'Wrong Actual cost amount on Statistics page.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedStatisticsPageHandler(var PostedAsmOrderStatistics: TestPage "Posted Asm. Order Statistics")
    var
        ColIdx: Option ,StdCost,ExpCost,ActCost,Dev,"Var";
        RowIdx: Option ,MatCost,ResCost,ResOvhd,AsmOvhd,Total;
    begin
        // Standard cost
        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::MatCost],
          PostedAsmOrderStatistics.StdMatCost.AsDecimal(),
          'Wrong Standard Material Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::ResCost],
          PostedAsmOrderStatistics.StdResCost.AsDecimal(),
          'Wrong Standard Resource Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::ResOvhd],
          PostedAsmOrderStatistics.StdResOvhd.AsDecimal(),
          'Wrong Standard Res. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::AsmOvhd],
          PostedAsmOrderStatistics.StdAsmOvhd.AsDecimal(),
          'Wrong Standard Asm. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::StdCost, RowIdx::Total],
          PostedAsmOrderStatistics.StdTotalCost.AsDecimal(),
          'Wrong Standard Total Cost Amount on Statistics page');

        // Expected cost
        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::MatCost],
          PostedAsmOrderStatistics.ExpMatCost.AsDecimal(),
          'Wrong Expected Material Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::ResCost],
          PostedAsmOrderStatistics.ExpResCost.AsDecimal(),
          'Wrong Expected Resource Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::ResOvhd],
          PostedAsmOrderStatistics.ExpResOvhd.AsDecimal(),
          'Wrong Expected Res. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::AsmOvhd],
          PostedAsmOrderStatistics.ExpAsmOvhd.AsDecimal(),
          'Wrong Expected Asm. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ExpCost, RowIdx::Total],
          PostedAsmOrderStatistics.ExpTotalCost.AsDecimal(),
          'Wrong Expected Total Cost Amount on Statistics page');

        // Actual cost
        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::MatCost],
          PostedAsmOrderStatistics.ActMatCost.AsDecimal(),
          'Wrong Actual Material Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::ResCost],
          PostedAsmOrderStatistics.ActResCost.AsDecimal(),
          'Wrong Actual Resource Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::ResOvhd],
          PostedAsmOrderStatistics.ActResOvhd.AsDecimal(),
          'Wrong Actual Res. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::AsmOvhd],
          PostedAsmOrderStatistics.ActAsmOvhd.AsDecimal(),
          'Wrong Actual Asm. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::ActCost, RowIdx::Total],
          PostedAsmOrderStatistics.ActTotalCost.AsDecimal(),
          'Wrong Actual Total Cost Amount on Statistics page');

        // Dev. %
        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::MatCost],
          PostedAsmOrderStatistics.DevMatCost.AsDecimal(),
          'Wrong Dev. % Material Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::ResCost],
          PostedAsmOrderStatistics.DevResCost.AsDecimal(),
          'Wrong Dev. % Resource Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::ResOvhd],
          PostedAsmOrderStatistics.DevResOvhd.AsDecimal(),
          'Wrong Dev. % Res. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::AsmOvhd],
          PostedAsmOrderStatistics.DevAsmOvhd.AsDecimal(),
          'Wrong Dev. % Asm. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::Dev, RowIdx::Total],
          PostedAsmOrderStatistics.DevTotalCost.AsDecimal(),
          'Wrong Dev. % Total Cost Amount on Statistics page');

        // Variance
        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::MatCost],
          PostedAsmOrderStatistics.VarMatCost.AsDecimal(),
          'Wrong Variance Material Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::ResCost],
          PostedAsmOrderStatistics.VarResCost.AsDecimal(),
          'Wrong Variance Resource Cost on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::ResOvhd],
          PostedAsmOrderStatistics.VarResOvhd.AsDecimal(),
          'Wrong Variance Res. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::AsmOvhd],
          PostedAsmOrderStatistics.VarAsmOvhd.AsDecimal(),
          'Wrong Variance Asm. Overhead on Statistics page');

        VerifyStatisticsField(
          GlobalPostedAsmStatValue[ColIdx::"Var", RowIdx::Total],
          PostedAsmOrderStatistics.VarTotalCost.AsDecimal(),
          'Wrong Variance Total Cost Amount on Statistics page');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DimensionsChangeConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(MsgUpdateDim, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmUpdateDimensionChange(Question: Text[1024]; var Reply: Boolean)
    begin
        if (Question = MsgUpdateDim) or (Question = UpdateDimensionOnLine) then
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingPostedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToPostTxt, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

