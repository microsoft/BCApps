namespace Microsoft.Test.DemoTool;

using Microsoft.DemoData.Inventory;
using Microsoft.DemoData.Manufacturing;
using Microsoft.DemoData.Warehousing;
using Microsoft.DemoTool;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;

codeunit 148049 "Demo Tool Language Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";

    [Test]
    procedure ContosoDemoToolLanguageInitializationTest()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
        CurrentLanguageID: Integer;
    begin
        ContosoDemoDataModule.DeleteAll();

        // [SCENARIO] Testing the "Language ID" of the Contoso Coffee Demo Data Setup record
        CurrentLanguageID := GlobalLanguage();

        // [GIVEN] Run the Contoso Demo Tool for the first time, "Language ID" should be initialized
        GetContosoTest1Module(ContosoDemoDataModule);
        ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::"Setup Data");

        // [THEN] The "Language ID" of the Contoso Coffee Demo Data Setup record should be the same as the current language
        ContosoCoffeeDemoDataSetup.Get();
        Assert.AreEqual(CurrentLanguageID, ContosoCoffeeDemoDataSetup."Language ID", 'The "Language ID" of the Contoso Coffee Demo Data Setup record should be the same as the current language');
    end;

    [Test]
    [HandlerFunctions('DifferentLanguageDialogHandler')]
    procedure ContosoDemoToolLanguageMismatchTest()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
        CurrentLanguageID, NewLanguageID : Integer;
    begin
        ContosoDemoDataModule.DeleteAll();

        // [SCENARIO] Testing when the "Language ID" does not match the first run of the Contoso Demo Tool
        CurrentLanguageID := GlobalLanguage();

        // [GIVEN] Run the Contoso Demo Tool for the first time, "Language ID" should be initialized
        GetContosoTest1Module(ContosoDemoDataModule);
        ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::"Setup Data");


        // [THEN] The "Language ID" of the Contoso Coffee Demo Data Setup record should be the same as the current language
        ContosoCoffeeDemoDataSetup.Get();
        Assert.AreEqual(CurrentLanguageID, ContosoCoffeeDemoDataSetup."Language ID", 'The "Language ID" of the Contoso Coffee Demo Data Setup record should be the same as the current language');

        // [WHEN] Changing the current language
        NewLanguageID := 2057; // English (United Kingdom)
        if NewLanguageID = CurrentLanguageID then
            NewLanguageID := 1033; // English (United States)
        GlobalLanguage(NewLanguageID);

        // [THEN] When running of the Contoso Demo Tool again, there should be dialog pops up warning a language mismatch 
        // Checking for the dialog is done in the handler function
        ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::All);
        GlobalLanguage(CurrentLanguageID);
    end;

    [Test]
    procedure InventoryAndWarehousingUseSameOwnLogisticsLocation()
    var
        CreateLocation: Codeunit "Create Location";
        CreateWhseLocation: Codeunit "Create Whse Location";
    begin
        // [SCENARIO] Inventory and Warehousing use the same localized code for the own-logistics in-transit location

        // [THEN] Both modules resolve the own-logistics in-transit location to the same code
        Assert.AreEqual(CreateLocation.OwnLogLocation(), CreateWhseLocation.TransitLocation(), 'Inventory and Warehousing must use the same own-logistics in-transit location.');
    end;

    [Test]
    procedure ManufacturingVersionNoSeriesAreCreatedAndAssignedOnlyWhenBlank()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        CreateMfgNoSeries: Codeunit "Create Mfg No Series";
    begin
        // [SCENARIO 647371] Contoso creates and assigns the production BOM and routing version number series.

        // [GIVEN] Manufacturing Setup has no version number series
        SetManufacturingVersionNoSeries('', '');

        // [WHEN] Manufacturing setup data is created
        CreateManufacturingSetupData();

        // [THEN] Both version number series have definitions padded to the ending number's width
        VerifyNoSeries(CreateMfgNoSeries.ProductionBOMVersion(), 'Production BOM Versions', 'PV00010', 'PV99990', 10);
        VerifyNoSeries(CreateMfgNoSeries.RoutingVersion(), 'Routing Versions', 'RV00010', 'RV99990', 10);

        // [THEN] Manufacturing Setup uses both version number series
        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Production BOM Version Nos.", CreateMfgNoSeries.ProductionBOMVersion());
        ManufacturingSetup.TestField("Routing Version Nos.", CreateMfgNoSeries.RoutingVersion());

        // [WHEN] Setup is rerun after alternate version number series have been selected
        ManufacturingSetup.Validate("Production BOM Version Nos.", CreateMfgNoSeries.ProductionBOM());
        ManufacturingSetup.Validate("Routing Version Nos.", CreateMfgNoSeries.Routing());
        ManufacturingSetup.Modify(true);
        CreateManufacturingSetupData();

        // [THEN] The existing setup choices are retained
        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Production BOM Version Nos.", CreateMfgNoSeries.ProductionBOM());
        ManufacturingSetup.TestField("Routing Version Nos.", CreateMfgNoSeries.Routing());
    end;

    [Test]
    procedure ManufacturingHeadersUseContosoVersionNoSeries()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        UnitOfMeasure: Record "Unit of Measure";
        CreateMfgNoSeries: Codeunit "Create Mfg No Series";
        NoSeries: Codeunit "No. Series";
        ExplicitBOMVersionCode: Code[20];
        ExpectedBOMVersionCode: Code[20];
        ExpectedRoutingVersionCode: Code[20];
    begin
        // [SCENARIO 647371] Contoso headers use the next numbers from their inherited version series without changing explicit version codes.

        // [GIVEN] Contoso manufacturing setup data
        SetManufacturingVersionNoSeries('', '');
        CreateManufacturingSetupData();

        // [WHEN] New production BOM and routing headers are inserted
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [THEN] The headers inherit the Contoso version number series
        ProductionBOMHeader.TestField("Version Nos.", CreateMfgNoSeries.ProductionBOMVersion());
        RoutingHeader.TestField("Version Nos.", CreateMfgNoSeries.RoutingVersion());

        // [GIVEN] The next numbers are captured before the explicit insertion, even if the series were already used
        ExpectedBOMVersionCode := NoSeries.PeekNextNo(CreateMfgNoSeries.ProductionBOMVersion());
        ExpectedRoutingVersionCode := NoSeries.PeekNextNo(CreateMfgNoSeries.RoutingVersion());

        // [WHEN] An explicit BOM version and blank-code BOM and routing versions are inserted
        ExplicitBOMVersionCode := 'EXPLICIT-V1';
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.", ExplicitBOMVersionCode, UnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.", '', UnitOfMeasure.Code);
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", '');

        // [THEN] The explicit code is preserved and blank codes use the inherited series
        Assert.AreEqual(ExpectedBOMVersionCode, ProductionBOMVersion."Version Code", 'The production BOM version must use the next number from the inherited series without consuming a number for the explicit version.');
        ProductionBOMVersion.TestField("No. Series", CreateMfgNoSeries.ProductionBOMVersion());
        Assert.AreEqual(ExpectedRoutingVersionCode, RoutingVersion."Version Code", 'The routing version must use the next number from the inherited series.');
        RoutingVersion.TestField("No. Series", CreateMfgNoSeries.RoutingVersion());
        Assert.IsTrue(ProductionBOMVersion.Get(ProductionBOMHeader."No.", ExplicitBOMVersionCode), 'The explicit production BOM version must remain unchanged.');
    end;

    [Test]
    procedure ManufacturingSetupRerunDoesNotBackfillExistingHeaders()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        UnitOfMeasure: Record "Unit of Measure";
        CreateMfgNoSeries: Codeunit "Create Mfg No Series";
    begin
        // [SCENARIO 647371] Rerunning Contoso setup does not backfill existing production BOM or routing headers.

        // [GIVEN] Existing headers were inserted while both setup defaults were blank
        SetManufacturingVersionNoSeries('', '');
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [WHEN] Contoso manufacturing setup is rerun
        CreateManufacturingSetupData();

        // [THEN] Setup receives the defaults but existing headers remain blank
        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Production BOM Version Nos.", CreateMfgNoSeries.ProductionBOMVersion());
        ManufacturingSetup.TestField("Routing Version Nos.", CreateMfgNoSeries.RoutingVersion());
        ProductionBOMHeader.Get(ProductionBOMHeader."No.");
        RoutingHeader.Get(RoutingHeader."No.");
        ProductionBOMHeader.TestField("Version Nos.", '');
        RoutingHeader.TestField("Version Nos.", '');
    end;

    [ConfirmHandler]
    procedure DifferentLanguageDialogHandler(Question: Text; var Reply: Boolean)
    begin
        // [THEN] The confirmation dialog should contain the words "different" and "language"
        // Not testing for the exact text because we do not want to be dependent on the label string
        if Question.Contains('different') and Question.Contains('language') then
            Reply := false
        else
            Error('Different language for the Contoso Demo Tool is not caught.');
    end;

    local procedure GetContosoTest1Module(var ContosoDemoDataModule: Record "Contoso Demo Data Module")
    begin
        ContosoDemoDataModule.Init();
        ContosoDemoDataModule.Validate(Name, Format(Enum::"Contoso Demo Data Module"::"Contoso Test 1"));
        ContosoDemoDataModule.Validate(Module, Enum::"Contoso Demo Data Module"::"Contoso Test 1");
        if not ContosoDemoDataModule.Get(Enum::"Contoso Demo Data Module"::"Contoso Test 1") then
            ContosoDemoDataModule.Insert();
    end;

    local procedure VerifyNoSeries(NoSeriesCode: Code[20]; ExpectedDescription: Text[100]; ExpectedStartingNo: Code[20]; ExpectedEndingNo: Code[20]; ExpectedIncrement: Integer)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries.TestField(Description, ExpectedDescription);
        NoSeries.TestField("Default Nos.", true);
        NoSeries.TestField("Manual Nos.", true);
        NoSeriesLine.Get(NoSeriesCode, 10000);
        NoSeriesLine.TestField("Starting No.", ExpectedStartingNo);
        NoSeriesLine.TestField("Ending No.", ExpectedEndingNo);
        NoSeriesLine.TestField("Increment-by No.", ExpectedIncrement);
        NoSeriesLine.TestField(Implementation, Enum::"No. Series Implementation"::Sequence);
    end;

    local procedure SetManufacturingVersionNoSeries(ProductionBOMVersionNos: Code[20]; RoutingVersionNos: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then
            ManufacturingSetup.Insert();
        ManufacturingSetup."Production BOM Version Nos." := ProductionBOMVersionNos;
        ManufacturingSetup."Routing Version Nos." := RoutingVersionNos;
        ManufacturingSetup.Modify();
    end;

    local procedure CreateManufacturingSetupData()
    var
        CreateMfgPostingSetup: Codeunit "Create Mfg Posting Setup";
    begin
        // Exercise the production setup routine without regenerating unrelated localized Finance and Inventory data.
        Codeunit.Run(Codeunit::"Create Mfg Cap Unit of Measure");
        Codeunit.Run(Codeunit::"Create Mfg No Series");
        CreateMfgPostingSetup.CreateManufacturingSetup();
    end;
}