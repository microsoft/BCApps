codeunit 137403 "SCM Budget and Analysis"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Analysis] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        AnalysisColumnTemplateName: Code[10];
        AnalysisLineTemplateName: Code[10];
        NewRowNo: Code[20];
        AssemblyOutpuTxt: Label 'Assembly Output';
        DirectCostTxt: Label 'Direct Cost';
        CanUseValueTypeErr: Label 'You cannot specify a %1 for %2.';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ItemListPageHandler,RenumberAnalysisLinesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RenumberAnalysisLines()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisLine: Record "Analysis Line";
    begin
        // [FEATURE] [Analysis Line]
        // [SCENARIO] Check that Analysis Lines can be renumbered.

        // [GIVEN] Create Analysis Line Template and three Analysis Lines for that template.
        Initialize();
        LibraryApplicationArea.EnableSalesAnalysisSetup();
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        CreateAnalysisLine(AnalysisLineTemplate.Name);
        CreateAnalysisLine(AnalysisLineTemplate.Name);
        CreateAnalysisLine(AnalysisLineTemplate.Name);

        // [WHEN] Renumber the Analysis Lines with the new "Row No." of 20 chars length
        // NewRowNo is made global as it is used in the handler.
        NewRowNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(AnalysisLine.FieldNo("Row Ref. No."), DATABASE::"Analysis Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Analysis Line", AnalysisLine.FieldNo("Row Ref. No.")));
        NewRowNo := PadStr(NewRowNo, MaxStrLen(AnalysisLine."Row Ref. No."), '0');
        RunRenumberAnalysisLines(AnalysisLineTemplate.Name);

        // [THEN] Verify that the Analysis Lines gets renumbered.
        VerifyRowNoInAnalysisLines(AnalysisLineTemplate.Name);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisLineHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisLineTemplate()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        // Test to validate Name on Analysis Lines page invoked by Sales Analysis Line Templates.
        Initialize();
        LibraryApplicationArea.EnableSalesAnalysisSetup();
        CreateAnalysisLineTemplateAndOpenAnalysisLines(AnalysisLineTemplate."Analysis Area"::Sales);
    end;

    [Test]
    [HandlerFunctions('PurchaseAnalysisLineHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisLineTemplate()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        // Test to validate Name on Analysis Lines page invoked by Purchase Analysis Line Templates.
        Initialize();
        LibraryApplicationArea.EnablePurchaseAnalysisSetup();
        CreateAnalysisLineTemplateAndOpenAnalysisLines(AnalysisLineTemplate."Analysis Area"::Purchase);
    end;

    [Test]
    [HandlerFunctions('InventoryAnalysisLineHandler')]
    [Scope('OnPrem')]
    procedure InventoryAnalysisLineTemplate()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        // Test to validate Name on Analysis Lines page invoked by Inventory Analysis Line Templates.
        Initialize();
        LibraryApplicationArea.EnableInventoryAnalysisSetup();
        CreateAnalysisLineTemplateAndOpenAnalysisLines(AnalysisLineTemplate."Analysis Area"::Inventory);
    end;

    local procedure CreateAnalysisLineTemplateAndOpenAnalysisLines(AnalysisArea: Enum "Analysis Area Type")
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisLineTemplates: TestPage "Analysis Line Templates";
    begin
        // Setup: Create an Analysis Line Template.
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisArea);
        AnalysisLineTemplateName := AnalysisLineTemplate.Name;  // This variable is made global as it is to be verified in the handler.

        // Exercise: Open Analysis Lines page from the Analysis Line Templates page using Handler.
        AnalysisLineTemplates.OpenEdit();
        AnalysisLineTemplates.FILTER.SetFilter(Name, AnalysisLineTemplate.Name);
        AnalysisLineTemplates.Lines.Invoke();

        // Verify: Verification is done in Analysis Line Handler.
    end;

    [Test]
    [HandlerFunctions('AnalysisColumnHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisColumnTemplate()
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // Test to validate Name on Analysis Columns page invoked by Sales Analysis Column Templates.
        Initialize();
        CreateAnalysisColumnTemplateAndOpenAnalysisColumns(AnalysisColumnTemplate."Analysis Area"::Sales);
    end;

    [Test]
    [HandlerFunctions('AnalysisColumnHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisColumnTemplate()
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // Test to validate Name on Analysis Columns page invoked by Purchase Analysis Column Templates.
        Initialize();
        CreateAnalysisColumnTemplateAndOpenAnalysisColumns(AnalysisColumnTemplate."Analysis Area"::Purchase);
    end;

    [Test]
    [HandlerFunctions('AnalysisColumnHandler')]
    [Scope('OnPrem')]
    procedure InventoryAnalysisColumnTemplate()
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // Test to validate Name on Analysis Columns page invoked by Inventory Analysis Column Templates.
        Initialize();
        CreateAnalysisColumnTemplateAndOpenAnalysisColumns(AnalysisColumnTemplate."Analysis Area"::Inventory);
    end;

    local procedure CreateAnalysisColumnTemplateAndOpenAnalysisColumns(AnalysisArea: Enum "Analysis Area Type")
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumnTemplates: TestPage "Analysis Column Templates";
    begin
        // Setup: Create an Analysis Column Template.
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisArea);
        AnalysisColumnTemplateName := AnalysisColumnTemplate.Name;  // This variable is made global as it is to be verified in the handler.

        // Exercise: Open Analysis Columns page from the Analysis Column Templates page.
        AnalysisColumnTemplates.OpenEdit();
        AnalysisColumnTemplates.FILTER.SetFilter("Analysis Area", Format(AnalysisColumnTemplate."Analysis Area"));
        AnalysisColumnTemplates.FILTER.SetFilter(Name, AnalysisColumnTemplate.Name);
        AnalysisColumnTemplates.Columns.Invoke();

        // Verify: Verification is done in Analysis Column Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemLedgerEntryTypeFilter()
    var
        AnalysisType: Record "Analysis Type";
        AnalysisTypes: TestPage "Analysis Types";
    begin
        // [FEATURE] [Analysis Types]
        // [SCENARIO 363540] Item Ledger Entry Type Filter field on Analysis Type Page stores a text option value if was set in text form

        // [GIVEN] Analysis Type Page where "Item Ledger Entry Type Filter" is blank
        AnalysisTypes.OpenNew();
        AnalysisTypes.Code.SetValue(LibraryUtility.GenerateGUID());
        AnalysisTypes."Value Type".SetValue(AnalysisType."Value Type"::"Cost Amount");

        // [WHEN] Set "Item Ledger Entry Type Filter" to "Assembly Output" in text form
        AnalysisTypes."Item Ledger Entry Type Filter".SetValue(AssemblyOutpuTxt);

        // [THEN] "Item Ledger Entry Type Filter" is "Assembly Output"
        AnalysisTypes."Item Ledger Entry Type Filter".AssertEquals(AssemblyOutpuTxt);
        AnalysisTypes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueEntryTypeFilter()
    var
        AnalysisType: Record "Analysis Type";
        AnalysisTypes: TestPage "Analysis Types";
    begin
        // [FEATURE] [Analysis Types]
        // [SCENARIO 363540] Value Entry Type Filter field on Analysis Type Page stores a text option value if was set in text form

        // [GIVEN] Analysis Type Page where "Item Ledger Entry Type Filter" is blank
        AnalysisTypes.OpenNew();
        AnalysisTypes.Code.SetValue(LibraryUtility.GenerateGUID());
        AnalysisTypes."Value Type".SetValue(AnalysisType."Value Type"::"Cost Amount");

        // [WHEN] Set "Value Entry Type Filter" to "Direct Cost" in text form
        AnalysisTypes."Value Entry Type Filter".SetValue(DirectCostTxt);

        // [THEN] "Item Ledger Entry Type Filter" is "Direct Cost"
        AnalysisTypes."Value Entry Type Filter".AssertEquals(DirectCostTxt);
        AnalysisTypes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemLedgerEntryTypeFilterNumeric()
    var
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        AnalysisType: Record "Analysis Type";
        AnalysisTypes: TestPage "Analysis Types";
    begin
        // [FEATURE] [Analysis Types]
        // [SCENARIO 363540] Item Ledger Entry Type Filter field on Analysis Type Page stores a text option value if was set in numeric form

        // [GIVEN] Analysis Type Page where "Item Ledger Entry Type Filter" is blank
        AnalysisTypes.OpenNew();
        AnalysisTypes.Code.SetValue(LibraryUtility.GenerateGUID());
        AnalysisTypes."Value Type".SetValue(AnalysisType."Value Type"::"Cost Amount");

        // [WHEN] Set "Item Ledger Entry Type Filter" to '9' (numeric value for "Assembly Output")
        AnalysisTypes."Item Ledger Entry Type Filter".SetValue(ItemStatisticsBuffer."Item Ledger Entry Type Filter"::"Assembly Output");

        // [THEN] "Item Ledger Entry Type Filter" is "Assembly Output"
        AnalysisTypes."Item Ledger Entry Type Filter".AssertEquals(AssemblyOutpuTxt);
        AnalysisTypes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueEntryTypeFilterNumeric()
    var
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        AnalysisType: Record "Analysis Type";
        AnalysisTypes: TestPage "Analysis Types";
    begin
        // [FEATURE] [Analysis Types]
        // [SCENARIO 363540] Value Entry Type Filter field on Analysis Type Page stores a text option value if was set in numeric form

        // [GIVEN] Analysis Type Page where "Item Ledger Entry Type Filter" is blank
        AnalysisTypes.OpenNew();
        AnalysisTypes.Code.SetValue(LibraryUtility.GenerateGUID());
        AnalysisTypes."Value Type".SetValue(AnalysisType."Value Type"::"Cost Amount");

        // [WHEN] Set "Value Entry Type Filter" to '0' (numeric value for "Direct Cost")
        AnalysisTypes."Value Entry Type Filter".SetValue(ItemStatisticsBuffer."Entry Type Filter"::"Direct Cost");

        // [THEN] "Item Ledger Entry Type Filter" is "Direct Cost"
        AnalysisTypes."Value Entry Type Filter".AssertEquals(DirectCostTxt);
        AnalysisTypes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueEntryTypeFilter_UnitCost()
    var
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        AnalysisType: Record "Analysis Type";
    begin
        // [FEATURE] [Analysis Types] [UT]
        // [SCENARIO 333949] Value Entry Type Filter cannot be used for Unit Cost value type (UT for CanUseValueTypeForValueEntryTypeFilter)

        // [GIVEN] Analysis Type with Value Type = "Unit Cost"
        AnalysisType."Value Type" := AnalysisType."Value Type"::"Unit Cost";

        // [WHEN] Set "Value Entry Type Filter" to "Direct Cost"
        asserterror AnalysisType.Validate("Value Entry Type Filter", format(ItemStatisticsBuffer."Entry Type Filter"::"Direct Cost"));

        // [THEN] Error "You cannot specify ..."
        Assert.ExpectedError(StrSubstNo(CanUseValueTypeErr, AnalysisType.FieldCaption("Value Entry Type Filter"), AnalysisType."Value Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemLedgerEntryTypeFilter_UnitCost()
    var
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        AnalysisType: Record "Analysis Type";
    begin
        // [FEATURE] [Analysis Types] [UT]
        // [SCENARIO 333949] Item Ledger Entry Type Filter cannot be used for Unit Cost value type (UT for CanUseValueTypeForItemLedgerEntryTypeFilter)

        // [GIVEN] Analysis Type with Value Type = "Unit Cost"
        AnalysisType."Value Type" := AnalysisType."Value Type"::"Unit Cost";

        // [WHEN] Set "Item Ledger Entry Type Filter" to "Direct Cost"
        asserterror AnalysisType.Validate("Item Ledger Entry Type Filter", format(ItemStatisticsBuffer."Item Ledger Entry Type Filter"::"Assembly Output"));

        // [THEN] Error "You cannot specify ..."
        Assert.ExpectedError(StrSubstNo(CanUseValueTypeErr, AnalysisType.FieldCaption("Item Ledger Entry Type Filter"), AnalysisType."Value Type"));
    end;

    [Test]
    [HandlerFunctions('AnalysisColumnSetShowValueHandler')]
    [Scope('OnPrem')]
    procedure AnalysisColumnShowValueReselection()
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumn: Record "Analysis Column";
        AnalysisColumnTemplates: TestPage "Analysis Column Templates";
    begin
        // [SCENARIO 395017] Analysis Column line "Show" field default value can be reselected
        Initialize();

        // [GIVEN] Analysis Column line with "Show" = Always set as default
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Sales);
        AnalysisColumnTemplateName := AnalysisColumnTemplate.Name;

        // [GIVEN] Analysis Column line "Show" = Never. Page closed
        LibraryVariableStorage.Enqueue(AnalysisColumn.Show::Never);
        AnalysisColumnTemplates.OpenEdit();
        AnalysisColumnTemplates.FILTER.SetFilter("Analysis Area", Format(AnalysisColumnTemplate."Analysis Area"));
        AnalysisColumnTemplates.FILTER.SetFilter(Name, AnalysisColumnTemplate.Name);
        AnalysisColumnTemplates.Columns.Invoke();

        // [WHEN] Analysis Columns Line "Show" set to "Always
        // [THEN] "Show" field value can be successfully selected
        // Checked in AnalysisColumnSetShowValueHandler handler
        LibraryVariableStorage.Enqueue(AnalysisColumn.Show::Always);
        AnalysisColumnTemplates.Columns.Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Budget and Analysis");
        Clear(AnalysisColumnTemplateName);
        Clear(AnalysisLineTemplateName);
        Clear(NewRowNo);
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Budget and Analysis");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Budget and Analysis");
    end;

    local procedure CreateAnalysisLine(AnalysisLineTemplateName: Code[10])
    var
        AnalysisLine: Record "Analysis Line";
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        RecRef: RecordRef;
    begin
        AnalysisLine.Validate("Analysis Area", AnalysisLine."Analysis Area"::Sales);
        AnalysisLine.Validate("Analysis Line Template Name", AnalysisLineTemplateName);
        RecRef.GetTable(AnalysisLine);
        AnalysisLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, AnalysisLine.FieldNo("Line No.")));
        AnalysisLine.Validate(Type, AnalysisLine.Type::Item);
        InsertAnalysisLine.InsertItems(AnalysisLine);
    end;

    local procedure RunRenumberAnalysisLines(AnalysisLineTemplateName: Code[20])
    var
        AnalysisLine: Record "Analysis Line";
        RenumberAnalysisLines: Report "Renumber Analysis Lines";
    begin
        Commit(); // COMMIT is required for running Batch report.
        Clear(RenumberAnalysisLines);
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLineTemplateName);
        RenumberAnalysisLines.Init(AnalysisLine);
        RenumberAnalysisLines.Run();
    end;

    local procedure VerifyRowNoInAnalysisLines(AnalysisLineTemplateName: Code[20])
    var
        AnalysisLine: Record "Analysis Line";
    begin
        // Verify that the Row Reference Number gets updated.
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLineTemplateName);
        AnalysisLine.FindSet();
        AnalysisLine.TestField("Row Ref. No.", NewRowNo);
        AnalysisLine.Next();
        NewRowNo := IncStr(NewRowNo);
        AnalysisLine.TestField("Row Ref. No.", NewRowNo);
        AnalysisLine.Next();
        NewRowNo := IncStr(NewRowNo);
        AnalysisLine.TestField("Row Ref. No.", NewRowNo);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RenumberAnalysisLinesHandler(var RenumberAnalysisLines: TestRequestPage "Renumber Analysis Lines")
    begin
        RenumberAnalysisLines.StartRowRefNo.SetValue(NewRowNo);
        RenumberAnalysisLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisLineHandler(var SalesAnalysisLines: TestPage "Sales Analysis Lines")
    begin
        SalesAnalysisLines.CurrentAnalysisLineTempl.AssertEquals(AnalysisLineTemplateName);
        SalesAnalysisLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisLineHandler(var PurchaseAnalysisLines: TestPage "Purchase Analysis Lines")
    begin
        PurchaseAnalysisLines.CurrentAnalysisLineTempl.AssertEquals(AnalysisLineTemplateName);
        PurchaseAnalysisLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InventoryAnalysisLineHandler(var InventoryAnalysisLines: TestPage "Inventory Analysis Lines")
    begin
        InventoryAnalysisLines.CurrentAnalysisLineTempl.AssertEquals(AnalysisLineTemplateName);
        InventoryAnalysisLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisColumnHandler(var AnalysisColumns: TestPage "Analysis Columns")
    begin
        AnalysisColumns.CurrentColumnName.AssertEquals(AnalysisColumnTemplateName);
        AnalysisColumns.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisColumnSetShowValueHandler(var AnalysisColumns: TestPage "Analysis Columns")
    var
        ShowValue: Integer;
    begin
        ShowValue := LibraryVariableStorage.DequeueInteger();
        AnalysisColumns.Show.SetValue(ShowValue);
        AnalysisColumns.Show.AssertEquals(ShowValue);
        AnalysisColumns.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.OK().Invoke();
    end;
}

