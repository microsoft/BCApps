// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement.TestLibraries;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.InventoryAdjustment;
using Microsoft.QualityManagement.Dispositions.ItemTracking;
using Microsoft.QualityManagement.Dispositions.Move;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Dispositions.PutAway;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Utilities;
using Microsoft.QualityManagement.Workflow;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using System.Automation;
using System.Reflection;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 139940 "Qlty. Inspection Utility"
{
    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryUtility: Codeunit "Library - Utility";
        NoSeriesCodeunit: Codeunit "No. Series";
        DefaultResult2PassCodeLbl: Label 'PASS', Locked = true;
        SupervisorRoleIDTok: Label 'QltyMngmnt - Edit', Locked = true;

    internal procedure EnsureSetupExists()
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
    begin
        QltyAutoConfigure.EnsureBasicSetupExists(false);
        UserPermissionsLibrary.AssignPermissionSetToUser(UserSecurityId(), SupervisorRoleIDTok);
    end;

    internal procedure CreateABasicTemplateAndInstanceOfAInspection(var OutCreatedQltyInspectionHeader: Record "Qlty. Inspection Header"; var OutQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        ClaimedInspectionWasCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        QltyInspectionUtility.EnsureSetupExists();

        QltyInspectionUtility.CreateTemplate(OutQltyInspectionTemplateHdr, 3);

        QltyInspectionUtility.CreatePrioritizedRule(OutQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(2, OrdersList);
        LibraryAssert.AreEqual(2, OrdersList.Count(), 'Common inspection generation. Inspection generator did not make the expected amount of production orders.');
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        OutCreatedQltyInspectionHeader.Reset();
        BeforeCount := OutCreatedQltyInspectionHeader.Count();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ClaimedInspectionWasCreated := QltyInspectionCreate.CreateInspection(ProdOrderRoutingLineRecordRefRecordRef, false);

        OutCreatedQltyInspectionHeader.Reset();
        AfterCount := OutCreatedQltyInspectionHeader.Count();

        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall inspections');
        OutCreatedQltyInspectionHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual((1), OutCreatedQltyInspectionHeader.Count(), 'There should be exactly one inspection for this operation.');
        LibraryAssert.IsTrue(ClaimedInspectionWasCreated, 'An inspection flag should have been created');

        QltyInspectionCreate.GetCreatedInspection(OutCreatedQltyInspectionHeader);
    end;

    internal procedure CreateTemplate(var OutQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; HowManyFields: Integer)
    var
        IgnoredQltyTest: Record "Qlty. Test";
        ToTemplateRecordRef: RecordRef;
        FieldNumberToCreate: Integer;
    begin
        Clear(OutQltyInspectionTemplateHdr);
        OutQltyInspectionTemplateHdr.Init();
        ToTemplateRecordRef.GetTable(OutQltyInspectionTemplateHdr);
        FillTextField(ToTemplateRecordRef, OutQltyInspectionTemplateHdr.FieldNo("Code"), true);
        FillTextField(ToTemplateRecordRef, OutQltyInspectionTemplateHdr.FieldNo(Description), true);
        ToTemplateRecordRef.SetTable(OutQltyInspectionTemplateHdr);
        OutQltyInspectionTemplateHdr.Insert(true);
        if HowManyFields > 0 then
            for FieldNumberToCreate := 1 to HowManyFields do
                CreateTestAndAddToTemplate(OutQltyInspectionTemplateHdr, IgnoredQltyTest, "Qlty. Test Value Type"::"Value Type Text")
    end;

    internal procedure CreateTestAndAddToTemplate(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; QltyTestValueType: Enum "Qlty. Test Value Type")
    var
        IgnoredQltyTest: Record "Qlty. Test";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        Clear(QltyInspectionTemplateLine);
        CreateTest(IgnoredQltyTest, QltyTestValueType);
        QltyInspectionTemplateLine.Init();
        QltyInspectionTemplateLine."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateLine.InitLineNoIfNeeded();
        QltyInspectionTemplateLine.Validate("Test Code", IgnoredQltyTest.Code);
        QltyInspectionTemplateLine.Insert(true);
    end;

    internal procedure CreateTestAndAddToTemplate(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var OutQltyTest: Record "Qlty. Test"; QltyTestValueType: Enum "Qlty. Test Value Type")
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        Clear(QltyInspectionTemplateLine);
        CreateTest(OutQltyTest, QltyTestValueType);
        QltyInspectionTemplateLine.Init();
        QltyInspectionTemplateLine."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateLine.InitLineNoIfNeeded();
        QltyInspectionTemplateLine.Validate("Test Code", OutQltyTest.Code);
        QltyInspectionTemplateLine.Insert(true);
    end;

    internal procedure CreateTestAndAddToTemplate(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; QltyTestValueType: Enum "Qlty. Test Value Type"; var QltyTest: Record "Qlty. Test"; var OutQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line")
    begin
        Clear(OutQltyInspectionTemplateLine);
        CreateTest(QltyTest, QltyTestValueType);
        OutQltyInspectionTemplateLine.Init();
        OutQltyInspectionTemplateLine."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        OutQltyInspectionTemplateLine.InitLineNoIfNeeded();
        OutQltyInspectionTemplateLine.Validate("Test Code", QltyTest.Code);
        OutQltyInspectionTemplateLine.Insert(true);
    end;

    internal procedure CreateTest(var QltyTest: Record "Qlty. Test"; QltyTestValueType: Enum "Qlty. Test Value Type")
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        ToFieldRecordRef: RecordRef;
    begin
        Clear(QltyTest);
        QltyTest.Init();
        QltyTest."Test Value Type" := QltyTestValueType;
        ToFieldRecordRef.GetTable(QltyTest);
        FillTextField(ToFieldRecordRef, QltyTest.FieldNo(Code), true);
        FillTextField(ToFieldRecordRef, QltyTest.FieldNo(Description), true);
        ToFieldRecordRef.SetTable(QltyTest);
        QltyTest.Insert();

        if QltyInspectionResult.Get(DefaultResult2PassCodeLbl) then
            case QltyTestValueType of
                QltyTestValueType::"Value Type Text", QltyTestValueType::"Value Type Text Expression":
                    QltyTest.SetResultCondition(DefaultResult2PassCodeLbl, '<>HARDCODEDFAIL', true);
                QltyTestValueType::"Value Type Decimal", QltyTestValueType::"Value Type Integer":
                    QltyTest.SetResultCondition(DefaultResult2PassCodeLbl, '<>-123', true);
                QltyTestValueType::"Value Type Boolean":
                    QltyTest.SetResultCondition(DefaultResult2PassCodeLbl, '<>FALSE', true);
            end;
    end;

    internal procedure CreatePrioritizedRule(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; SourceTableNo: Integer)
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        CreatePrioritizedRule(InExistingQltyInspectionTemplateHdr, SourceTableNo, QltyInspectionGenRule);
    end;

    internal procedure CreatePrioritizedRule(var InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; SourceTableNo: Integer; var OutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        FindLowestQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        if InExistingQltyInspectionTemplateHdr.Code = '' then
            CreateTemplate(InExistingQltyInspectionTemplateHdr, 0);

        FindLowestQltyInspectionGenRule.ModifyAll("Activation Trigger", FindLowestQltyInspectionGenRule."Activation Trigger"::Disabled);

        FindLowestQltyInspectionGenRule.Reset();
        FindLowestQltyInspectionGenRule.SetCurrentKey("Sort Order");

        OutQltyInspectionGenRule.Init();
        if FindLowestQltyInspectionGenRule.FindFirst() then
            OutQltyInspectionGenRule."Sort Order" := FindLowestQltyInspectionGenRule."Sort Order" - 1;

        OutQltyInspectionGenRule."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        OutQltyInspectionGenRule."Source Table No." := SourceTableNo;
        OutQltyInspectionGenRule.Insert(true);
    end;

    internal procedure CreateItemJournalTemplateAndBatch(TemplateType: Enum "Item Journal Entry Type"; var OutItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItemJournalTemplateByType(ItemJournalTemplate, TemplateType);
        LibraryInventory.CreateItemJournalBatch(OutItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure FillTextField(RecordVariant: Variant; FieldNo: Integer; Validate: Boolean)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        Data: Text;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecordRef);
        FieldRef := RecordRef.Field(FieldNo);
        if not (FieldRef.Type in [FieldType::Code, FieldType::Text]) then
            Error('FillTextField should only be called on code or text fields. Table %1, field %2, type %3', RecordRef.Number(), FieldNo, FieldRef.Type);
        if FieldRef.Length < 10 then
            Error('Unexpected length of %4 for Table %1, field %2, type %3', RecordRef.Number(), FieldNo, FieldRef.Type, FieldRef.Length);

        FillText(FieldRef.Length, Data);
        if Validate then
            FieldRef.Validate(Data)
        else
            FieldRef.Value(Data);
    end;

    local procedure FillText(NumberOfCharacters: Integer; var Out: Text)
    var
        CompanyInformation: Record "Company Information";
        Now: DateTime;
        CompanyCreated: DateTime;
        igIntMilliseconds: BigInteger;
        CharactersToGenerate: Integer;
        RandomCharacters: Text;
        SequenceNumber: Integer;
    begin
        if NumberOfCharacters < 0 then
            Error('FillText is being called incorrectly, NumberOfCharacters must be > 0');

        if not NumberSequence.Exists('QualityManagementAutoTests') then
            NumberSequence.Insert('QualityManagementAutoTests');
        SequenceNumber := NumberSequence.Next('QualityManagementAutoTests', true);

        Clear(Out);
        Now := System.CurrentDateTime();
        CompanyInformation.Get();
        CompanyCreated := CompanyInformation.SystemCreatedAt;
        Out += format(SequenceNumber, 0, 9);

        igIntMilliseconds := (Now - CompanyCreated);
        Out += format(igIntMilliseconds, 0, 9);

        CharactersToGenerate := NumberOfCharacters - strlen(Out);
        if CharactersToGenerate > 0 then begin
            GenerateRandomCharacters(CharactersToGenerate, RandomCharacters);
            Out := Out + RandomCharacters;
        end;

        if (strlen(Out) > NumberOfCharacters) then begin
            Out := CopyStr(Out, strlen(Out), NumberOfCharacters);
            exit;
        end;
    end;

    /// <summary>
    /// Intentionally not using RandText() from Library - Random, because it's not random based on how it
    /// generates text with the guids, making collision counts very high.
    /// </summary>
    /// <param name="NumberOfCharacters"></param>
    /// <param name="Out"></param>
    internal procedure GenerateRandomCharacters(NumberOfCharacters: Integer; var Out: Text)
    var
        LibraryRandom: Codeunit "Library - Random";
        CharSet: Text[36];
        Index: Integer;
    begin
        Clear(Out);
        CharSet := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

        LibraryRandom.Init();

        for Index := 1 to NumberOfCharacters do
            Out += CopyStr(CharSet, LibraryRandom.RandIntInRange(1, 36), 1);
    end;

    /// <summary>
    /// Creates a lot no. series and a lot-tracked item
    /// </summary>
    /// <param name="OutItem"></param>
    internal procedure CreateLotTrackedItem(var OutItem: Record Item)
    var
        NoSeries: Record "No. Series";
    begin
        CreateLotTrackedItem(OutItem, NoSeries);
    end;

    /// <summary>
    /// Creates a lot no. series and a lot-tracked item
    /// </summary>
    /// <param name="OutItem"></param>
    internal procedure CreateLotTrackedItem(var OutItem: Record Item; var OutLotNoSeries: Record "No. Series")
    var
        InventorySetup: Record "Inventory Setup";
        ItemNoSeries: Record "No. Series";
        ItemNoSeriesLine: Record "No. Series Line";
        LotNoSeriesLine: Record "No. Series Line";
        LotItemTrackingCode: Record "Item Tracking Code";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility2: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        LibraryUtility2.CreateNoSeries(ItemNoSeries, true, true, false);
        GetCode20NoSeries('IL', StartingNo, EndingNo);
        LibraryUtility2.CreateNoSeriesLine(ItemNoSeriesLine, ItemNoSeries.Code, StartingNo, EndingNo);
        LibraryUtility2.CreateNoSeries(OutLotNoSeries, true, true, false);
        GetCode20NoSeries('L', StartingNo, EndingNo);
        LibraryUtility2.CreateNoSeriesLine(LotNoSeriesLine, OutLotNoSeries.Code, StartingNo, EndingNo);

        LibraryItemTracking.CreateItemTrackingCode(LotItemTrackingCode, false, true, false);

        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", ItemNoSeries.Code);
        InventorySetup.Modify(true);

        LibraryInventory.CreateTrackedItem(OutItem, OutLotNoSeries.Code, '', LotItemTrackingCode.Code);
        OutItem.Rename(NoSeriesCodeunit.PeekNextNo(ItemNoSeries.Code));
        OutItem.Modify();

        OutItem.Validate("Unit Cost", 1.234);
        OutItem.Validate("Unit Price", 2.2345);
        OutItem.Modify();
    end;

    /// <summary>
    /// Creates a serial no. series and a serial-tracked item
    /// </summary>
    /// <param name="OutItem"></param>
    internal procedure CreateSerialTrackedItem(var OutItem: Record Item)
    var
        NoSeries: Record "No. Series";
    begin
        CreateSerialTrackedItem(OutItem, NoSeries);
    end;

    /// <summary>
    /// Creates a serial no. series and a serial-tracked item
    /// </summary>
    /// <param name="OutItem"></param>
    internal procedure CreateSerialTrackedItem(var OutItem: Record Item; var OutSerialNoSeries: Record "No. Series")
    var
        InventorySetup: Record "Inventory Setup";
        ItemNoSeries: Record "No. Series";
        ItemNoSeriesLine: Record "No. Series Line";
        SerialNoSeriesLine: Record "No. Series Line";
        SerialItemTrackingCode: Record "Item Tracking Code";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility2: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        LibraryUtility2.CreateNoSeries(ItemNoSeries, true, true, false);
        GetCode20NoSeries('IS', StartingNo, EndingNo);
        LibraryUtility2.CreateNoSeriesLine(ItemNoSeriesLine, ItemNoSeries.Code, StartingNo, EndingNo);
        LibraryUtility2.CreateNoSeries(OutSerialNoSeries, true, true, false);
        GetCode20NoSeries('S', StartingNo, EndingNo);
        LibraryUtility2.CreateNoSeriesLine(SerialNoSeriesLine, OutSerialNoSeries.Code, StartingNo, EndingNo);

        LibraryItemTracking.CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);

        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", ItemNoSeries.Code);
        InventorySetup.Modify(true);

        LibraryInventory.CreateTrackedItem(OutItem, '', OutSerialNoSeries.Code, SerialItemTrackingCode.Code);
        OutItem.Rename(NoSeriesCodeunit.PeekNextNo(ItemNoSeries.Code));

        OutItem.Modify();

        OutItem.Validate("Unit Cost", 1.234);
        OutItem.Validate("Unit Price", 2.2345);
        OutItem.Modify();
    end;

    /// <summary>
    /// Creates a package no. series and a package-tracked item
    /// </summary>
    /// <param name="OutItem"></param>
    internal procedure CreatePackageTrackedItemWithNoSeries(var OutItem: Record Item; var OutPackageNoSeries: Record "No. Series")
    var
        InventorySetup: Record "Inventory Setup";
        PackageNoSeriesLine: Record "No. Series Line";
        PackageItemTrackingCode: Record "Item Tracking Code";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility2: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        StartingNo: Code[20];
        EndingNo: Code[20];
    begin
        InventorySetup.Get();
        GetCode20NoSeries('P', StartingNo, EndingNo);
        if InventorySetup."Package Nos." <> '' then begin
            OutPackageNoSeries.Get(InventorySetup."Package Nos.");
            PackageNoSeriesLine.SetRange(PackageNoSeriesLine."Series Code");
            if PackageNoSeriesLine.Count = 0 then
                LibraryUtility2.CreateNoSeriesLine(PackageNoSeriesLine, OutPackageNoSeries.Code, StartingNo, EndingNo);
        end else begin
            LibraryUtility2.CreateNoSeries(OutPackageNoSeries, true, true, false);
            LibraryUtility2.CreateNoSeriesLine(PackageNoSeriesLine, OutPackageNoSeries.Code, StartingNo, EndingNo);
            InventorySetup.Validate("Package Nos.", OutPackageNoSeries.Code);
            InventorySetup.Modify(true);
        end;
        LibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);

        LibraryInventory.CreateItem(OutItem);
        OutItem.Validate("Item Tracking Code", PackageItemTrackingCode.Code);
        OutItem.Validate("Unit Cost", 1.234);
        OutItem.Validate("Unit Price", 2.2345);
        OutItem.Modify();
    end;

    /// <summary>
    /// Sets user as warehouse employee for location
    /// </summary>
    /// <param name="Location"></param>
    internal procedure SetCurrLocationWhseEmployee(Location: Code[10])
    var
        WhseWarehouseEmployee: Record "Warehouse Employee";
    begin
        WhseWarehouseEmployee.Validate("User ID", UserId());
        WhseWarehouseEmployee.Validate("Location Code", Location);
        WhseWarehouseEmployee.Default := true;
        if WhseWarehouseEmployee.Insert() then;
    end;

    /// <summary>
    /// Creates Quality Inspection from purchase line for tracked item
    /// </summary>
    /// <param name="PurOrdPurchaseLine"></param>
    /// <param name="ReservationEntry"></param>
    /// <param name="OutQltyInspectionHeader"></param>
    internal procedure CreateInspectionWithPurchaseLineAndTracking(PurOrdPurchaseLine: Record "Purchase Line"; ReservationEntry: Record "Reservation Entry"; var OutQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        SpecTrackingSpecification: Record "Tracking Specification";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        PurchaseLineRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        InspectionCreated: Boolean;
    begin
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        InspectionCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(PurchaseLineRecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '');
        LibraryAssert.IsTrue(InspectionCreated, 'Quality Inspection not created.');

        QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        LibraryAssert.RecordCount(OutQltyInspectionHeader, 1);
    end;

    /// <summary>
    /// Creates Quality Inspection from warehouse entry for tracked item
    /// </summary>
    /// <param name="WarehouseEntry"></param>
    /// <param name="ReservationEntry"></param>
    /// <param name="OutQltyInspectionHeader"></param>
    internal procedure CreateInspectionWithWarehouseEntryAndTracking(WarehouseEntry: Record "Warehouse Entry"; ReservationEntry: Record "Reservation Entry"; var OutQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        SpecTrackingSpecification: Record "Tracking Specification";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        InspectionCreated: Boolean;
    begin
        RecordRef.GetTable(WarehouseEntry);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        InspectionCreated := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(RecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, false, '');
        LibraryAssert.IsTrue(InspectionCreated, 'Quality Inspection not created.');

        QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        LibraryAssert.RecordCount(OutQltyInspectionHeader, 1);
    end;

    /// <summary>
    /// Creates Quality Inspection from purchase line for untracked item
    /// </summary>
    /// <param name="PurOrdPurchaseLine"></param>
    /// <param name="SpecificTemplate">The specific template to use.</param>
    /// <param name="OutQltyInspectionHeader"></param>
    internal procedure CreateInspectionWithPurchaseLine(PurOrdPurchaseLine: Record "Purchase Line"; SpecificTemplate: Code[20]; var OutQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        PurchaseLineRecordRef: RecordRef;
        InspectionCreated: Boolean;
    begin
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        InspectionCreated := QltyInspectionCreate.CreateInspectionWithSpecificTemplate(PurchaseLineRecordRef, false, SpecificTemplate);
        LibraryAssert.IsTrue(InspectionCreated, 'Quality Inspection not created.');

        QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        LibraryAssert.RecordCount(OutQltyInspectionHeader, 1);
    end;

    /// <summary>
    /// Creates Quality Inspection for warehouse entry for untracked item
    /// </summary>
    /// <param name="WarehouseEntry"></param>
    /// <param name="OutQltyInspectionHeader"></param>
    internal procedure CreateInspectionWithWarehouseEntry(WarehouseEntry: Record "Warehouse Entry"; var OutQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        RecordRef: RecordRef;
        InspectionCreated: Boolean;
    begin
        RecordRef.GetTable(WarehouseEntry);
        InspectionCreated := QltyInspectionCreate.CreateInspection(RecordRef, false);
        LibraryAssert.IsTrue(InspectionCreated, 'Quality Inspection not created.');

        QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        LibraryAssert.RecordCount(OutQltyInspectionHeader, 1);
    end;

    /// <summary>
    /// Creates Quality Inspection from a RecordRef with option to prevent displaying inspection.
    /// Useful for tests that need to suppress UI dialogs during inspection creation.
    /// </summary>
    /// <param name="SourceRecordRef">The source record reference.</param>
    /// <param name="PreventDisplaying">If true, prevents displaying inspection even if configured.</param>
    /// <param name="RaiseErrorIfNoRuleFound">If true, raises an error when no matching rule is found.</param>
    /// <param name="OutQltyInspectionHeader">The created inspection header.</param>
    internal procedure CreateInspectionWithPreventDisplaying(SourceRecordRef: RecordRef; PreventDisplaying: Boolean; RaiseErrorIfNoRuleFound: Boolean; var OutQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        QltyInspectionCreate.SetPreventDisplayingInspectionEvenIfConfigured(PreventDisplaying);
        QltyInspectionCreate.CreateInspection(SourceRecordRef, RaiseErrorIfNoRuleFound);
        QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
    end;

    /// <summary>
    /// This works around a flaw in "Library - Warehouse"::CreateWhseJournalLine where it only supports the item template and does insufficient filtering.
    /// It's otherwise nearly identical to CreateReclassWhseJournalLine from "Library - Warehouse"::CreateWhseJournalLine
    /// </summary>
    /// <param name="ReclassWarehouseJournalLine"></param>
    /// <param name="JournalTemplateName"></param>
    /// <param name="JournalBatchName"></param>
    /// <param name="LocationCode"></param>
    /// <param name="ZoneCode"></param>
    /// <param name="BinCode"></param>
    /// <param name="EntryType"></param>
    /// <param name="ItemNo"></param>
    /// <param name="NewQuantity"></param>
    internal procedure CreateReclassWhseJournalLine(var ReclassWarehouseJournalLine: Record "Warehouse Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; EntryType: Option; ItemNo: Code[20]; NewQuantity: Decimal)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        BatchNoSeries: Record "No. Series";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        BatchGeneratorNoSeries: Codeunit "No. Series";
        RecordRef: RecordRef;
        DocumentNo: Code[20];
    begin
        ReclassWarehouseJournalLine.LockTable(true);
        QltyManagementSetup.LockTable();
        if not WarehouseJournalBatch.Get(JournalTemplateName, JournalBatchName, LocationCode) then begin
            WarehouseJournalBatch.Init();
            WarehouseJournalBatch.Validate("Journal Template Name", JournalTemplateName);
            WarehouseJournalBatch.SetupNewBatch();
            WarehouseJournalBatch.Validate(Name, JournalBatchName);
            WarehouseJournalBatch.Validate(Description, JournalBatchName + ' journal');
            WarehouseJournalBatch.Validate("Location Code", LocationCode);
            WarehouseJournalBatch.Insert(true);
        end;

        ReclassWarehouseJournalLine.Validate("Journal Template Name", JournalTemplateName);
        ReclassWarehouseJournalLine.Validate("Journal Batch Name", JournalBatchName);
        ReclassWarehouseJournalLine.Validate("Location Code", LocationCode);
        ReclassWarehouseJournalLine.Validate("Zone Code", ZoneCode);
        ReclassWarehouseJournalLine.Validate("Bin Code", BinCode);

        ReclassWarehouseJournalLine.SetUpNewLine(ReclassWarehouseJournalLine);

        RecordRef.GetTable(ReclassWarehouseJournalLine);
        ReclassWarehouseJournalLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ReclassWarehouseJournalLine.FieldNo("Line No.")));
        ReclassWarehouseJournalLine.Insert(true);
        ReclassWarehouseJournalLine.Validate("Registering Date", WorkDate());
        ReclassWarehouseJournalLine.Validate("Entry Type", EntryType);
        if BatchNoSeries.Get(WarehouseJournalBatch."No. Series") then
            DocumentNo := BatchGeneratorNoSeries.PeekNextNo(WarehouseJournalBatch."No. Series", ReclassWarehouseJournalLine."Registering Date")
        else
            DocumentNo := 'Default Document No.';
        ReclassWarehouseJournalLine.Validate("Whse. Document No.", DocumentNo);
        ReclassWarehouseJournalLine.Validate("Item No.", ItemNo);
        ReclassWarehouseJournalLine.Validate(Quantity, NewQuantity);
        ReclassWarehouseJournalLine.Modify(true);
    end;

    internal procedure ClearResultLotSettings(var QltyInspectionResult: Record "Qlty. Inspection Result")
    begin
        QltyInspectionResult."Item Tracking Allow Sales" := QltyInspectionResult."Item Tracking Allow Sales"::Allow;
        QltyInspectionResult."Item Tracking Allow Asm. Cons." := QltyInspectionResult."Item Tracking Allow Asm. Cons."::Allow;
        QltyInspectionResult."Item Tracking Allow Asm. Out." := QltyInspectionResult."Item Tracking Allow Asm. Out."::Allow;
        QltyInspectionResult."Item Tracking Allow Consump." := QltyInspectionResult."Item Tracking Allow Consump."::Allow;
        QltyInspectionResult."Item Tracking Allow Invt. Mov." := QltyInspectionResult."Item Tracking Allow Invt. Mov."::Allow;
        QltyInspectionResult."Item Tracking Allow Invt. Pick" := QltyInspectionResult."Item Tracking Allow Invt. Pick"::Allow;
        QltyInspectionResult."Item Tracking Allow Invt. PA" := QltyInspectionResult."Item Tracking Allow Invt. PA"::Allow;
        QltyInspectionResult."Item Tracking Allow Movement" := QltyInspectionResult."Item Tracking Allow Movement"::Allow;
        QltyInspectionResult."Item Tracking Allow Output" := QltyInspectionResult."Item Tracking Allow Output"::Allow;
        QltyInspectionResult."Item Tracking Allow Pick" := QltyInspectionResult."Item Tracking Allow Pick"::Allow;
        QltyInspectionResult."Item Tracking Allow Purchase" := QltyInspectionResult."Item Tracking Allow Purchase"::Allow;
        QltyInspectionResult."Item Tracking Allow Put-Away" := QltyInspectionResult."Item Tracking Allow Put-Away"::Allow;
        QltyInspectionResult."Item Tracking Allow Transfer" := QltyInspectionResult."Item Tracking Allow Transfer"::Allow;
        QltyInspectionResult.Modify();
    end;

    internal procedure ClearSetupTriggerDefaults(var QltyManagementSetup: Record "Qlty. Management Setup")
    begin
        QltyManagementSetup."Purchase Order Trigger" := QltyManagementSetup."Purchase Order Trigger"::NoTrigger;
        QltyManagementSetup."Sales Return Trigger" := QltyManagementSetup."Sales Return Trigger"::NoTrigger;
        QltyManagementSetup."Warehouse Receipt Trigger" := QltyManagementSetup."Warehouse Receipt Trigger"::NoTrigger;
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;
        QltyManagementSetup."Transfer Order Trigger" := QltyManagementSetup."Transfer Order Trigger"::NoTrigger;
        QltyManagementSetup."Production Order Trigger" := QltyManagementSetup."Production Order Trigger"::NoTrigger;
        QltyManagementSetup."Assembly Trigger" := QltyManagementSetup."Assembly Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    internal procedure CreatePackageTracking(var PackageNoSeries: Record "No. Series"; var PackageNoSeriesLine: Record "No. Series Line"; var PackageItemTrackingCode: Record "Item Tracking Code")
    var
        InventorySetup: Record "Inventory Setup";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
    begin
        InventorySetup.Get();
        if InventorySetup."Package Nos." <> '' then begin
            PackageNoSeries.Get(InventorySetup."Package Nos.");
            PackageNoSeriesLine.SetRange(PackageNoSeriesLine."Series Code");
            if not PackageNoSeriesLine.FindFirst() then
                LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'P<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'P<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        end else begin
            LibraryUtility.CreateNoSeries(PackageNoSeries, true, true, false);
            LibraryUtility.CreateNoSeriesLine(PackageNoSeriesLine, PackageNoSeries.Code, PadStr(Format(CurrentDateTime(), 0, 'P<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'), PadStr(Format(CurrentDateTime(), 0, 'P<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
            InventorySetup.Validate("Package Nos.", PackageNoSeries.Code);
            InventorySetup.Modify(true);
        end;
        LibraryItemTracking.CreateItemTrackingCode(PackageItemTrackingCode, false, false, true);
    end;

    internal procedure CreateLotTrackedItemWithVariant(var LotTrackedItem: Record Item; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateLotTrackedItem(LotTrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, LotTrackedItem."No.");
        LotTrackedItem.Modify(true);
    end;

    internal procedure CreateSerialTrackedItemWithVariant(var SerialTrackedItem: Record Item; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateSerialTrackedItem(SerialTrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, SerialTrackedItem."No.");
        SerialTrackedItem.Modify(true);
    end;

    internal procedure CreateSerialTrackedItemWithVariant(var SerialTrackedItem: Record Item; SerialNoSeries: Code[20]; SerialTrackingCode: Code[10]; UnitCost: Decimal; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateSerialTrackedItem(SerialTrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, SerialTrackedItem."No.");
    end;

    internal procedure CreatePackageTrackedItem(var PackageTrackedItem: Record Item; PackageTrackingCode: Code[10]; UnitCost: Decimal; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(PackageTrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, PackageTrackedItem."No.");
        PackageTrackedItem.Validate("Item Tracking Code", PackageTrackingCode);
        PackageTrackedItem.Validate("Unit Cost", UnitCost);
        PackageTrackedItem.Modify(true);
    end;

    internal procedure CreateUntrackedItem(var UntrackedItem: Record Item; UnitCost: Decimal; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(UntrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, UntrackedItem."No.");
        UntrackedItem.Validate("Unit Cost", UnitCost);
        UntrackedItem.Modify(true);
    end;

    internal procedure GetCode20NoSeries(InPrefix: Text; var OutStart: Code[20]; var OutEnd: Code[20])
    var
        Temp: Text;
    begin
        Temp :=
            InPrefix + Format(CurrentDateTime(), 0, '<Year><Month,2><Day,2><Hours24><Minutes><Seconds>') +
            GetNextSequenceNoAsText(InPrefix, 3);
        OutStart := CopyStr(Temp.PadRight(MaxStrLen(OutStart), '1'), 1, MaxStrLen(OutStart));
        OutEnd := CopyStr(Temp.PadRight(MaxStrLen(OutEnd), '9'), 1, MaxStrLen(OutEnd));
    end;

    local procedure GetNextSequenceNoAsText(SequenceKey: Text; PadSize: Integer) Out: Text;
    var
        QltySessionHelper: Codeunit "Qlty. Session Helper";
        BigResult: BigInteger;
        CurrentSessionValue: Text;
        PreviousessionDateTime: DateTime;
        Sequence: BigInteger;
    begin
        SequenceKey := SequenceKey + Format(CurrentDateTime(), 0, '<Year><Month,2><Day,2><Hours24><Minutes>');
        CurrentSessionValue := QltySessionHelper.GetSessionValue(SequenceKey);
        PreviousessionDateTime := CurrentDateTime();
        if CurrentSessionValue <> '' then
            Evaluate(PreviousessionDateTime, CurrentSessionValue, 9);
        QltySessionHelper.SetSessionValue(SequenceKey, Format(CurrentDateTime(), 0, 9));

        if PreviousessionDateTime <> 0DT then
            BigResult := CurrentDateTime() - PreviousessionDateTime;

        if not NumberSequence.Exists(SequenceKey, true) then
            NumberSequence.Insert(SequenceKey, BigResult);

        Sequence := NumberSequence.Next(SequenceKey);
        if Sequence < BigResult then
            NumberSequence.Restart(SequenceKey, BigResult);

        Sequence := NumberSequence.Next(SequenceKey);
        Out := Format(Sequence, 0, 9);
        Out := Out.PadLeft(PadSize, '0');
    end;

    internal procedure CreateWarehouseReceiptSetup(var CreatedQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"; var OutPurchaseLine: Record "Purchase Line"; var OutReservationEntry: Record "Reservation Entry")
    begin
        CreateWarehouseReceiptSetup(CreatedQltyInspectionGenRule, OutPurchaseLine, OutReservationEntry, 123);
    end;

    internal procedure CreateWarehouseReceiptSetup(var CreatedQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"; var OutPurchaseLine: Record "Purchase Line"; var OutReservationEntry: Record "Reservation Entry"; Quantity: Decimal)
    var
        Item: Record Item;
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        PurchaseHeader: Record "Purchase Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        OrdQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        EnsureSetupExists();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        CreateTemplate(QltyInspectionTemplateHdr, 1);
        CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", CreatedQltyInspectionGenRule);

        CreatedQltyInspectionGenRule."Purchase Order Trigger" := CreatedQltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive;
        CreatedQltyInspectionGenRule.Modify();

        CreateLotTrackedItem(Item);

        Item.SetRecFilter();
        CreatedQltyInspectionGenRule."Item Filter" := CopyStr(Item.GetView(), 1, MaxStrLen(CreatedQltyInspectionGenRule."Item Filter"));
        CreatedQltyInspectionGenRule."Activation Trigger" := CreatedQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic";
        CreatedQltyInspectionGenRule."Purchase Order Trigger" := CreatedQltyInspectionGenRule."Purchase Order Trigger"::OnPurchaseOrderPostReceive;
        CreatedQltyInspectionGenRule.Modify();

        OrdQltyPurOrderGenerator.CreatePurchaseOrder(Quantity, Location, Item, PurchaseHeader, OutPurchaseLine, OutReservationEntry);
    end;

    /// <summary>
    /// Wrapper for internal procedure IsQualityManagementApplicationAreaEnabled from Qlty. Application Area Mgmt. codeunit.
    /// </summary>
    /// <returns>True if Quality Management application area is enabled.</returns>
    internal procedure IsQualityManagementApplicationAreaEnabled(): Boolean
    var
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
    begin
        exit(QltyApplicationAreaMgmt.IsQualityManagementApplicationAreaEnabled());
    end;

    #region Qlty. Auto Configure Wrappers

    /// <summary>
    /// Wrapper for internal procedure EnsureBasicSetupExists from Qlty. Auto Configure codeunit.
    /// Ensures that basic quality management setup exists.
    /// </summary>
    /// <param name="ShowUI">Whether to show UI during setup.</param>
    internal procedure EnsureBasicSetupExists(ShowUI: Boolean)
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        QltyAutoConfigure.EnsureBasicSetupExists(ShowUI);
    end;

    /// <summary>
    /// Wrapper for internal procedure GetDefaultPassResult from Qlty. Auto Configure codeunit.
    /// Returns the default PASS result code.
    /// </summary>
    /// <returns>The default PASS result code.</returns>
    internal procedure GetDefaultPassResult(): Code[20]
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        ResultCode: Code[20];
    begin
        ResultCode := CopyStr(QltyAutoConfigure.GetDefaultPassResult(), 1, MaxStrLen(ResultCode));
        exit(ResultCode);
    end;

    #endregion Qlty. Auto Configure Wrappers

    #region Qlty. Result Evaluation Wrappers

    /// <summary>
    /// Wrapper for internal procedure CheckIfValueIsDecimal from Qlty. Result Evaluation codeunit.
    /// </summary>
    /// <param name="ValueToCheck">The value to check.</param>
    /// <param name="AcceptableValue">The acceptable value condition.</param>
    /// <returns>True if the value matches the condition, false otherwise.</returns>
    internal procedure CheckIfValueIsDecimal(ValueToCheck: Text; AcceptableValue: Text): Boolean
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.CheckIfValueIsDecimal(ValueToCheck, AcceptableValue));
    end;

    /// <summary>
    /// Wrapper for internal procedure CheckIfValueIsInteger from Qlty. Result Evaluation codeunit.
    /// </summary>
    /// <param name="ValueToCheck">The value to check.</param>
    /// <param name="AcceptableValue">The acceptable value condition.</param>
    /// <returns>True if the value matches the condition, false otherwise.</returns>
    internal procedure CheckIfValueIsInteger(ValueToCheck: Text; AcceptableValue: Text): Boolean
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.CheckIfValueIsInteger(ValueToCheck, AcceptableValue));
    end;

    /// <summary>
    /// Wrapper for internal procedure CheckIfValueIsString from Qlty. Result Evaluation codeunit.
    /// Uses default case sensitivity (Sensitive).
    /// </summary>
    /// <param name="ValueToCheck">The value to check.</param>
    /// <param name="AcceptableValue">The acceptable value condition.</param>
    /// <returns>True if the value matches the condition, false otherwise.</returns>
    internal procedure CheckIfValueIsString(ValueToCheck: Text; AcceptableValue: Text): Boolean
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.CheckIfValueIsString(ValueToCheck, AcceptableValue));
    end;

    /// <summary>
    /// Wrapper for internal procedure CheckIfValueIsString from Qlty. Result Evaluation codeunit.
    /// </summary>
    /// <param name="ValueToCheck">The value to check.</param>
    /// <param name="AcceptableValue">The acceptable value condition.</param>
    /// <param name="QltyCaseSensitivity">The case sensitivity option.</param>
    /// <returns>True if the value matches the condition, false otherwise.</returns>
    internal procedure CheckIfValueIsString(ValueToCheck: Text; AcceptableValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Boolean
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.CheckIfValueIsString(ValueToCheck, AcceptableValue, QltyCaseSensitivity));
    end;

    /// <summary>
    /// Wrapper for internal procedure ValidateQltyInspectionLine from Qlty. Result Evaluation codeunit.
    /// Validates an inspection line using the single-parameter internal signature.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line to validate.</param>
    internal procedure ValidateQltyInspectionLine(var QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyResultEvaluation.ValidateQltyInspectionLine(QltyInspectionLine);
    end;

    /// <summary>
    /// Wrapper for internal procedure ValidateAllowableValuesOnTest from Qlty. Result Evaluation codeunit.
    /// Validates allowable values on a test with inspection header context only.
    /// </summary>
    /// <param name="QltyTest">The test record to validate.</param>
    /// <param name="QltyInspectionHeader">The inspection header context.</param>
    internal procedure ValidateAllowableValuesOnTest(var QltyTest: Record "Qlty. Test"; var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyResultEvaluation.ValidateAllowableValuesOnTest(QltyTest, QltyInspectionHeader, QltyInspectionLine);
    end;

    /// <summary>
    /// Wrapper for internal procedure EvaluateResult from Qlty. Result Evaluation codeunit.
    /// Evaluates result without inspection line context (passing empty line record).
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header.</param>
    /// <param name="QltyIResultConditConf">The result condition configuration.</param>
    /// <param name="QltyTestValueType">The test value type.</param>
    /// <param name="Value">The value to evaluate.</param>
    /// <param name="QltyCaseSensitivity">The case sensitivity option.</param>
    /// <returns>The result code.</returns>
    internal procedure EvaluateResult(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf."; QltyTestValueType: Enum "Qlty. Test Value Type"; Value: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Code[20]
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.EvaluateResult(QltyInspectionHeader, QltyInspectionLine, QltyIResultConditConf, QltyTestValueType, Value, QltyCaseSensitivity));
    end;

    /// <summary>
    /// Wrapper for internal procedure ValidateAllowableValuesOnTest from Qlty. Result Evaluation codeunit.
    /// 1-parameter overload.
    /// </summary>
    /// <param name="QltyTest">The test record to validate.</param>
    internal procedure ValidateAllowableValuesOnTest(var QltyTest: Record "Qlty. Test")
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyResultEvaluation.ValidateAllowableValuesOnTest(QltyTest);
    end;

    /// <summary>
    /// Wrapper for internal procedure ValidateAllowableValuesOnTest from Qlty. Result Evaluation codeunit.
    /// 3-parameter overload with inspection header and line context.
    /// </summary>
    /// <param name="QltyTest">The test record to validate.</param>
    /// <param name="QltyInspectionHeader">The inspection header context.</param>
    /// <param name="QltyInspectionLine">The inspection line context.</param>
    internal procedure ValidateAllowableValuesOnTest(var QltyTest: Record "Qlty. Test"; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyResultEvaluation.ValidateAllowableValuesOnTest(QltyTest, QltyInspectionHeader, QltyInspectionLine);
    end;

    /// <summary>
    /// Wrapper for internal procedure ValidateInspectionLineWithAllowableValues from Qlty. Result Evaluation codeunit.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line to validate.</param>
    /// <param name="OptionalQltyInspectionHeader">The optional inspection header.</param>
    /// <param name="CheckForAllowableValues">Whether to check for allowable values.</param>
    /// <param name="UpdateHeader">Whether to update the header.</param>
    internal procedure ValidateInspectionLineWithAllowableValues(var QltyInspectionLine: Record "Qlty. Inspection Line"; var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; CheckForAllowableValues: Boolean; UpdateHeader: Boolean)
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyResultEvaluation.ValidateInspectionLineWithAllowableValues(QltyInspectionLine, OptionalQltyInspectionHeader, CheckForAllowableValues, UpdateHeader);
    end;

    /// <summary>
    /// Wrapper for internal procedure GetInspectionLineConfigFilters from Qlty. Result Evaluation codeunit.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line.</param>
    /// <param name="TemplateLineQltyIResultConditConf">The result condition configuration record to set filters on.</param>
    internal procedure GetInspectionLineConfigFilters(var QltyInspectionLine: Record "Qlty. Inspection Line"; var TemplateLineQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.")
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyResultEvaluation.GetInspectionLineConfigFilters(QltyInspectionLine, TemplateLineQltyIResultConditConf);
    end;

    /// <summary>
    /// Wrapper for running Qlty. Result Evaluation codeunit OnRun trigger.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line to evaluate.</param>
    /// <returns>True if the evaluation succeeded, false otherwise.</returns>
    internal procedure RunResultEvaluation(var QltyInspectionLine: Record "Qlty. Inspection Line"): Boolean
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.Run(QltyInspectionLine));
    end;

    #endregion Qlty. Result Evaluation Wrappers

    #region Qlty. Notification Mgmt. Wrappers

    /// <summary>
    /// Wrapper for internal procedure NotifyDoYouWantToAssignToYourself from Qlty. Notification Mgmt. codeunit.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header record.</param>
    internal procedure NotifyDoYouWantToAssignToYourself(QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        QltyNotificationMgmt.NotifyDoYouWantToAssignToYourself(QltyInspectionHeader);
    end;

    /// <summary>
    /// Wrapper for internal procedure HandleOpenDocument from Qlty. Notification Mgmt. codeunit.
    /// </summary>
    /// <param name="NotificationToShow">The notification that triggered the action.</param>
    internal procedure HandleOpenDocument(NotificationToShow: Notification)
    var
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        QltyNotificationMgmt.HandleOpenDocument(NotificationToShow);
    end;

    /// <summary>
    /// Wrapper for internal procedure HandleNotificationActionAssignToSelf from Qlty. Notification Mgmt. codeunit.
    /// </summary>
    /// <param name="NotificationToShow">The notification that triggered the action.</param>
    internal procedure HandleNotificationActionAssignToSelf(NotificationToShow: Notification)
    var
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        QltyNotificationMgmt.HandleNotificationActionAssignToSelf(NotificationToShow);
    end;

    /// <summary>
    /// Wrapper for internal procedure HandleNotificationActionIgnore from Qlty. Notification Mgmt. codeunit.
    /// </summary>
    /// <param name="NotificationToShow">The notification that triggered the action.</param>
    internal procedure HandleNotificationActionIgnore(NotificationToShow: Notification)
    var
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        QltyNotificationMgmt.HandleNotificationActionIgnore(NotificationToShow);
    end;

    #endregion Qlty. Notification Mgmt. Wrappers

    #region Qlty. Inspection - Create Wrappers

    /// <summary>
    /// Wrapper for internal procedure FindExistingInspectionWithMultipleVariants from Qlty. Inspection - Create codeunit.
    /// Finds existing inspections based on the multiple variants supplied.
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">If true, raises an error when no matching rule is found.</param>
    /// <param name="ReferenceVariant">The main reference variant.</param>
    /// <param name="OptionalVariant2">Optional second variant.</param>
    /// <param name="OptionalVariant3">Optional third variant.</param>
    /// <param name="OptionalVariant4">Optional fourth variant.</param>
    /// <param name="QltyInspectionHeader">The found inspection header.</param>
    /// <returns>True if an existing inspection was found.</returns>
    internal procedure FindExistingInspectionWithMultipleVariants(RaiseErrorIfNoRuleIsFound: Boolean; ReferenceVariant: Variant; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant; var QltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.FindExistingInspectionWithMultipleVariants(RaiseErrorIfNoRuleIsFound, ReferenceVariant, OptionalVariant2, OptionalVariant3, OptionalVariant4, QltyInspectionHeader));
    end;

    /// <summary>
    /// Wrapper for internal procedure FindExistingInspection from Qlty. Inspection - Create codeunit.
    /// Finds existing inspections based on RecordRef parameters.
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">If true, raises an error when no matching rule is found.</param>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against.</param>
    /// <param name="Optional2RecordRef">Optional second RecordRef.</param>
    /// <param name="Optional3RecordRef">Optional third RecordRef.</param>
    /// <param name="Optional4RecordRef">Optional fourth RecordRef.</param>
    /// <param name="QltyInspectionHeader">The found inspection header.</param>
    /// <returns>True if an existing inspection was found.</returns>
    internal procedure FindExistingInspection(RaiseErrorIfNoRuleIsFound: Boolean; TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; var QltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.FindExistingInspection(RaiseErrorIfNoRuleIsFound, TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, QltyInspectionHeader));
    end;

    #endregion Qlty. Inspection - Create Wrappers

    #region Qlty. Traversal Wrappers

    /// <summary>
    /// Wrapper for internal procedure FindRelatedItem from Qlty. Traversal codeunit (4 optional variants version).
    /// Searches for a related Item record by sequentially checking supplied record variants.
    /// </summary>
    /// <param name="Item">Output parameter that will contain the found Item record.</param>
    /// <param name="TargetRecordRef">Primary record reference to search from.</param>
    /// <param name="Optional2Variant">Second optional variant to search.</param>
    /// <param name="Optional3Variant">Third optional variant to search.</param>
    /// <param name="Optional4Variant">Fourth optional variant to search.</param>
    /// <returns>True if an Item was found; False otherwise.</returns>
    internal procedure FindRelatedItem(var Item: Record Item; TargetRecordRef: RecordRef; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant): Boolean
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        exit(QltyTraversal.FindRelatedItem(Item, TargetRecordRef, Optional2Variant, Optional3Variant, Optional4Variant));
    end;

    /// <summary>
    /// Wrapper for internal procedure FindRelatedItem from Qlty. Traversal codeunit (5 optional variants version).
    /// Searches for a related Item record by sequentially checking supplied record variants.
    /// </summary>
    /// <param name="Item">Output parameter that will contain the found Item record.</param>
    /// <param name="TargetRecordRef">Primary record reference to search from.</param>
    /// <param name="Optional2Variant">Second optional variant to search.</param>
    /// <param name="Optional3Variant">Third optional variant to search.</param>
    /// <param name="Optional4Variant">Fourth optional variant to search.</param>
    /// <param name="Optional5Variant">Fifth optional variant to search.</param>
    /// <returns>True if an Item was found; False otherwise.</returns>
    internal procedure FindRelatedItem(var Item: Record Item; TargetRecordRef: RecordRef; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        exit(QltyTraversal.FindRelatedItem(Item, TargetRecordRef, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant));
    end;

    #endregion Qlty. Traversal Wrappers

    #region Qlty. Inspect. Source Config. Helpers

    /// <summary>
    /// Creates and inserts a source configuration record with randomized code and description.
    /// This helper procedure encapsulates the boilerplate code for creating source configurations.
    /// </summary>
    /// <param name="QltyInspectSourceConfig">The source configuration record to populate and insert (var parameter).</param>
    /// <param name="FromTableNo">The source table number.</param>
    /// <param name="ToType">The target type (Chained table, Inspection, or Item Tracking).</param>
    /// <param name="ToTableNo">The target table number.</param>
    internal procedure CreateSourceConfig(var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config."; FromTableNo: Integer; ToType: Enum "Qlty. Target Type"; ToTableNo: Integer)
    var
        ConfigCode: Text;
    begin
        QltyInspectSourceConfig.Init();
        GenerateRandomCharacters(MaxStrLen(QltyInspectSourceConfig.Code), ConfigCode);
        QltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(QltyInspectSourceConfig.Code));
        QltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(QltyInspectSourceConfig.Description));
        QltyInspectSourceConfig.Validate("From Table No.", FromTableNo);
        QltyInspectSourceConfig."To Type" := ToType;
        QltyInspectSourceConfig.Validate("To Table No.", ToTableNo);
        QltyInspectSourceConfig.Insert();
    end;

    #endregion Qlty. Inspect. Source Config. Helpers

    #region Qlty. Inspect. Src. Fld. Conf. Helpers

    /// <summary>
    /// Creates and inserts a source field configuration record.
    /// This helper procedure encapsulates the boilerplate code for creating field configurations,
    /// calling the internal InitLineNoIfNeeded procedure.
    /// </summary>
    /// <param name="SourceConfigCode">The code of the parent source configuration.</param>
    /// <param name="FromTableNo">The source table number.</param>
    /// <param name="FromFieldNo">The source field number.</param>
    /// <param name="ToType">The target type (Chained table, Inspection, or Item Tracking).</param>
    /// <param name="ToTableNo">The target table number.</param>
    /// <param name="ToFieldNo">The target field number.</param>
    internal procedure CreateSourceFieldConfig(SourceConfigCode: Code[20]; FromTableNo: Integer; FromFieldNo: Integer; ToType: Enum "Qlty. Target Type"; ToTableNo: Integer;
                                                                                                                          ToFieldNo: Integer)
    var
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
    begin
        Clear(QltyInspectSrcFldConf);
        QltyInspectSrcFldConf.Init();
        QltyInspectSrcFldConf.Code := SourceConfigCode;
        QltyInspectSrcFldConf.InitLineNoIfNeeded();
        QltyInspectSrcFldConf."From Table No." := FromTableNo;
        QltyInspectSrcFldConf."From Field No." := FromFieldNo;
        QltyInspectSrcFldConf."To Type" := ToType;
        QltyInspectSrcFldConf."To Table No." := ToTableNo;
        QltyInspectSrcFldConf."To Field No." := ToFieldNo;
        QltyInspectSrcFldConf.Insert();
    end;

    /// <summary>
    /// Creates and inserts a source field configuration record by resolving a field name.
    /// This overload is useful when the same field is used for both source and target (e.g., inspection-to-inspection mapping).
    /// </summary>
    /// <param name="SourceConfigCode">The code of the parent source configuration.</param>
    /// <param name="TableNo">The table number for both source and target (used for field name resolution).</param>
    /// <param name="ToType">The target type (Chained table, Inspection, or Item Tracking).</param>
    /// <param name="FieldName">The field name to resolve to a field number.</param>
    internal procedure CreateSourceFieldConfigByName(SourceConfigCode: Code[20]; TableNo: Integer; ToType: Enum "Qlty. Target Type"; FieldName: Text)
    var
        FieldRec: Record Field;
    begin
        FieldRec.SetRange(TableNo, TableNo);
        FieldRec.SetRange(FieldName, FieldName);
        FieldRec.FindFirst();
        CreateSourceFieldConfig(SourceConfigCode, TableNo, FieldRec."No.", ToType, TableNo, FieldRec."No.");
    end;

    #endregion Qlty. Inspect. Src. Fld. Conf. Helpers

    #region Qlty. Item Tracking Wrappers

    /// <summary>
    /// Wrapper for internal QltyItemTracking.IsItemTrackingUsed.
    /// Returns true if the item is either lot, serial, or package tracked.
    /// </summary>
    /// <param name="ItemNo">The item number to check.</param>
    /// <param name="TempItemTrackingSetup">Temporary item tracking setup record that will contain the tracking information.</param>
    /// <returns>True if item tracking is used for the item.</returns>
    internal procedure IsItemTrackingUsed(ItemNo: Code[20]; var TempItemTrackingSetup: Record "Item Tracking Setup" temporary): Boolean
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        exit(QltyItemTracking.IsItemTrackingUsed(ItemNo, TempItemTrackingSetup));
    end;

    /// <summary>
    /// Wrapper for internal QltyItemTrackingMgmt.DeleteAndRecreatePurchaseReturnOrderLineTracking.
    /// Deletes all Reservation Entries for the line and creates a single entry with the updated quantity.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header containing item tracking info.</param>
    /// <param name="ReturnOrderPurchaseLine">The purchase return order line.</param>
    /// <param name="QtyToReturn">The quantity to return.</param>
    internal procedure DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader: Record "Qlty. Inspection Header"; ReturnOrderPurchaseLine: Record "Purchase Line"; QtyToReturn: Decimal)
    var
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
    begin
        QltyItemTrackingMgmt.DeleteAndRecreatePurchaseReturnOrderLineTracking(QltyInspectionHeader, ReturnOrderPurchaseLine, QtyToReturn);
    end;

    #endregion Qlty. Item Tracking Wrappers

    #region Qlty. Management Setup Wrappers

    /// <summary>
    /// Wrapper for internal QltyManagementSetup.GetSetupVideoLink.
    /// Returns the setup video link from the management setup.
    /// </summary>
    /// <param name="QltyManagementSetup">The setup record to get the video link from.</param>
    /// <returns>The setup video link text.</returns>
    internal procedure GetSetupVideoLink(var QltyManagementSetup: Record "Qlty. Management Setup"): Text
    begin
        exit(QltyManagementSetup.GetSetupVideoLink());
    end;

    /// <summary>
    /// Wrapper for internal QltyManagementSetup.GetAppGuid.
    /// Returns the application GUID for the Quality Management app.
    /// </summary>
    /// <param name="QltyManagementSetup">The setup record.</param>
    /// <returns>The application GUID.</returns>
    internal procedure GetAppGuid(var QltyManagementSetup: Record "Qlty. Management Setup"): Guid
    begin
        exit(QltyManagementSetup.GetAppGuid());
    end;

    /// <summary>
    /// Wrapper for internal QltyManagementSetup.GetVersion.
    /// Returns the version text for the Quality Management app.
    /// </summary>
    /// <param name="QltyManagementSetup">The setup record.</param>
    /// <returns>The version text.</returns>
    internal procedure GetVersion(var QltyManagementSetup: Record "Qlty. Management Setup"): Text
    begin
        exit(QltyManagementSetup.GetVersion());
    end;

    #endregion Qlty. Management Setup Wrappers

    #region Qlty. Inspection - Create Wrappers

    /// <summary>
    /// Wrapper for internal QltyInspectionCreate.CreateMultipleInspectionsForMarkedTrackingSpecification.
    /// Use this with Marked records.
    /// </summary>
    /// <param name="TempTrackingSpecification">You must mark your records as a pre-requisite.</param>
    internal procedure CreateMultipleInspectionsForMarkedTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        QltyInspectionCreate.CreateMultipleInspectionsForMarkedTrackingSpecification(TempTrackingSpecification, false);
    end;

    /// <summary>
    /// Wrapper for internal QltyInspectionCreate.CreateMultipleInspectionsForMultipleRecords.
    /// Creates multiple inspections for a set of records.
    /// </summary>
    /// <param name="SetOfRecordsRecordRef">RecordRef containing the records to create inspections for.</param>
    /// <param name="IsManualCreation">Whether this is a manual creation (affects display behavior).</param>
    internal procedure CreateMultipleInspectionsForMultipleRecords(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean)
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        QltyInspectionCreate.CreateMultipleInspectionsForMultipleRecords(SetOfRecordsRecordRef, IsManualCreation);
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspection.
    /// Creates a quality inspection from a RecordRef using generation rule configuration.
    /// </summary>
    /// <param name="TargetRecordRef">The source record to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspection(TargetRecordRef: RecordRef; IsManualCreation: Boolean): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.CreateInspection(TargetRecordRef, IsManualCreation));
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspection with output inspection header.
    /// Creates a quality inspection and returns the created inspection.
    /// </summary>
    /// <param name="TargetRecordRef">The source record to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <param name="OutQltyInspectionHeader">Output: the created inspection header.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspection(TargetRecordRef: RecordRef; IsManualCreation: Boolean; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Result: Boolean;
    begin
        Result := QltyInspectionCreate.CreateInspection(TargetRecordRef, IsManualCreation);
        if Result then
            QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        exit(Result);
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithVariant.
    /// Creates a quality inspection from a variant using generation rule configuration.
    /// </summary>
    /// <param name="ReferenceVariant">The source record (Record, RecordRef, or RecordId) to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspectionWithVariant(ReferenceVariant: Variant; IsManualCreation: Boolean): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.CreateInspectionWithVariant(ReferenceVariant, IsManualCreation));
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithVariant with output inspection header.
    /// Creates a quality inspection from a variant and returns the created inspection.
    /// </summary>
    /// <param name="ReferenceVariant">The source record (Record, RecordRef, or RecordId) to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <param name="OutQltyInspectionHeader">Output: the created inspection header.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspectionWithVariant(ReferenceVariant: Variant; IsManualCreation: Boolean; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Result: Boolean;
    begin
        Result := QltyInspectionCreate.CreateInspectionWithVariant(ReferenceVariant, IsManualCreation);
        if Result then
            QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        exit(Result);
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithVariantAndTemplate.
    /// Creates a quality inspection from a variant using a specified template.
    /// </summary>
    /// <param name="ReferenceVariant">The source record to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use; empty string for rule-based selection.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspectionWithVariantAndTemplate(ReferenceVariant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.CreateInspectionWithVariantAndTemplate(ReferenceVariant, IsManualCreation, OptionalSpecificTemplate));
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithVariantAndTemplate with output inspection header.
    /// Creates a quality inspection from a variant using a specified template and returns the created inspection.
    /// </summary>
    /// <param name="ReferenceVariant">The source record to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use; empty string for rule-based selection.</param>
    /// <param name="OutQltyInspectionHeader">Output: the created inspection header.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspectionWithVariantAndTemplate(ReferenceVariant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Result: Boolean;
    begin
        Result := QltyInspectionCreate.CreateInspectionWithVariantAndTemplate(ReferenceVariant, IsManualCreation, OptionalSpecificTemplate);
        if Result then
            QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        exit(Result);
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithSpecificTemplate.
    /// Creates a quality inspection using a specified template.
    /// </summary>
    /// <param name="TargetRecordRef">The source record to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspectionWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.CreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate));
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithSpecificTemplate with output inspection header.
    /// Creates a quality inspection using a specified template and returns the created inspection.
    /// </summary>
    /// <param name="TargetRecordRef">The source record to create an inspection from.</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation.</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use.</param>
    /// <param name="OutQltyInspectionHeader">Output: the created inspection header.</param>
    /// <returns>True if inspection was successfully created.</returns>
    internal procedure CreateInspectionWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Result: Boolean;
    begin
        Result := QltyInspectionCreate.CreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate);
        if Result then
            QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        exit(Result);
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate.
    /// Creates an inspection using multiple variant records with a specified template.
    /// </summary>
    /// <param name="OptionalRec1Variant">First record variant to attempt inspection creation from.</param>
    /// <param name="OptionalRec2Variant">Second record variant.</param>
    /// <param name="OptionalRec3Variant">Third record variant.</param>
    /// <param name="OptionalRec4Variant">Fourth record variant.</param>
    /// <param name="IsManualCreation">True for manual creation; False for automatic/triggered creation.</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use; empty string for rule-based selection.</param>
    /// <returns>True if inspection was successfully created from any variant.</returns>
    internal procedure CreateInspectionWithMultiVariantsAndTemplate(OptionalRec1Variant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(OptionalRec1Variant, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, IsManualCreation, OptionalSpecificTemplate));
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate with output inspection header.
    /// Creates an inspection using multiple variant records with a specified template and returns the created inspection.
    /// </summary>
    /// <param name="OptionalRec1Variant">First record variant to attempt inspection creation from.</param>
    /// <param name="OptionalRec2Variant">Second record variant.</param>
    /// <param name="OptionalRec3Variant">Third record variant.</param>
    /// <param name="OptionalRec4Variant">Fourth record variant.</param>
    /// <param name="IsManualCreation">True for manual creation; False for automatic/triggered creation.</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use; empty string for rule-based selection.</param>
    /// <param name="OutQltyInspectionHeader">Output: the created inspection header.</param>
    /// <returns>True if inspection was successfully created from any variant.</returns>
    internal procedure CreateInspectionWithMultiVariantsAndTemplate(OptionalRec1Variant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Result: Boolean;
    begin
        Result := QltyInspectionCreate.CreateInspectionWithMultiVariantsAndTemplate(OptionalRec1Variant, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, IsManualCreation, OptionalSpecificTemplate);
        if Result then
            QltyInspectionCreate.GetCreatedInspection(OutQltyInspectionHeader);
        exit(Result);
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.CreateReinspection.
    /// Creates a re-inspection from an existing inspection.
    /// </summary>
    /// <param name="QltyInspectionHeader">The existing inspection to create a re-inspection from.</param>
    /// <param name="OutReQltyInspectionHeader">Output: the created re-inspection header.</param>
    internal procedure CreateReinspection(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var OutReQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        QltyInspectionCreate.CreateReinspection(QltyInspectionHeader, OutReQltyInspectionHeader);
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.FindExistingInspectionWithVariant (simple overload).
    /// Finds an existing inspection matching the given variant.
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">If true, raises an error when no matching rule is found.</param>
    /// <param name="ReferenceVariant">The source record to find an inspection for.</param>
    /// <param name="OutQltyInspectionHeader">Output: the found inspection header.</param>
    /// <returns>True if an existing inspection was found.</returns>
    internal procedure FindExistingInspectionWithVariant(RaiseErrorIfNoRuleIsFound: Boolean; ReferenceVariant: Variant; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.FindExistingInspectionWithVariant(RaiseErrorIfNoRuleIsFound, ReferenceVariant, OutQltyInspectionHeader));
    end;

    /// <summary>
    /// Wrapper for QltyInspectionCreate.FindExistingInspectionWithVariant (with TempQltyInspectionGenRule).
    /// Finds existing inspections with generation rule filtering.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record.</param>
    /// <param name="OptionalVariant2">Optional second variant.</param>
    /// <param name="OptionalVariant3">Optional third variant.</param>
    /// <param name="OptionalVariant4">Optional fourth variant.</param>
    /// <param name="TempQltyInspectionGenRule">Temporary generation rule for filtering.</param>
    /// <param name="OutQltyInspectionHeader">Output: the found inspection header.</param>
    /// <param name="FindAll">If true, finds all matching inspections.</param>
    /// <returns>True if an existing inspection was found.</returns>
    internal procedure FindExistingInspectionWithVariant(TargetRecordRef: RecordRef; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant; TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var OutQltyInspectionHeader: Record "Qlty. Inspection Header"; FindAll: Boolean): Boolean
    var
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
    begin
        exit(QltyInspectionCreate.FindExistingInspectionWithVariant(TargetRecordRef, OptionalVariant2, OptionalVariant3, OptionalVariant4, TempQltyInspectionGenRule, OutQltyInspectionHeader, FindAll));
    end;

    #endregion Qlty. Inspection - Create Wrappers

    #region Qlty. Disposition Wrappers

    /// <summary>
    /// Wrapper for internal QltyDispPurchaseReturn.PerformDisposition (7-argument version) and GetCreatedPurchaseReturnBuffer.
    /// Performs disposition and returns the created purchase return buffer.
    /// </summary>
    internal procedure PerformPurchaseReturnDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSpecificQuantity: Decimal;
                                                                                                                                     OptionalSourceLocationFilter: Text;
                                                                                                                                     OptionalSourceBinFilter: Text;
                                                                                                                                     ReasonCode: Code[10];
                                                                                                                                     ExternalDocumentNo: Code[35]; var TempCreatedBufferPurchaseHeader: Record "Purchase Header" temporary): Boolean
    var
        QltyDispPurchaseReturn: Codeunit "Qlty. Disp. Purchase Return";
        Result: Boolean;
    begin
        Result := QltyDispPurchaseReturn.PerformDisposition(QltyInspectionHeader, QltyQuantityBehavior, OptionalSpecificQuantity, OptionalSourceLocationFilter, OptionalSourceBinFilter, ReasonCode, ExternalDocumentNo);
        QltyDispPurchaseReturn.GetCreatedPurchaseReturnBuffer(TempCreatedBufferPurchaseHeader);
        exit(Result);
    end;

    /// <summary>
    /// Wrapper for internal QltyDispNegAdjustInv.PerformDisposition (7-argument version).
    /// </summary>
    internal procedure PerformNegAdjustInvDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSourceLocationFilter: Text;
                                                                                                                                                                      OptionalSourceBinFilter: Text;
                                                                                                                                                                      PostingBehavior: Enum "Qlty. Item Adj. Post Behavior";
                                                                                                                                                                      Reason: Code[10]): Boolean
    var
        QltyDispNegAdjustInv: Codeunit "Qlty. Disp. Neg. Adjust Inv.";
    begin
        exit(QltyDispNegAdjustInv.PerformDisposition(QltyInspectionHeader, OptionalSpecificQuantity, QltyQuantityBehavior, OptionalSourceLocationFilter, OptionalSourceBinFilter, PostingBehavior, Reason));
    end;

    /// <summary>
    /// Wrapper for internal QltyDispTransfer.PerformDisposition (7-argument version).
    /// </summary>
    internal procedure PerformTransferDisposition(QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSourceLocationFilter: Text;
                                                                                                                                                              OptionalSourceBinFilter: Text;
                                                                                                                                                              DestinationLocationCode: Code[10];
                                                                                                                                                              OptionalInTransitLocationCode: Code[10]): Boolean
    var
        QltyDispTransfer: Codeunit "Qlty. Disp. Transfer";
    begin
        exit(QltyDispTransfer.PerformDisposition(QltyInspectionHeader, OptionalSpecificQuantity, QltyQuantityBehavior, OptionalSourceLocationFilter, OptionalSourceBinFilter, DestinationLocationCode, OptionalInTransitLocationCode));
    end;

    /// <summary>
    /// Wrapper for internal QltyDispMoveAutoChoose.MoveInventory.
    /// </summary>
    internal procedure MoveInventory(QltyInspectionHeader: Record "Qlty. Inspection Header"; TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; UseMovement: Boolean): Boolean
    var
        QltyDispMoveAutoChoose: Codeunit "Qlty. Disp. Move Auto Choose";
    begin
        exit(QltyDispMoveAutoChoose.MoveInventory(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, UseMovement));
    end;

    /// <summary>
    /// Wrapper for internal QltyDispInternalPutAway.PerformDisposition (6-argument version).
    /// </summary>
    internal procedure PerformInternalPutAwayDisposition(QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; ReleaseImmediately: Boolean; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"): Boolean
    var
        QltyDispInternalPutAway: Codeunit "Qlty. Disp. Internal Put-away";
    begin
        exit(QltyDispInternalPutAway.PerformDisposition(QltyInspectionHeader, OptionalSpecificQuantity, OptionalSourceLocationFilter, OptionalSourceBinFilter, ReleaseImmediately, QltyQuantityBehavior));
    end;

    /// <summary>
    /// Wrapper for internal QltyDispWarehousePutAway.PerformDisposition (5-argument version).
    /// </summary>
    internal procedure PerformWarehousePutAwayDisposition(QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"): Boolean
    var
        QltyDispWarehousePutAway: Codeunit "Qlty. Disp. Warehouse Put-away";
    begin
        exit(QltyDispWarehousePutAway.PerformDisposition(QltyInspectionHeader, OptionalSpecificQuantity, OptionalSourceLocationFilter, OptionalSourceBinFilter, QltyQuantityBehavior));
    end;

    /// <summary>
    /// Wrapper for internal QltyAutoConfigure.EnsureAtLeastOneSourceConfigurationExist.
    /// </summary>
    internal procedure EnsureAtLeastOneSourceConfigurationExist(ForceAll: Boolean)
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        QltyAutoConfigure.EnsureAtLeastOneSourceConfigurationExist(ForceAll);
    end;

    /// <summary>
    /// Wrapper for internal QltyInspectionHeader.IsItemTrackingUsed (no parameters).
    /// </summary>
    internal procedure IsInspectionItemTrackingUsed(QltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    begin
        exit(QltyInspectionHeader.IsItemTrackingUsed());
    end;

    #endregion Qlty. Disposition Wrappers

    #region Qlty. Filter Helpers Wrappers

    /// <summary>
    /// Wrapper for internal QltyFilterHelpers.BuildFilter.
    /// </summary>
    internal procedure BuildFilter(TableNo: Integer; IncludeWhereText: Boolean; var Value: Text): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.BuildFilter(TableNo, IncludeWhereText, Value));
    end;

    /// <summary>
    /// Wrapper for internal QltyFilterHelpers.BuildItemAttributeFilter.
    /// </summary>
    internal procedure BuildItemAttributeFilter(var ItemAttributeFilter: Text)
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        QltyFilterHelpers.BuildItemAttributeFilter(ItemAttributeFilter);
    end;

    #endregion Qlty. Filter Helpers Wrappers

    #region Qlty. Inspec. Gen. Rule Mgmt. Wrappers

    /// <summary>
    /// Wrapper for internal QltyInspecGenRuleMgmt.SetFilterToApplicableTemplates.
    /// Sets the filter on the target configuration to sources that could match the supplied template.
    /// </summary>
    internal procedure SetFilterToApplicableTemplates(TemplateCode: Code[20]; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.")
    var
        QltyInspecGenRuleMgmt: Codeunit "Qlty. Inspec. Gen. Rule Mgmt.";
    begin
        QltyInspecGenRuleMgmt.SetFilterToApplicableTemplates(TemplateCode, QltyInspectSourceConfig);
    end;

    /// <summary>
    /// Wrapper for internal QltyInspecGenRuleMgmt.GetFilterForAvailableConfigurations.
    /// Returns the filter for available source configurations.
    /// </summary>
    internal procedure GetFilterForAvailableConfigurations(): Text
    var
        QltyInspecGenRuleMgmt: Codeunit "Qlty. Inspec. Gen. Rule Mgmt.";
    begin
        exit(QltyInspecGenRuleMgmt.GetFilterForAvailableConfigurations());
    end;

    /// <summary>
    /// Wrapper for internal QltyInspectionGenRule.SetEntryNo.
    /// Sets the entry number for the generation rule record.
    /// </summary>
    internal procedure SetEntryNo(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    begin
        QltyInspectionGenRule.SetEntryNo();
    end;

    #endregion Qlty. Inspec. Gen. Rule Mgmt. Wrappers

    #region Qlty. Inspection Header Wrappers

    /// <summary>
    /// Wrapper for internal QltyInspectionHeader.GetReferenceRecordId.
    /// Returns the reference record ID (SystemId) from the inspection header.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header record.</param>
    /// <returns>The reference record's SystemId.</returns>
    internal procedure GetReferenceRecordId(var QltyInspectionHeader: Record "Qlty. Inspection Header"): Guid
    begin
        exit(QltyInspectionHeader.GetReferenceRecordId());
    end;

    /// <summary>
    /// Wrapper for internal QltyInspectionHeader.VerifyTrackingBeforeFinish.
    /// Verifies that item tracking (lot/serial/package) is properly set before finishing an inspection.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header record.</param>
    internal procedure VerifyTrackingBeforeFinish(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        QltyInspectionHeader.VerifyTrackingBeforeFinish();
    end;

    /// <summary>
    /// Wrapper for internal QltyInspectionHeader.DetermineControlInformation.
    /// Determines the control information for a custom field.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header record.</param>
    /// <param name="Input">The input text (field name).</param>
    internal procedure DetermineControlInformation(var QltyInspectionHeader: Record "Qlty. Inspection Header"; Input: Text)
    begin
        QltyInspectionHeader.DetermineControlInformation(Input);
    end;

    /// <summary>
    /// Wrapper for internal QltyInspectionHeader.GetControlCaptionClass.
    /// Gets the caption class for a custom control field.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header record.</param>
    /// <param name="Input">The input text (field name).</param>
    /// <returns>The caption text.</returns>
    internal procedure GetControlCaptionClass(var QltyInspectionHeader: Record "Qlty. Inspection Header"; Input: Text): Text
    begin
        exit(QltyInspectionHeader.GetControlCaptionClass(Input));
    end;

    /// <summary>
    /// Wrapper for internal QltyInspectionHeader.GetControlVisibleState.
    /// Gets the visibility state for a custom control field.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection header record.</param>
    /// <param name="Input">The input text (field name).</param>
    /// <returns>True if the control should be visible.</returns>
    internal procedure GetControlVisibleState(var QltyInspectionHeader: Record "Qlty. Inspection Header"; Input: Text): Boolean
    begin
        exit(QltyInspectionHeader.GetControlVisibleState(Input));
    end;

    #endregion Qlty. Inspection Header Wrappers

    #region Qlty. Test Wrappers

    /// <summary>
    /// Wrapper for internal QltyTest.SuggestUnusedTestCodeFromDescription.
    /// Suggests an unused test code based on the provided description.
    /// </summary>
    /// <param name="QltyTest">The test record.</param>
    /// <param name="InputDescription">The description to generate a code from.</param>
    /// <param name="SuggestionCode">The suggested test code (output).</param>
    internal procedure SuggestUnusedTestCodeFromDescription(var QltyTest: Record "Qlty. Test"; InputDescription: Text; var SuggestionCode: Code[20])
    begin
        QltyTest.SuggestUnusedTestCodeFromDescription(InputDescription, SuggestionCode);
    end;

    #endregion Qlty. Test Wrappers

    #region Qlty. Misc Helpers Wrappers

    /// <summary>
    /// Wrapper for internal QltyMiscHelpers.IsNumericText.
    /// Checks if the input text represents a numeric value.
    /// </summary>
    /// <param name="Input">The text to check.</param>
    /// <returns>True if the text is numeric.</returns>
    internal procedure IsNumericText(Input: Text): Boolean
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        exit(QltyMiscHelpers.IsNumericText(Input));
    end;

    /// <summary>
    /// Wrapper for QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax.
    /// Attempts to parse a text range (e.g., "1..10") into min and max decimal values.
    /// </summary>
    /// <param name="InputText">The text containing a range in format "minValue..maxValue".</param>
    /// <param name="MinValueInRange">Output: The minimum value from the range.</param>
    /// <param name="MaxValueInRange">Output: The maximum value from the range.</param>
    /// <returns>True if successfully parsed as a simple range.</returns>
    internal procedure AttemptSplitSimpleRangeIntoMinMax(InputText: Text; var MinValueInRange: Decimal; var MaxValueInRange: Decimal): Boolean
    var
        QltyValueParsing: Codeunit "Qlty. Value Parsing";
    begin
        exit(QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax(InputText, MinValueInRange, MaxValueInRange));
    end;

    /// <summary>
    /// Wrapper for QltyConfigurationHelpers.GetArbitraryMaximumRecursion.
    /// Returns the maximum recursion depth limit for traversing multi-level table relationships.
    /// </summary>
    /// <returns>The maximum recursion depth allowed (currently 20 levels).</returns>
    internal procedure GetArbitraryMaximumRecursion(): Integer
    var
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
    begin
        exit(QltyConfigurationHelpers.GetArbitraryMaximumRecursion());
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.GetCSVOfValuesFromRecord (internal overload).
    /// Generates a CSV string of values for a specific field from a table with optional filtering.
    /// Uses system-defined maximum recursion limit for record count.
    /// </summary>
    /// <param name="CurrentTable">The table number to retrieve records from.</param>
    /// <param name="ChoiceField">The field number whose values should be extracted.</param>
    /// <param name="TableFilter">Optional filter to apply to the table (AL filter syntax).</param>
    /// <returns>Comma-separated string of field values (up to system maximum records).</returns>
    internal procedure GetCSVOfValuesFromRecord(CurrentTable: Integer; ChoiceField: Integer; TableFilter: Text): Text
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        exit(QltyMiscHelpers.GetCSVOfValuesFromRecord(CurrentTable, ChoiceField, TableFilter, GetArbitraryMaximumRecursion()));
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.GetRecordsForTableField (internal overload).
    /// Retrieves lookup values for a quality field with context-sensitive filtering.
    /// </summary>
    /// <param name="QltyTest">The quality field configuration defining lookup table and filters.</param>
    /// <param name="OptionalContextQltyInspectionHeader">Inspection header providing context for filter expression evaluation.</param>
    /// <param name="TempBufferQltyTestLookupValue">Output: Temporary buffer populated with lookup values.</param>
    internal procedure GetRecordsForTableField(var QltyTest: Record "Qlty. Test"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        QltyMiscHelpers.GetRecordsForTableField(QltyTest, OptionalContextQltyInspectionHeader, TempBufferQltyTestLookupValue);
    end;

    /// <summary>
    /// Wrapper for QltyConfigurationHelpers.GetDefaultMaximumRowsFieldLookup.
    /// Returns the configured maximum rows for field lookups from Quality Management Setup.
    /// </summary>
    /// <returns>Maximum rows to fetch for field lookups (default 100 if not configured).</returns>
    internal procedure GetDefaultMaximumRowsFieldLookup(): Integer
    var
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
    begin
        exit(QltyConfigurationHelpers.GetDefaultMaximumRowsFieldLookup());
    end;

    /// <summary>
    /// Wrapper for QltyDocumentNavigation.NavigateToSourceDocument.
    /// Opens the source document associated with a quality inspection in its appropriate page.
    /// Automatically determines the correct page to display based on the source record type.
    /// </summary>
    /// <param name="QltyInspectionHeader">The Inspection whose source document should be displayed.</param>
    internal procedure NavigateToSourceDocument(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyDocumentNavigation: Codeunit "Qlty. Document Navigation";
    begin
        QltyDocumentNavigation.NavigateToSourceDocument(QltyInspectionHeader);
    end;

    /// <summary>
    /// Wrapper for QltyDocumentNavigation.NavigateToFindEntries.
    /// Opens the Navigate page to find all related entries for an Inspection's source document.
    /// Pre-fills search criteria with test source information including item, document number, and tracking.
    /// </summary>
    /// <param name="QltyInspectionHeader">The Inspection whose related entries should be found.</param>
    internal procedure NavigateToFindEntries(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyDocumentNavigation: Codeunit "Qlty. Document Navigation";
    begin
        QltyDocumentNavigation.NavigateToFindEntries(QltyInspectionHeader);
    end;

    #endregion Qlty. Misc Helpers Wrappers

    #region Qlty. Filter Helpers Wrappers

    /// <summary>
    /// Wrapper for QltyFilterHelpers.IdentifyTableIDFromText.
    /// Identifies a table ID from a text reference (table number, name, or caption).
    /// </summary>
    /// <param name="CurrentTable">Input/Output: Table reference as text; updated to Object Name if found</param>
    /// <returns>The table ID if found; 0 if table cannot be identified</returns>
    internal procedure IdentifyTableIDFromText(var CurrentTable: Text): Integer
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.IdentifyTableIDFromText(CurrentTable));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.IdentifyFieldIDFromText.
    /// Identifies a field ID from a text reference (field number, name, or caption).
    /// </summary>
    /// <param name="CurrentTable">The table ID containing the field</param>
    /// <param name="NumberOrNameOfField">Input/Output: Field reference as text; updated to Field Name if found</param>
    /// <returns>The field ID if found; 0 if field cannot be identified</returns>
    internal procedure IdentifyFieldIDFromText(CurrentTable: Integer; var NumberOrNameOfField: Text): Integer
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.IdentifyFieldIDFromText(CurrentTable, NumberOrNameOfField));
    end;

    #endregion Qlty. Filter Helpers Wrappers

    #region Qlty. Localization Wrappers

    /// <summary>
    /// Wrapper for QltyLocalization.GetTranslatedYes.
    /// Returns the translatable "Yes" label with maximum length of 250 characters.
    /// </summary>
    /// <returns>The localized "Yes" text (up to 250 characters)</returns>
    internal procedure GetTranslatedYes250(): Text[250]
    var
        QltyLocalization: Codeunit "Qlty. Localization";
    begin
        exit(QltyLocalization.GetTranslatedYes());
    end;

    /// <summary>
    /// Wrapper for QltyLocalization.GetTranslatedNo.
    /// Returns the translatable "No" label with maximum length of 250 characters.
    /// </summary>
    /// <returns>The localized "No" text (up to 250 characters)</returns>
    internal procedure GetTranslatedNo250(): Text[250]
    var
        QltyLocalization: Codeunit "Qlty. Localization";
    begin
        exit(QltyLocalization.GetTranslatedNo());
    end;

    #endregion Qlty. Localization Wrappers

    #region Qlty. Misc Helpers Additional Wrappers

    /// <summary>
    /// Wrapper for QltyBooleanParsing.GetBooleanFor.
    /// Converts text input to a boolean value using flexible interpretation rules.
    /// </summary>
    /// <param name="Input">The text value to convert to boolean</param>
    /// <returns>True if input matches any positive boolean representation; False otherwise</returns>
    internal procedure GetBooleanFor(Input: Text): Boolean
    var
        QltyBooleanParsing: Codeunit "Qlty. Boolean Parsing";
    begin
        exit(QltyBooleanParsing.GetBooleanFor(Input));
    end;

    /// <summary>
    /// Wrapper for QltyBooleanParsing.IsTextValuePositiveBoolean.
    /// Checks if a text value represents a "positive" or "true-ish" boolean value.
    /// </summary>
    /// <param name="ValueToCheckIfPositiveBoolean">The text value to check</param>
    /// <returns>True if the value represents a positive/affirmative boolean; False otherwise</returns>
    internal procedure IsTextValuePositiveBoolean(ValueToCheckIfPositiveBoolean: Text): Boolean
    var
        QltyBooleanParsing: Codeunit "Qlty. Boolean Parsing";
    begin
        exit(QltyBooleanParsing.IsTextValuePositiveBoolean(ValueToCheckIfPositiveBoolean));
    end;

    /// <summary>
    /// Wrapper for QltyBooleanParsing.IsTextValueNegativeBoolean.
    /// Checks if text represents a negative/false boolean value.
    /// </summary>
    /// <param name="ValueToCheckIfNegativeBoolean">The text value to check</param>
    /// <returns>True if text represents a negative boolean value; False otherwise</returns>
    internal procedure IsTextValueNegativeBoolean(ValueToCheckIfNegativeBoolean: Text): Boolean
    var
        QltyBooleanParsing: Codeunit "Qlty. Boolean Parsing";
    begin
        exit(QltyBooleanParsing.IsTextValueNegativeBoolean(ValueToCheckIfNegativeBoolean));
    end;

    /// <summary>
    /// Wrapper for QltyPersonLookup.GetBasicPersonDetails.
    /// Retrieves basic person details from various person-related tables.
    /// </summary>
    /// <param name="Input">The primary key value to search for</param>
    /// <param name="FullName">Output: The person's full name</param>
    /// <param name="JobTitle">Output: The person's job title</param>
    /// <param name="EmailAddress">Output: The person's email address</param>
    /// <param name="PhoneNo">Output: The person's phone number</param>
    /// <param name="SourceRecordId">Output: RecordId of the source record</param>
    /// <returns>True if person details were found; False otherwise</returns>
    internal procedure GetBasicPersonDetails(Input: Text; var FullName: Text; var JobTitle: Text; var EmailAddress: Text; var PhoneNo: Text; var SourceRecordId: RecordId): Boolean
    var
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
    begin
        exit(QltyPersonLookup.GetBasicPersonDetails(Input, FullName, JobTitle, EmailAddress, PhoneNo, SourceRecordId));
    end;

    /// <summary>
    /// Wrapper for QltyPersonLookup.GetBasicPersonDetailsFromInspectionLine.
    /// Retrieves person details based on the value in an inspection line's table lookup field.
    /// </summary>
    /// <param name="QltyInspectionLine">The inspection line containing the person reference</param>
    /// <param name="FullName">Output: The person's full name</param>
    /// <param name="JobTitle">Output: The person's job title</param>
    /// <param name="EmailAddress">Output: The person's email address</param>
    /// <param name="PhoneNo">Output: The person's phone number</param>
    /// <param name="SourceRecordId">Output: RecordId of the source person record</param>
    /// <returns>True if details were retrieved; False otherwise</returns>
    internal procedure GetBasicPersonDetailsFromInspectionLine(QltyInspectionLine: Record "Qlty. Inspection Line"; var FullName: Text; var JobTitle: Text; var EmailAddress: Text; var PhoneNo: Text; var SourceRecordId: RecordId): Boolean
    var
        QltyPersonLookup: Codeunit "Qlty. Person Lookup";
    begin
        exit(QltyPersonLookup.GetBasicPersonDetailsFromInspectionLine(QltyInspectionLine, FullName, JobTitle, EmailAddress, PhoneNo, SourceRecordId));
    end;

    #endregion Qlty. Misc Helpers Additional Wrappers

    #region Qlty. Traversal Wrappers

    /// <summary>
    /// Wrapper for QltyTraversal.FindRelatedVendor - searches for a related Vendor record.
    /// </summary>
    internal procedure FindRelatedVendor(var Vendor: Record Vendor; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        exit(QltyTraversal.FindRelatedVendor(Vendor, Optional1Variant, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant));
    end;

    /// <summary>
    /// Wrapper for QltyTraversal.FindRelatedCustomer - searches for a related Customer record.
    /// </summary>
    internal procedure FindRelatedCustomer(var Customer: Record Customer; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        exit(QltyTraversal.FindRelatedCustomer(Customer, Optional1Variant, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant));
    end;

    /// <summary>
    /// Wrapper for QltyTraversal.FindRelatedRouting - searches for a related Routing Header record.
    /// </summary>
    internal procedure FindRelatedRouting(var RoutingHeader: Record "Routing Header"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        exit(QltyTraversal.FindRelatedRouting(RoutingHeader, Optional1Variant, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant));
    end;

    /// <summary>
    /// Wrapper for QltyTraversal.FindRelatedBillOfMaterial - searches for a related Production BOM Header record.
    /// </summary>
    internal procedure FindRelatedBillOfMaterial(var ProductionBOMHeader: Record "Production BOM Header"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        exit(QltyTraversal.FindRelatedBillOfMaterial(ProductionBOMHeader, Optional1Variant, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant));
    end;

    /// <summary>
    /// Wrapper for QltyTraversal.FindRelatedProdOrderRoutingLine - searches for a related Production Order Routing Line record.
    /// </summary>
    internal procedure FindRelatedProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        QltyTraversal: Codeunit "Qlty. Traversal";
    begin
        exit(QltyTraversal.FindRelatedProdOrderRoutingLine(ProdOrderRoutingLine, Optional1Variant, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant));
    end;

    #endregion Qlty. Traversal Wrappers

    #region Qlty. Permission Mgmt. Wrappers

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanCreateManualInspection
    /// </summary>
    internal procedure VerifyCanCreateManualInspection()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanCreateManualInspection();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanCreateReinspection
    /// </summary>
    internal procedure VerifyCanCreateReinspection()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanCreateReinspection();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanDeleteOpenInspection
    /// </summary>
    internal procedure VerifyCanDeleteOpenInspection()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanDeleteOpenInspection();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanDeleteFinishedInspection
    /// </summary>
    internal procedure VerifyCanDeleteFinishedInspection()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanDeleteFinishedInspection();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.CanDeleteFinishedInspection
    /// </summary>
    internal procedure CanDeleteFinishedInspection(): Boolean
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        exit(QltyPermissionMgmt.CanDeleteFinishedInspection());
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanChangeOtherInspections
    /// </summary>
    internal procedure VerifyCanChangeOtherInspections()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanChangeOtherInspections();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.CanChangeOtherInspections
    /// </summary>
    internal procedure CanChangeOtherInspections(): Boolean
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        exit(QltyPermissionMgmt.CanChangeOtherInspections());
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanReopenInspection
    /// </summary>
    internal procedure VerifyCanReopenInspection()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanReopenInspection();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanFinishInspection
    /// </summary>
    internal procedure VerifyCanFinishInspection()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanFinishInspection();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.CanFinishInspection
    /// </summary>
    internal procedure CanFinishInspection(): Boolean
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        exit(QltyPermissionMgmt.CanFinishInspection());
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanChangeItemTracking
    /// </summary>
    internal procedure VerifyCanChangeItemTracking()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanChangeItemTracking();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.CanChangeItemTracking
    /// </summary>
    internal procedure CanChangeItemTracking(): Boolean
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        exit(QltyPermissionMgmt.CanChangeItemTracking());
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.VerifyCanChangeSourceQuantity
    /// </summary>
    internal procedure VerifyCanChangeSourceQuantity()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        QltyPermissionMgmt.VerifyCanChangeSourceQuantity();
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.CanChangeSourceQuantity
    /// </summary>
    internal procedure CanChangeSourceQuantity(): Boolean
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        exit(QltyPermissionMgmt.CanChangeSourceQuantity());
    end;

    /// <summary>
    /// Wrapper for QltyPermissionMgmt.CanEditLineComments
    /// </summary>
    internal procedure CanEditLineComments(): Boolean
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        exit(QltyPermissionMgmt.CanEditLineComments());
    end;

    #endregion Qlty. Permission Mgmt. Wrappers

    #region Qlty. Workflow Setup Wrappers

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetInspectionFinishedEvent
    /// </summary>
    internal procedure GetInspectionFinishedEvent(): Code[128]
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetInspectionFinishedEvent());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetInspectionReopenedEvent
    /// </summary>
    internal procedure GetInspectionReopenedEvent(): Code[128]
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetInspectionReopenedEvent());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetInspectionHasChangedEvent
    /// </summary>
    internal procedure GetInspectionHasChangedEvent(): Code[128]
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetInspectionHasChangedEvent());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseCreatePurchaseReturn
    /// </summary>
    internal procedure GetWorkflowResponseCreatePurchaseReturn(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseCreatePurchaseReturn());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseCreateInspection
    /// </summary>
    internal procedure GetWorkflowResponseCreateInspection(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseCreateInspection());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseInternalPutAway
    /// </summary>
    internal procedure GetWorkflowResponseInternalPutAway(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseInternalPutAway());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseInventoryAdjustment
    /// </summary>
    internal procedure GetWorkflowResponseInventoryAdjustment(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseInventoryAdjustment());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseCreateTransfer
    /// </summary>
    internal procedure GetWorkflowResponseCreateTransfer(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseCreateTransfer());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseMoveInventory
    /// </summary>
    internal procedure GetWorkflowResponseMoveInventory(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseMoveInventory());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseFinishInspection
    /// </summary>
    internal procedure GetWorkflowResponseFinishInspection(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseFinishInspection());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseReopenInspection
    /// </summary>
    internal procedure GetWorkflowResponseReopenInspection(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseReopenInspection());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseCreateReinspection
    /// </summary>
    internal procedure GetWorkflowResponseCreateReinspection(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseCreateReinspection());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseSetDatabaseValue
    /// </summary>
    internal procedure GetWorkflowResponseSetDatabaseValue(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseSetDatabaseValue());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseChangeItemTracking
    /// </summary>
    internal procedure GetWorkflowResponseChangeItemTracking(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseChangeItemTracking());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseBlockLot
    /// </summary>
    internal procedure GetWorkflowResponseBlockLot(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseBlockLot());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseUnblockLot
    /// </summary>
    internal procedure GetWorkflowResponseUnblockLot(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseUnblockLot());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseBlockSerial
    /// </summary>
    internal procedure GetWorkflowResponseBlockSerial(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseBlockSerial());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseUnblockSerial
    /// </summary>
    internal procedure GetWorkflowResponseUnblockSerial(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseUnblockSerial());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseBlockPackage
    /// </summary>
    internal procedure GetWorkflowResponseBlockPackage(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseBlockPackage());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowSetup.GetWorkflowResponseUnblockPackage
    /// </summary>
    internal procedure GetWorkflowResponseUnblockPackage(): Text
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        exit(QltyWorkflowSetup.GetWorkflowResponseUnblockPackage());
    end;

    #endregion Qlty. Workflow Setup Wrappers

    #region Qlty. Workflow Response Wrappers

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum
    /// </summary>
    internal procedure SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior")
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, CurrentKey, QltyQuantityBehavior);
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.SetStepConfigurationValueAsDecimal
    /// </summary>
    internal procedure SetStepConfigurationValueAsDecimal(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; Value: Decimal)
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(WorkflowStepArgument, CurrentKey, Value);
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.SetStepConfigurationValue
    /// </summary>
    internal procedure SetStepConfigurationValue(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; Value: Text)
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyWorkflowResponse.SetStepConfigurationValue(WorkflowStepArgument, CurrentKey, Value);
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.SetStepConfigurationValueAsBoolean
    /// </summary>
    internal procedure SetStepConfigurationValueAsBoolean(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; Value: Boolean)
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(WorkflowStepArgument, CurrentKey, Value);
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownMoveAll
    /// </summary>
    internal procedure GetWellKnownMoveAll(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownMoveAll());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownKeyQuantity
    /// </summary>
    internal procedure GetWellKnownKeyQuantity(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownKeyQuantity());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownExternalDocNo
    /// </summary>
    internal procedure GetWellKnownExternalDocNo(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownExternalDocNo());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownReasonCode
    /// </summary>
    internal procedure GetWellKnownReasonCode(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownReasonCode());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownCreatePutAway
    /// </summary>
    internal procedure GetWellKnownCreatePutAway(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownCreatePutAway());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownPostImmediately
    /// </summary>
    internal procedure GetWellKnownPostImmediately(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownPostImmediately());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownAdjPostingBehavior
    /// </summary>
    internal procedure GetWellKnownAdjPostingBehavior(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownAdjPostingBehavior());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownKeyLocation
    /// </summary>
    internal procedure GetWellKnownKeyLocation(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownKeyLocation());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownDirectTransfer
    /// </summary>
    internal procedure GetWellKnownDirectTransfer(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownDirectTransfer());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetStepConfigurationValue
    /// </summary>
    internal procedure GetStepConfigurationValue(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetStepConfigurationValue(WorkflowStepArgument, CurrentKey));
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownKeyBin
    /// </summary>
    internal procedure GetWellKnownKeyBin(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownKeyBin());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.SetStepConfigurationValueAsAdjPostingEnum
    /// </summary>
    internal procedure SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior")
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyWorkflowResponse.SetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, CurrentKey, QltyItemAdjPostBehavior);
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.SetStepConfigurationValueAsDate
    /// </summary>
    internal procedure SetStepConfigurationValueAsDate(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text; DateValue: Date)
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyWorkflowResponse.SetStepConfigurationValueAsDate(WorkflowStepArgument, CurrentKey, DateValue);
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetStepConfigurationValueAsQuantityBehaviorEnum
    /// </summary>
    internal procedure GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text): Enum "Qlty. Quantity Behavior"
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetStepConfigurationValueAsQuantityBehaviorEnum(WorkflowStepArgument, CurrentKey));
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetStepConfigurationValueAsAdjPostingEnum
    /// </summary>
    internal procedure GetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument: Record "Workflow Step Argument"; CurrentKey: Text): Enum "Qlty. Item Adj. Post Behavior"
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetStepConfigurationValueAsAdjPostingEnum(WorkflowStepArgument, CurrentKey));
    end;

    #endregion Qlty. Workflow Response Wrappers

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownSourceLocationFilter
    /// </summary>
    internal procedure GetWellKnownSourceLocationFilter(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownSourceLocationFilter());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownSourceBinFilter
    /// </summary>
    internal procedure GetWellKnownSourceBinFilter(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownSourceBinFilter());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownKeyField
    /// </summary>
    internal procedure GetWellKnownKeyField(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownKeyField());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownKeyValueExpression
    /// </summary>
    internal procedure GetWellKnownKeyValueExpression(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownKeyValueExpression());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownKeyDatabaseTable
    /// </summary>
    internal procedure GetWellKnownKeyDatabaseTable(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownKeyDatabaseTable());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownKeyDatabaseTableFilter
    /// </summary>
    internal procedure GetWellKnownKeyDatabaseTableFilter(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownKeyDatabaseTableFilter());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownUseMoveSheet
    /// </summary>
    internal procedure GetWellKnownUseMoveSheet(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownUseMoveSheet());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownNewLotNo
    /// </summary>
    internal procedure GetWellKnownNewLotNo(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownNewLotNo());
    end;

    /// <summary>
    /// Wrapper for QltyWorkflowResponse.GetWellKnownNewExpDate
    /// </summary>
    internal procedure GetWellKnownNewExpDate(): Text
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        exit(QltyWorkflowResponse.GetWellKnownNewExpDate());
    end;

    #region Qlty. Result Condition Mgmt. Wrappers

    /// <summary>
    /// Wrapper for QltyResultConditionMgmt.CopyResultConditionsFromDefaultToTest
    /// </summary>
    internal procedure CopyResultConditionsFromDefaultToTest(TestCode: Code[20])
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.CopyResultConditionsFromDefaultToTest(TestCode);
    end;

    /// <summary>
    /// Wrapper for QltyResultConditionMgmt.CopyResultConditionsFromTemplateLineToTemplateLine
    /// </summary>
    internal procedure CopyResultConditionsFromTemplateLineToTemplateLine(FromQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; TargetQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line")
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.CopyResultConditionsFromTemplateLineToTemplateLine(FromQltyInspectionTemplateLine, TargetQltyInspectionTemplateLine);
    end;

    /// <summary>
    /// Wrapper for QltyResultConditionMgmt.CopyGradeConditionsFromDefaultToAllTemplates
    /// </summary>
    internal procedure CopyGradeConditionsFromDefaultToAllTemplates()
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.CopyGradeConditionsFromDefaultToAllTemplates();
    end;

    /// <summary>
    /// Wrapper for QltyResultConditionMgmt.CopyResultConditionsFromTemplateToInspection
    /// </summary>
    internal procedure CopyResultConditionsFromTemplateToInspection(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; QltyInspectionLine: Record "Qlty. Inspection Line")
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.CopyResultConditionsFromTemplateToInspection(QltyInspectionTemplateLine, QltyInspectionLine);
    end;

    /// <summary>
    /// Wrapper for QltyResultConditionMgmt.GetPromotedResultsForTest
    /// </summary>
    internal procedure GetPromotedResultsForTest(QltyTest: Record "Qlty. Test"; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.GetPromotedResultsForTest(QltyTest, MatrixSourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    /// <summary>
    /// Wrapper for QltyResultConditionMgmt.GetPromotedResultsForTemplateLine
    /// </summary>
    internal procedure GetPromotedResultsForTemplateLine(QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line"; var MatrixArraySourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.GetPromotedResultsForTemplateLine(QltyInspectionTemplateLine, MatrixArraySourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    /// <summary>
    /// Wrapper for QltyResultConditionMgmt.GetPromotedResultsForInspectionLine
    /// </summary>
    internal procedure GetPromotedResultsForInspectionLine(QltyInspectionLine: Record "Qlty. Inspection Line"; var MatrixSourceRecordId: array[10] of RecordId; var MatrixArrayToSetConditionCellData: array[10] of Text; var MatrixArrayToSetConditionDescriptionCellData: array[10] of Text; var MatrixArrayToSetCaptionSet: array[10] of Text; var MatrixVisibleStateToSet: array[10] of Boolean)
    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
    begin
        QltyResultConditionMgmt.GetPromotedResultsForInspectionLine(QltyInspectionLine, MatrixSourceRecordId, MatrixArrayToSetConditionCellData, MatrixArrayToSetConditionDescriptionCellData, MatrixArrayToSetCaptionSet, MatrixVisibleStateToSet);
    end;

    #endregion Qlty. Result Condition Mgmt. Wrappers

    #region Qlty. Filter Helpers Wrappers

    /// <summary>
    /// Wrapper for QltyFilterHelpers.RunModalLookupTable
    /// </summary>
    internal procedure RunModalLookupTable(var ObjectID: Integer; ObjectIdFilter: Text)
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        QltyFilterHelpers.RunModalLookupTable(ObjectID, ObjectIdFilter);
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.RunModalLookupTableFromText
    /// </summary>
    internal procedure RunModalLookupTableFromText(var TableReference: Text)
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        QltyFilterHelpers.RunModalLookupTableFromText(TableReference);
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.RunModalLookupFieldFromText
    /// </summary>
    internal procedure RunModalLookupFieldFromText(var TableReference: Text; var FieldReference: Text)
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        QltyFilterHelpers.RunModalLookupFieldFromText(TableReference, FieldReference);
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.SetFiltersByExpressionSyntax
    /// </summary>
    internal procedure SetFiltersByExpressionSyntax(var RecordRef: RecordRef; FilterExpression: Text)
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        QltyFilterHelpers.SetFiltersByExpressionSyntax(RecordRef, FilterExpression);
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.RunModalLookupAnyField
    /// </summary>
    internal procedure RunModalLookupAnyField(TableNo: Integer; CurrentField: Integer; FieldFilter: Text): Integer
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.RunModalLookupAnyField(TableNo, CurrentField, FieldFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditZone
    /// </summary>
    internal procedure AssistEditZone(LocationFilter: Code[20]; var ToZoneCodeFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditZone(LocationFilter, ToZoneCodeFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditBin
    /// Starts the assist edit dialog for choosing a bin.
    /// </summary>
    internal procedure AssistEditBin(LocationFilter: Code[20]; ToZoneFilter: Code[20]; var ToBinCodeFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditBin(LocationFilter, ToZoneFilter, ToBinCodeFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditItemNo
    /// Starts the assist edit dialog for choosing an item.
    /// </summary>
    internal procedure AssistEditItemNo(var ItemNoFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditItemNo(ItemNoFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditItemCategory
    /// Starts the assist edit dialog for choosing an item category.
    /// </summary>
    internal procedure AssistEditItemCategory(var ItemCategoryCodeFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditItemCategory(ItemCategoryCodeFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditInventoryPostingGroup
    /// Starts the assist edit dialog for choosing an inventory posting group.
    /// </summary>
    internal procedure AssistEditInventoryPostingGroup(var InventoryPostingGroupCodeFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditInventoryPostingGroup(InventoryPostingGroupCodeFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditVendor
    /// Starts the assist edit dialog for choosing a vendor.
    /// </summary>
    internal procedure AssistEditVendor(var VendorNoFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditVendor(VendorNoFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditCustomer
    /// Starts the assist edit dialog for choosing a customer.
    /// </summary>
    internal procedure AssistEditCustomer(var CustomerNoFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditCustomer(CustomerNoFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditMachine
    /// Starts the assist edit dialog for choosing a machine.
    /// </summary>
    internal procedure AssistEditMachine(var MachineNoFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditMachine(MachineNoFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditRouting
    /// Starts the assist edit dialog for choosing a routing.
    /// </summary>
    internal procedure AssistEditRouting(var RoutingNoFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditRouting(RoutingNoFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditRoutingOperation
    /// Starts the assist edit dialog for choosing a routing operation.
    /// </summary>
    internal procedure AssistEditRoutingOperation(InRoutingNoFilter: Code[20]; var OperationNoFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditRoutingOperation(InRoutingNoFilter, OperationNoFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditWorkCenter
    /// Starts the assist edit dialog for choosing a work center.
    /// </summary>
    internal procedure AssistEditWorkCenter(var WorkCenterNoFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditWorkCenter(WorkCenterNoFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditPurchasingCode
    /// Starts the assist edit dialog for choosing a purchasing code.
    /// </summary>
    internal procedure AssistEditPurchasingCode(var PurchasingCode: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditPurchasingCode(PurchasingCode));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditReturnReasonCode
    /// Starts the assist edit dialog for choosing a return reason code.
    /// </summary>
    internal procedure AssistEditReturnReasonCode(var ReturnReasonCode: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditReturnReasonCode(ReturnReasonCode));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditQltyInspectionTemplate
    /// Starts the assist edit dialog for choosing a quality inspection template.
    /// </summary>
    internal procedure AssistEditQltyInspectionTemplate(var QltyInspectionTemplateCode: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditQltyInspectionTemplate(QltyInspectionTemplateCode));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.AssistEditLocation
    /// Starts the assist edit dialog for choosing a location.
    /// </summary>
    internal procedure AssistEditLocation(var LocationCodeFilter: Code[20]): Boolean
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.AssistEditLocation(LocationCodeFilter));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.CleanUpWhereClause2048
    /// Cleans up a WHERE clause and returns a Text[2048].
    /// </summary>
    internal procedure CleanUpWhereClause2048(Input: Text): Text[2048]
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.CleanUpWhereClause2048(Input));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.CleanUpWhereClause
    /// Cleans up a WHERE clause and returns the result.
    /// </summary>
    internal procedure CleanUpWhereClause(Input: Text): Text
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.CleanUpWhereClause(Input));
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.DeserializeFilterIntoItemAttributesBuffer
    /// De-serializes an existing attribute filter text into an attribute filter buffer.
    /// </summary>
    internal procedure DeserializeFilterIntoItemAttributesBuffer(AttributeFilter: Text; var TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary)
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        QltyFilterHelpers.DeserializeFilterIntoItemAttributesBuffer(AttributeFilter, TempFilterItemAttributesBuffer);
    end;

    /// <summary>
    /// Wrapper for QltyFilterHelpers.SerializeItemAttributesBufferIntoText
    /// Serializes an item attributes buffer into a filter text.
    /// </summary>
    internal procedure SerializeItemAttributesBufferIntoText(var TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary): Text
    var
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
    begin
        exit(QltyFilterHelpers.SerializeItemAttributesBufferIntoText(TempFilterItemAttributesBuffer));
    end;

    #endregion Qlty. Filter Helpers Wrappers

    #region Qlty. Expression Mgmt. Wrappers

    /// <summary>
    /// Wrapper for QltyExpressionMgmt.EvaluateTextExpression (with header and line)
    /// </summary>
    internal procedure EvaluateTextExpression(Input: Text; CurrentQltyInspectionHeader: Record "Qlty. Inspection Header"; CurrentQltyInspectionLine: Record "Qlty. Inspection Line"): Text
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        exit(QltyExpressionMgmt.EvaluateTextExpression(Input, CurrentQltyInspectionHeader, CurrentQltyInspectionLine));
    end;

    /// <summary>
    /// Wrapper for QltyExpressionMgmt.EvaluateExpressionForRecord
    /// </summary>
    internal procedure EvaluateExpressionForRecord(Input: Text; RecordVariant: Variant; EvaluateEmbeddedExpressions: Boolean): Text
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        exit(QltyExpressionMgmt.EvaluateExpressionForRecord(Input, RecordVariant, EvaluateEmbeddedExpressions));
    end;

    /// <summary>
    /// Wrapper for QltyExpressionMgmt.TestEvaluateSpecialStringFunctions
    /// Used for validation of special string function syntax.
    /// </summary>
    internal procedure TestEvaluateSpecialStringFunctions(Input: Text): Text
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
    begin
        exit(QltyExpressionMgmt.TestEvaluateSpecialStringFunctions(Input));
    end;

    #endregion Qlty. Expression Mgmt. Wrappers

    #region Qlty. Result Evaluation Wrappers

    /// <summary>
    /// Wrapper for QltyResultEvaluation.CheckIfValueIsDate
    /// </summary>
    internal procedure CheckIfValueIsDate(var TestValue: Text[250]; Condition: Text; ThrowError: Boolean): Boolean
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.CheckIfValueIsDate(TestValue, Condition, ThrowError));
    end;

    /// <summary>
    /// Wrapper for QltyResultEvaluation.CheckIfValueIsDateTime
    /// </summary>
    internal procedure CheckIfValueIsDateTime(var TestValue: Text[250]; Condition: Text; ThrowError: Boolean): Boolean
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.CheckIfValueIsDateTime(TestValue, Condition, ThrowError));
    end;

    /// <summary>
    /// Wrapper for QltyResultEvaluation.EvaluateResult
    /// </summary>
    internal procedure EvaluateResult(var OptionalQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalQltyInspectionLine: Record "Qlty. Inspection Line"; var QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf."; QltyTestValueType: Enum "Qlty. Test Value Type"; TestValue: Text; QltyCaseSensitivity: Enum "Qlty. Case Sensitivity"): Code[20]
    var
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        exit(QltyResultEvaluation.EvaluateResult(OptionalQltyInspectionHeader, OptionalQltyInspectionLine, QltyIResultConditConf, QltyTestValueType, TestValue, QltyCaseSensitivity));
    end;

    #endregion Qlty. Result Evaluation Wrappers

    #region Qlty. Inspec. Gen. Rule Mgmt. Wrappers

    /// <summary>
    /// Wrapper for QltyInspecGenRuleMgmt.FindMatchingGenerationRule
    /// </summary>
    internal procedure FindMatchingGenerationRule(RaiseErrorIfNoRuleIsFound: Boolean; IsManualCreation: Boolean; var TargetRecordRef: RecordRef; var OptionalItem: Record Item; OptionalSpecificTemplate: Code[20]; var TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary): Boolean
    var
        QltyInspecGenRuleMgmt: Codeunit "Qlty. Inspec. Gen. Rule Mgmt.";
    begin
        exit(QltyInspecGenRuleMgmt.FindMatchingGenerationRule(RaiseErrorIfNoRuleIsFound, IsManualCreation, TargetRecordRef, OptionalItem, OptionalSpecificTemplate, TempQltyInspectionGenRule));
    end;

    #endregion Qlty. Inspec. Gen. Rule Mgmt. Wrappers

    #region Qlty. Disp. Move Auto Choose Wrappers

    /// <summary>
    /// Wrapper for QltyDispMoveAutoChoose.PerformDisposition
    /// </summary>
    internal procedure PerformMoveAutoChooseDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispMoveAutoChoose: Codeunit "Qlty. Disp. Move Auto Choose";
    begin
        exit(QltyDispMoveAutoChoose.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Move Auto Choose Wrappers

    #region Qlty. Item Tracking Wrappers

    /// <summary>
    /// Wrapper for QltyItemTracking.SetLotBlockState
    /// Sets the lot block state for an inspection.
    /// </summary>
    internal procedure SetLotBlockState(QltyInspectionHeader: Record "Qlty. Inspection Header"; Blocked: Boolean)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetLotBlockState(QltyInspectionHeader, Blocked);
    end;

    /// <summary>
    /// Wrapper for QltyItemTracking.SetSerialBlockState
    /// Sets the serial block state for an inspection.
    /// </summary>
    internal procedure SetSerialBlockState(QltyInspectionHeader: Record "Qlty. Inspection Header"; Blocked: Boolean)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetSerialBlockState(QltyInspectionHeader, Blocked);
    end;

    /// <summary>
    /// Wrapper for QltyItemTracking.SetPackageBlockState
    /// Sets the package block state for an inspection.
    /// </summary>
    internal procedure SetPackageBlockState(QltyInspectionHeader: Record "Qlty. Inspection Header"; Blocked: Boolean)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetPackageBlockState(QltyInspectionHeader, Blocked);
    end;

    #endregion Qlty. Item Tracking Wrappers

    #region Qlty. Disp. Neg. Adjust Inv. Wrappers

    /// <summary>
    /// Wrapper for QltyDispNegAdjustInv.PerformDisposition
    /// Creates a negative adjustment using the information from a given Quality Inspection.
    /// </summary>
    internal procedure PerformNegAdjustInvDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispNegAdjustInv: Codeunit "Qlty. Disp. Neg. Adjust Inv.";
    begin
        exit(QltyDispNegAdjustInv.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Neg. Adjust Inv. Wrappers

    #region Qlty. Disp. Change Tracking Wrappers

    /// <summary>
    /// Wrapper for QltyDispChangeTracking.PerformDisposition
    /// Performs the change item tracking disposition.
    /// </summary>
    internal procedure PerformChangeTrackingDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispChangeTracking: Codeunit "Qlty. Disp. Change Tracking";
    begin
        exit(QltyDispChangeTracking.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Change Tracking Wrappers

    #region Qlty. Item Journal Management Wrappers

    /// <summary>
    /// Wrapper for QltyItemJournalManagement.CreateWarehouseJournalLine
    /// Creates a warehouse journal line.
    /// </summary>
    internal procedure CreateWarehouseJournalLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalBatch: Record "Warehouse Journal Batch"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
    begin
        QltyItemJournalManagement.CreateWarehouseJournalLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, WarehouseJournalBatch, WarehouseJournalLine, WhseItemTrackingLine);
    end;

    /// <summary>
    /// Wrapper for QltyItemJournalManagement.PostWarehouseJournal
    /// Posts the supplied warehouse journal line.
    /// </summary>
    internal procedure PostWarehouseJournal(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseJournalLine: Record "Warehouse Journal Line"): Boolean
    var
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
    begin
        exit(QltyItemJournalManagement.PostWarehouseJournal(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, WarehouseJournalLine));
    end;

    /// <summary>
    /// Wrapper for QltyItemJournalManagement.CreateItemJournalLine
    /// Creates an item journal line.
    /// </summary>
    internal procedure CreateItemJournalLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    var
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
    begin
        QltyItemJournalManagement.CreateItemJournalLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry);
    end;

    /// <summary>
    /// Wrapper for QltyItemJournalManagement.PostItemJournal
    /// Posts the supplied item journal line.
    /// </summary>
    internal procedure PostItemJournal(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalLine: Record "Item Journal Line"): Boolean
    var
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
    begin
        exit(QltyItemJournalManagement.PostItemJournal(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, ItemJournalLine));
    end;

    #endregion Qlty. Item Journal Management Wrappers

    #region Qlty. Disp. Move Whse.Reclass. Wrappers

    /// <summary>
    /// Wrapper for QltyDispMoveWhseReclass.PerformDisposition
    /// Performs warehouse reclassification disposition.
    /// </summary>
    internal procedure PerformMoveWhseReclassDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispMoveWhseReclass: Codeunit "Qlty. Disp. Move Whse.Reclass.";
    begin
        exit(QltyDispMoveWhseReclass.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Move Whse.Reclass. Wrappers

    #region Qlty. Disp. Move Item Reclass. Wrappers

    /// <summary>
    /// Wrapper for QltyDispMoveItemReclass.PerformDisposition
    /// Performs item reclassification disposition.
    /// </summary>
    internal procedure PerformMoveItemReclassDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispMoveItemReclass: Codeunit "Qlty. Disp. Move Item Reclass.";
    begin
        exit(QltyDispMoveItemReclass.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Move Item Reclass. Wrappers

    #region Qlty. Disp. Move Worksheet Wrappers

    /// <summary>
    /// Wrapper for QltyDispMoveWorksheet.PerformDisposition
    /// Performs movement worksheet disposition.
    /// </summary>
    internal procedure PerformMoveWorksheetDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispMoveWorksheet: Codeunit "Qlty. Disp. Move Worksheet";
    begin
        exit(QltyDispMoveWorksheet.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Move Worksheet Wrappers

    #region Qlty. Disp. Internal Move Wrappers

    /// <summary>
    /// Wrapper for QltyDispInternalMove.PerformDisposition
    /// Performs internal move disposition.
    /// </summary>
    internal procedure PerformInternalMoveDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispInternalMove: Codeunit "Qlty. Disp. Internal Move";
    begin
        exit(QltyDispInternalMove.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Internal Move Wrappers

    #region Qlty. Disp. Transfer Wrappers

    /// <summary>
    /// Wrapper for QltyDispTransfer.PerformDisposition
    /// Performs transfer order disposition.
    /// </summary>
    internal procedure PerformTransferDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary): Boolean
    var
        QltyDispTransfer: Codeunit "Qlty. Disp. Transfer";
    begin
        exit(QltyDispTransfer.PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    #endregion Qlty. Disp. Transfer Wrappers

    #region Qlty. Inventory Availability Wrappers

    /// <summary>
    /// Wrapper for QltyInventoryAvailability.PopulateQuantityBuffer
    /// Populates the quantity buffer.
    /// </summary>
    internal procedure PopulateQuantityBuffer(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TempQuantityQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary)
    var
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
    begin
        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityQltyDispositionBuffer);
    end;

    #endregion Qlty. Inventory Availability Wrappers

    #region Qlty. Item Tracking Mgmt. Wrappers

    /// <summary>
    /// Wrapper for QltyItemTrackingMgmt.CreateItemJournalLineReservationEntry
    /// Creates an item journal line reservation entry for the supplyed journal line.
    /// Set the tracking on the line (no modify needed) to give the tracking instruction.
    /// </summary>
    internal procedure CreateItemJournalLineReservationEntry(var ItemJournalLine: Record "Item Journal Line"; var CreatedActualReservationEntry: Record "Reservation Entry")
    var
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
    begin
        QltyItemTrackingMgmt.CreateItemJournalLineReservationEntry(ItemJournalLine, CreatedActualReservationEntry);
    end;

    /// <summary>
    /// Wrapper for QltyItemTrackingMgmt.GetIsWarehouseTracked
    /// Returns true if the item is lot warehouse, or serial warehouse, or package warehouse tracked.
    /// </summary>
    internal procedure GetIsWarehouseTracked(ItemNo: Code[20]): Boolean
    var
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
    begin
        exit(QltyItemTrackingMgmt.GetIsWarehouseTracked(ItemNo));
    end;

    #endregion Qlty. Item Tracking Mgmt. Wrappers

    #region Qlty. Misc Helpers Wrappers

    /// <summary>
    /// Wrapper for QltyMiscHelpers.GetRecordsForTableFieldAsCSV
    /// Retrieves available record values for a table lookup field configured on an inspection line, returned as CSV.
    /// </summary>
    internal procedure GetRecordsForTableFieldAsCSV(var QltyInspectionLine: Record "Qlty. Inspection Line") CSVText: Text
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        exit(QltyMiscHelpers.GetRecordsForTableFieldAsCSV(QltyInspectionLine));
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.GetRecordsForTableField (2-param)
    /// Retrieves available records for a table lookup field configured on an inspection line.
    /// </summary>
    internal procedure GetRecordsForTableField(var QltyInspectionLine: Record "Qlty. Inspection Line"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        QltyMiscHelpers.GetRecordsForTableField(QltyInspectionLine, TempBufferQltyTestLookupValue);
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.GetRecordsForTableField (4-param)
    /// Retrieves lookup values for a quality field with context-sensitive filtering.
    /// </summary>
    internal procedure GetRecordsForTableField(var QltyTest: Record "Qlty. Test"; var OptionalContextQltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalContextQltyInspectionLine: Record "Qlty. Inspection Line"; var TempBufferQltyTestLookupValue: Record "Qlty. Test Lookup Value" temporary)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        QltyMiscHelpers.GetRecordsForTableField(QltyTest, OptionalContextQltyInspectionHeader, OptionalContextQltyInspectionLine, TempBufferQltyTestLookupValue);
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.GetCSVOfValuesFromRecord (4-param)
    /// Generates a CSV string of values for a specific field from a table with optional filtering.
    /// </summary>
    internal procedure GetCSVOfValuesFromRecord(CurrentTable: Integer; ChoiceField: Integer; TableFilter: Text; MaxCountRecords: Integer): Text
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        exit(QltyMiscHelpers.GetCSVOfValuesFromRecord(CurrentTable, ChoiceField, TableFilter, MaxCountRecords));
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue
    /// Analyzes field description and sample value to infer the appropriate data type.
    /// </summary>
    internal procedure GuessDataTypeFromDescriptionAndValue(Description: Text; OptionalValue: Text): Enum "Qlty. Test Value Type"
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        exit(QltyMiscHelpers.GuessDataTypeFromDescriptionAndValue(Description, OptionalValue));
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.SetTableValue
    /// Sets a field value on a record identified by table name and filter.
    /// </summary>
    internal procedure SetTableValue(TableName: Text; TableFilter: Text; NumberOrNameOfFieldToSet: Text; ValueToSet: Text; Validate: Boolean)
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        QltyMiscHelpers.SetTableValue(TableName, TableFilter, NumberOrNameOfFieldToSet, ValueToSet, Validate);
    end;

    /// <summary>
    /// Wrapper for QltyMiscHelpers.ReadFieldAsText
    /// Reads a field value from any record variant and returns it as formatted text.
    /// </summary>
    internal procedure ReadFieldAsText(CurrentRecordVariant: Variant; NumberOrNameOfFieldName: Text; FormatNumber: Integer): Text
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
    begin
        exit(QltyMiscHelpers.ReadFieldAsText(CurrentRecordVariant, NumberOrNameOfFieldName, FormatNumber));
    end;

    #endregion Qlty. Misc Helpers Wrappers
}
