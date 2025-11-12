// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement.TestLibraries;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using System.Reflection;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 139950 "Qlty. Tests - Utility"
{
    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryUtility: Codeunit "Library - Utility";
        NoSeriesCodeunit: Codeunit "No. Series";
        DefaultGrade2PassCodeLbl: Label 'PASS', Locked = true;

    procedure EnsureSetup()
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        UserPermissionsLibrary: Codeunit "User Permissions Library";
    begin
        QltyAutoConfigure.EnsureBasicSetup(false);
        QltyManagementSetup.Get();
        QltyManagementSetup."Show Test Behavior" := QltyManagementSetup."Show Test Behavior"::"Do not show created tests";
        QltyManagementSetup.Modify();

        UserPermissionsLibrary.AssignPermissionSetToUser(UserSecurityId(), 'QltyGeneral');
    end;

    procedure CreateABasicTemplateAndInstanceOfATest(var OutCreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var OutQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        ProdOrderRoutingLineRecordRefRecordRef: RecordRef;
        OrdersList: List of [Code[20]];
        ProductionOrder: Code[20];
        ClaimedATestWasCreated: Boolean;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        QltyTestsUtility.EnsureSetup();

        QltyTestsUtility.CreateTemplate(OutQltyInspectionTemplateHdr, 3);

        QltyTestsUtility.CreatePrioritizedRule(OutQltyInspectionTemplateHdr, Database::"Prod. Order Routing Line");

        QltyProdOrderGenerator.Init(100);
        QltyProdOrderGenerator.ToggleAllSources(false);
        QltyProdOrderGenerator.ToggleSourceType("Prod. Order Source Type"::Item, true);
        QltyProdOrderGenerator.Generate(2, OrdersList);
        LibraryAssert.AreEqual(2, OrdersList.Count(), 'Common test generation. Test generator did not make the expected amount of production orders.');
        OrdersList.Get(1, ProductionOrder);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder);
        ProdOrderRoutingLine.FindLast();

        OutCreatedQltyInspectionTestHeader.Reset();
        BeforeCount := OutCreatedQltyInspectionTestHeader.Count();

        ProdOrderRoutingLineRecordRefRecordRef.GetTable(ProdOrderRoutingLine);
        ClaimedATestWasCreated := QltyInspectionTestCreate.CreateTest(ProdOrderRoutingLineRecordRefRecordRef, true);

        OutCreatedQltyInspectionTestHeader.Reset();
        AfterCount := OutCreatedQltyInspectionTestHeader.Count();

        LibraryAssert.AreEqual((BeforeCount + 1), AfterCount, 'Expected overall tests');
        OutCreatedQltyInspectionTestHeader.SetRange("Source Document No.", ProdOrderRoutingLine."Prod. Order No.");
        LibraryAssert.AreEqual((1), OutCreatedQltyInspectionTestHeader.Count(), 'There should be exactly one test for this operation.');
        LibraryAssert.IsTrue(ClaimedATestWasCreated, 'A test flag should have been created');

        QltyInspectionTestCreate.GetCreatedTest(OutCreatedQltyInspectionTestHeader);
    end;

    procedure CreateTemplate(var OutQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; HowManyFields: Integer)
    var
        IgnoredQltyField: Record "Qlty. Field";
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
                CreateFieldAndAddToTemplate(OutQltyInspectionTemplateHdr, IgnoredQltyField, "Qlty. Field Type"::"Field Type Text")
    end;

    procedure CreateFieldAndAddToTemplate(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; QltyFieldType: Enum "Qlty. Field Type")
    var
        IgnoredQltyField: Record "Qlty. Field";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        Clear(QltyInspectionTemplateLine);
        CreateField(IgnoredQltyField, QltyFieldType);
        QltyInspectionTemplateLine.Init();
        QltyInspectionTemplateLine."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateLine.InitLineNoIfNeeded();
        QltyInspectionTemplateLine.Validate("Field Code", IgnoredQltyField.Code);
        QltyInspectionTemplateLine.Insert(true);
    end;

    procedure CreateFieldAndAddToTemplate(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var OutQltyField: Record "Qlty. Field"; QltyFieldType: Enum "Qlty. Field Type")
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        Clear(QltyInspectionTemplateLine);
        CreateField(OutQltyField, QltyFieldType);
        QltyInspectionTemplateLine.Init();
        QltyInspectionTemplateLine."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateLine.InitLineNoIfNeeded();
        QltyInspectionTemplateLine.Validate("Field Code", OutQltyField.Code);
        QltyInspectionTemplateLine.Insert(true);
    end;

    procedure CreateFieldAndAddToTemplate(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; QltyFieldType: Enum "Qlty. Field Type"; var QltyField: Record "Qlty. Field"; var OutQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line")
    begin
        Clear(OutQltyInspectionTemplateLine);
        CreateField(QltyField, QltyFieldType);
        OutQltyInspectionTemplateLine.Init();
        OutQltyInspectionTemplateLine."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        OutQltyInspectionTemplateLine.InitLineNoIfNeeded();
        OutQltyInspectionTemplateLine.Validate("Field Code", QltyField.Code);
        OutQltyInspectionTemplateLine.Insert(true);
    end;

    procedure CreateField(var QltyField: Record "Qlty. Field"; QltyFieldType: Enum "Qlty. Field Type")
    var
        QltyInspectionGrade: Record "Qlty. Inspection Grade";
        ToFieldRecordRef: RecordRef;
    begin
        Clear(QltyField);
        QltyField.Init();
        QltyField."Field Type" := QltyFieldType;
        ToFieldRecordRef.GetTable(QltyField);
        FillTextField(ToFieldRecordRef, QltyField.FieldNo(Code), true);
        FillTextField(ToFieldRecordRef, QltyField.FieldNo(Description), true);
        ToFieldRecordRef.SetTable(QltyField);
        QltyField.Insert();

        if QltyInspectionGrade.Get(DefaultGrade2PassCodeLbl) then
            case QltyFieldType of
                QltyFieldType::"Field Type Text", QltyFieldType::"Field Type Text Expression":
                    QltyField.SetGradeCondition(DefaultGrade2PassCodeLbl, '<>HARDCODEDFAIL', true);
                QltyFieldType::"Field Type Decimal", QltyFieldType::"Field Type Integer":
                    QltyField.SetGradeCondition(DefaultGrade2PassCodeLbl, '<>-123', true);
                QltyFieldType::"Field Type Boolean":
                    QltyField.SetGradeCondition(DefaultGrade2PassCodeLbl, '<>FALSE', true);
            end;
    end;

    procedure CreatePrioritizedRule(InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; SourceTableNo: Integer)
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        CreatePrioritizedRule(InExistingQltyInspectionTemplateHdr, SourceTableNo, QltyInTestGenerationRule);
    end;

    procedure CreatePrioritizedRule(var InExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; SourceTableNo: Integer; var OutQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule")
    var
        FindLowestQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        if InExistingQltyInspectionTemplateHdr.Code = '' then
            CreateTemplate(InExistingQltyInspectionTemplateHdr, 0);

        FindLowestQltyInTestGenerationRule.ModifyAll("Activation Trigger", FindLowestQltyInTestGenerationRule."Activation Trigger"::Disabled);

        FindLowestQltyInTestGenerationRule.Reset();
        FindLowestQltyInTestGenerationRule.SetCurrentKey("Sort Order");

        OutQltyInTestGenerationRule.Init();
        if FindLowestQltyInTestGenerationRule.FindFirst() then
            OutQltyInTestGenerationRule."Sort Order" := FindLowestQltyInTestGenerationRule."Sort Order" - 1;

        OutQltyInTestGenerationRule."Template Code" := InExistingQltyInspectionTemplateHdr.Code;
        OutQltyInTestGenerationRule."Source Table No." := SourceTableNo;
        OutQltyInTestGenerationRule.Insert(true);
    end;

    procedure CreateItemJournalTemplateAndBatch(TemplateType: Enum "Item Journal Entry Type"; var OutItemJournalBatch: Record "Item Journal Batch")
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
    procedure GenerateRandomCharacters(NumberOfCharacters: Integer; var Out: Text)
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
    procedure CreateLotTrackedItem(var OutItem: Record Item)
    var
        NoSeries: Record "No. Series";
    begin
        CreateLotTrackedItem(OutItem, NoSeries);
    end;

    /// <summary>
    /// Creates a lot no. series and a lot-tracked item
    /// </summary>
    /// <param name="OutItem"></param>
    procedure CreateLotTrackedItem(var OutItem: Record Item; var OutLotNoSeries: Record "No. Series")
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
    procedure CreateSerialTrackedItem(var OutItem: Record Item)
    var
        NoSeries: Record "No. Series";
    begin
        CreateSerialTrackedItem(OutItem, NoSeries);
    end;

    /// <summary>
    /// Creates a serial no. series and a serial-tracked item
    /// </summary>
    /// <param name="OutItem"></param>
    procedure CreateSerialTrackedItem(var OutItem: Record Item; var OutSerialNoSeries: Record "No. Series")
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
    procedure CreatePackageTrackedItemWithNoSeries(var OutItem: Record Item; var OutPackageNoSeries: Record "No. Series")
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
    procedure SetCurrLocationWhseEmployee(Location: Code[10])
    var
        WhseWarehouseEmployee: Record "Warehouse Employee";
    begin
        WhseWarehouseEmployee.Validate("User ID", UserId());
        WhseWarehouseEmployee.Validate("Location Code", Location);
        WhseWarehouseEmployee.Default := true;
        if WhseWarehouseEmployee.Insert() then;
    end;

    /// <summary>
    /// Creates Quality Inspection Test from purchase line for tracked item
    /// </summary>
    /// <param name="PurOrdPurchaseLine"></param>
    /// <param name="ReservationEntry"></param>
    /// <param name="OutQltyInspectionTestHeader"></param>
    procedure CreateTestWithPurchaseLineAndTracking(PurOrdPurchaseLine: Record "Purchase Line"; ReservationEntry: Record "Reservation Entry"; var OutQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        SpecTrackingSpecification: Record "Tracking Specification";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        PurchaseLineRecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        TestCreated: Boolean;
    begin
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        TestCreated := QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(PurchaseLineRecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        LibraryAssert.IsTrue(TestCreated, 'Quality Inspection Test not created.');

        QltyInspectionTestCreate.GetCreatedTest(OutQltyInspectionTestHeader);
        LibraryAssert.RecordCount(OutQltyInspectionTestHeader, 1);
    end;

    /// <summary>
    /// Creates Quality Inspection Test from warehouse entry for tracked item
    /// </summary>
    /// <param name="WarehouseEntry"></param>
    /// <param name="ReservationEntry"></param>
    /// <param name="OutQltyInspectionTestHeader"></param>
    procedure CreateTestWithWarehouseEntryAndTracking(WarehouseEntry: Record "Warehouse Entry"; ReservationEntry: Record "Reservation Entry"; var OutQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        SpecTrackingSpecification: Record "Tracking Specification";
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        RecordRef: RecordRef;
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        TestCreated: Boolean;
    begin
        RecordRef.GetTable(WarehouseEntry);
        SpecTrackingSpecification.CopyTrackingFromReservEntry(ReservationEntry);
        TestCreated := QltyInspectionTestCreate.CreateTestWithMultiVariantsAndTemplate(RecordRef, SpecTrackingSpecification, UnusedVariant1, UnusedVariant2, true, '');
        LibraryAssert.IsTrue(TestCreated, 'Quality Inspection Test not created.');

        QltyInspectionTestCreate.GetCreatedTest(OutQltyInspectionTestHeader);
        LibraryAssert.RecordCount(OutQltyInspectionTestHeader, 1);
    end;

    /// <summary>
    /// Creates Quality Inspection Test from purchase line for untracked item
    /// </summary>
    /// <param name="PurOrdPurchaseLine"></param>
    /// <param name="SpecificTemplate">The specific template to use.</param>
    /// <param name="OutQltyInspectionTestHeader"></param>
    procedure CreateTestWithPurchaseLine(PurOrdPurchaseLine: Record "Purchase Line"; SpecificTemplate: Code[20]; var OutQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        PurchaseLineRecordRef: RecordRef;
        TestCreated: Boolean;
    begin
        PurchaseLineRecordRef.GetTable(PurOrdPurchaseLine);
        TestCreated := QltyInspectionTestCreate.CreateTestWithSpecificTemplate(PurchaseLineRecordRef, true, SpecificTemplate);
        LibraryAssert.IsTrue(TestCreated, 'Quality Inspection Test not created.');

        QltyInspectionTestCreate.GetCreatedTest(OutQltyInspectionTestHeader);
        LibraryAssert.RecordCount(OutQltyInspectionTestHeader, 1);
    end;

    /// <summary>
    /// Creates Quality Inspection Test for warehouse entry for untracked item
    /// </summary>
    /// <param name="WarehouseEntry"></param>
    /// <param name="OutQltyInspectionTestHeader"></param>
    procedure CreateTestWithWarehouseEntry(WarehouseEntry: Record "Warehouse Entry"; var OutQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        RecordRef: RecordRef;
        TestCreated: Boolean;
    begin
        RecordRef.GetTable(WarehouseEntry);
        TestCreated := QltyInspectionTestCreate.CreateTest(RecordRef, true);
        LibraryAssert.IsTrue(TestCreated, 'Quality Inspection Test not created.');

        QltyInspectionTestCreate.GetCreatedTest(OutQltyInspectionTestHeader);
        LibraryAssert.RecordCount(OutQltyInspectionTestHeader, 1);
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
    procedure CreateReclassWhseJournalLine(var ReclassWarehouseJournalLine: Record "Warehouse Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; EntryType: Option; ItemNo: Code[20]; NewQuantity: Decimal)
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

    procedure ClearGradeLotSettings(var QltyInspectionGrade: Record "Qlty. Inspection Grade")
    begin
        QltyInspectionGrade."Lot Allow Sales" := QltyInspectionGrade."Lot Allow Sales"::Allow;
        QltyInspectionGrade."Lot Allow Assembly Consumption" := QltyInspectionGrade."Lot Allow Assembly Consumption"::Allow;
        QltyInspectionGrade."Lot Allow Assembly Output" := QltyInspectionGrade."Lot Allow Assembly Output"::Allow;
        QltyInspectionGrade."Lot Allow Consumption" := QltyInspectionGrade."Lot Allow Consumption"::Allow;
        QltyInspectionGrade."Lot Allow Invt. Movement" := QltyInspectionGrade."Lot Allow Invt. Movement"::Allow;
        QltyInspectionGrade."Lot Allow Invt. Pick" := QltyInspectionGrade."Lot Allow Invt. Pick"::Allow;
        QltyInspectionGrade."Lot Allow Invt. Put-Away" := QltyInspectionGrade."Lot Allow Invt. Put-Away"::Allow;
        QltyInspectionGrade."Lot Allow Movement" := QltyInspectionGrade."Lot Allow Movement"::Allow;
        QltyInspectionGrade."Lot Allow Output" := QltyInspectionGrade."Lot Allow Output"::Allow;
        QltyInspectionGrade."Lot Allow Pick" := QltyInspectionGrade."Lot Allow Pick"::Allow;
        QltyInspectionGrade."Lot Allow Purchase" := QltyInspectionGrade."Lot Allow Purchase"::Allow;
        QltyInspectionGrade."Lot Allow Put-Away" := QltyInspectionGrade."Lot Allow Put-Away"::Allow;
        QltyInspectionGrade."Lot Allow Transfer" := QltyInspectionGrade."Lot Allow Transfer"::Allow;
        QltyInspectionGrade.Modify();
    end;

    procedure ClearSetupTriggerDefaults(var QltyManagementSetup: Record "Qlty. Management Setup")
    begin
        QltyManagementSetup."Purchase Trigger" := QltyManagementSetup."Purchase Trigger"::NoTrigger;
        QltyManagementSetup."Sales Return Trigger" := QltyManagementSetup."Sales Return Trigger"::NoTrigger;
        QltyManagementSetup."Warehouse Receive Trigger" := QltyManagementSetup."Warehouse Receive Trigger"::NoTrigger;
        QltyManagementSetup."Warehouse Trigger" := QltyManagementSetup."Warehouse Trigger"::NoTrigger;
        QltyManagementSetup."Transfer Trigger" := QltyManagementSetup."Transfer Trigger"::NoTrigger;
        QltyManagementSetup."Production Trigger" := QltyManagementSetup."Production Trigger"::NoTrigger;
        QltyManagementSetup."Assembly Trigger" := QltyManagementSetup."Assembly Trigger"::NoTrigger;
        QltyManagementSetup.Modify();
    end;

    procedure CreatePackageTracking(var PackageNoSeries: Record "No. Series"; var PackageNoSeriesLine: Record "No. Series Line"; var PackageItemTrackingCode: Record "Item Tracking Code")
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

    procedure CreateLotTrackedItemWithVariant(var LotTrackedItem: Record Item; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateLotTrackedItem(LotTrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, LotTrackedItem."No.");
        LotTrackedItem.Modify(true);
    end;

    procedure CreateSerialTrackedItemWithVariant(var SerialTrackedItem: Record Item; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateSerialTrackedItem(SerialTrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, SerialTrackedItem."No.");
        SerialTrackedItem.Modify(true);
    end;

    procedure CreateSerialTrackedItemWithVariant(var SerialTrackedItem: Record Item; SerialNoSeries: Code[20]; SerialTrackingCode: Code[10]; UnitCost: Decimal; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateSerialTrackedItem(SerialTrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, SerialTrackedItem."No.");
    end;

    procedure CreatePackageTrackedItem(var PackageTrackedItem: Record Item; PackageTrackingCode: Code[10]; UnitCost: Decimal; var OutOptionalItemVariant: Code[10])
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

    procedure CreateUntrackedItem(var UntrackedItem: Record Item; UnitCost: Decimal; var OutOptionalItemVariant: Code[10])
    var
        ItemVariant: Record "Item Variant";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(UntrackedItem);
        OutOptionalItemVariant := LibraryInventory.CreateItemVariant(ItemVariant, UntrackedItem."No.");
        UntrackedItem.Validate("Unit Cost", UnitCost);
        UntrackedItem.Modify(true);
    end;

    procedure GetCode20NoSeries(InPrefix: Text; var OutStart: Code[20]; var OutEnd: Code[20])
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

    procedure CreateWarehouseReceiptSetup(var CreatedQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var OutPurchaseLine: Record "Purchase Line"; var OutReservationEntry: Record "Reservation Entry")
    begin
        CreateWarehouseReceiptSetup(CreatedQltyInTestGenerationRule, OutPurchaseLine, OutReservationEntry, 123);
    end;

    procedure CreateWarehouseReceiptSetup(var CreatedQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var OutPurchaseLine: Record "Purchase Line"; var OutReservationEntry: Record "Reservation Entry"; Quantity: Decimal)
    var
        Item: Record Item;
        Location: Record Location;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        PurchaseHeader: Record "Purchase Header";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        OrdQltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
    begin
        EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        CreateTemplate(QltyInspectionTemplateHdr, 1);
        CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", CreatedQltyInTestGenerationRule);

        CreatedQltyInTestGenerationRule."Purchase Trigger" := CreatedQltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderPostReceive;
        CreatedQltyInTestGenerationRule.Modify();

        CreateLotTrackedItem(Item);

        Item.SetRecFilter();
        CreatedQltyInTestGenerationRule."Item Filter" := CopyStr(Item.GetView(), 1, MaxStrLen(CreatedQltyInTestGenerationRule."Item Filter"));
        CreatedQltyInTestGenerationRule."Activation Trigger" := CreatedQltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic";
        CreatedQltyInTestGenerationRule."Purchase Trigger" := CreatedQltyInTestGenerationRule."Purchase Trigger"::OnPurchaseOrderPostReceive;
        CreatedQltyInTestGenerationRule.Modify();

        OrdQltyPurOrderGenerator.CreatePurchaseOrder(Quantity, Location, Item, PurchaseHeader, OutPurchaseLine, OutReservationEntry);
    end;
}
