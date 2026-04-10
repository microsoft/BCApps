codeunit 135412 "Budgets & Analysis Reports E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [Budgets & Analysis Reports E2E] [UI] [User Group Plan]
    end;

    var
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        Sales17Q1Tok: Label 'SALES 17Q1', Locked = true;
        SalesBudgetQ1Txt: Label 'Sales Budget 2017,Q1';
        Purchase17Q1Tok: Label 'PURCH 17Q1', Locked = true;
        PurchaseBudgetQ1Txt: Label 'Purchase Budget 2017,Q1';
        SelectedTok: Label 'SELECTED', Locked = true;
        ValueType: Option "Sales Amount","Cost Amount",Quantity;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Item1Code: Code[20];
        Item2Code: Code[20];
        SelectedTxt: Label 'Selected';
        BudgetTok: Label 'BUDGET', Locked = true;
        SalesTok: Label 'SALES', Locked = true;
        SalesSelectedItemsTxt: Label 'Sales - Select Items';
        TurnoverInActualTxt: Label 'Turnover in Amount, actual';
        TurnoverInBudgetTxt: Label 'Turnover in Amount, budget';
        DeviationTxt: Label 'Deviation';
        TotalTxt: Label 'TOTAL';
        MissingPermissionsErr: Label 'Sorry, the current permissions prevented the action.';
        InsertNotAllowedErr: Label 'New method failed because Insert is not allowed';

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SalesAnalysisLinesModalPageHandler,ItemListModalPageHandler,SalesAnalysisMatrixModalPageHandler,SalesBudgetOverviewPageHandler,SalesAnalysisReportPageHandler,AnalysisLineTemplateModalPageHandler,AnalysisColumnsModalPageHandler,AnalysisColumnTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure UsingSalesBudgetsAndAnalysisReportsAsBusinessManager()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // [SCENARIO] Setup and use Sales Budgets & Analysis Reports as Business Manager
        Initialize();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] 2 items
        Item1Code := CreateItem();
        Item2Code := CreateItem();

        // [WHEN] Create Sales Budget
        CreateBudgetNamesSales();

        // Use Sales Analysis Report to compare actual sales with budget
        // [WHEN] Create Analysis Line Template
        CreateAnalysisLineTemplate(AnalysisLineTemplate."Analysis Area"::Sales);

        // [WHEN] Create Analysis Column Template
        CreateAnalysisColumnTemplate(AnalysisColumnTemplate."Analysis Area"::Sales);

        // [WHEN] Open Sales Analysis Report
        CreateAnalysisReportSales();

        // [THEN] No error has been thrown
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,SalesAnalysisLinesModalPageHandler,ItemListModalPageHandler,SalesAnalysisMatrixModalPageHandler,SalesBudgetOverviewPageHandler,SalesAnalysisReportPageHandler,AnalysisLineTemplateModalPageHandler,AnalysisColumnsModalPageHandler,AnalysisColumnTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure UsingSalesBudgetsAndAnalysisReportsAsAccountant()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // [SCENARIO] Setup and use Cost Accounting as Accountant
        Initialize();

        // [GIVEN] The External Accountant plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] 2 items
        Item1Code := CreateItem();
        Item2Code := CreateItem();

        // [WHEN] Create Sales Budget
        CreateBudgetNamesSales();

        // Use Sales Analysis Report to compare actual sales with budget
        // [WHEN] Create Analysis Line Template
        CreateAnalysisLineTemplate(AnalysisLineTemplate."Analysis Area"::Sales);

        // [WHEN] Create Analysis Column Template
        CreateAnalysisColumnTemplate(AnalysisColumnTemplate."Analysis Area"::Sales);

        // [WHEN] Open Sales Analysis Report
        CreateAnalysisReportSales();

        // [THEN] No error has been thrown
    end;

    [Test]
    [HandlerFunctions('AnalysisLineTemplateModalPageHandler,AnalysisColumnTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure UsingSalesBudgetsAndAnalysisReportsAsTeamMember()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // [SCENARIO] Setup and use Cost Accounting as Team Member
        Initialize();

        // [GIVEN] The Team Member plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [GIVEN] 2 items
        asserterror Item1Code := CreateItem();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        asserterror Item2Code := CreateItem();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        // [WHEN] Create Sales Budget
        asserterror CreateBudgetNamesSales();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(InsertNotAllowedErr);

        // Use Sales Analysis Report to compare actual sales with budget
        // [WHEN] Create Analysis Line Template
        asserterror CreateAnalysisLineTemplate(AnalysisLineTemplate."Analysis Area"::Sales);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(InsertNotAllowedErr);

        // [WHEN] Create Analysis Column Template
        asserterror CreateAnalysisColumnTemplate(AnalysisColumnTemplate."Analysis Area"::Sales);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(InsertNotAllowedErr);

        // [WHEN] Open Sales Analysis Report
        asserterror CreateAnalysisReportSales();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        // [THEN] No error has been thrown
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,PurchaseAnalysisLinesModalPageHandler,ItemListModalPageHandler,PurchaseAnalysisMatrixModalPageHandler,PurchaseBudgetOverviewPageHandler,PurchaseAnalysisReportPageHandler,AnalysisLineTemplateModalPageHandler,AnalysisColumnsModalPageHandler,AnalysisColumnTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure UsingPurchaseBudgetsAndAnalysisReportsAsBusinessManager()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // [SCENARIO] Setup and use Purchase Budgets & Analysis Reports as Business Manager
        Initialize();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] 2 items
        Item1Code := CreateItem();
        Item2Code := CreateItem();

        // [WHEN] Create Purchase Budget
        CreateBudgetNamesPurchase();

        // [WHEN] Use Purchase Analysis Report to compare actual sales with budget
        CreateAnalysisLineTemplate(AnalysisLineTemplate."Analysis Area"::Purchase);

        // [WHEN] Create AnalysisColumnTemplate
        CreateAnalysisColumnTemplate(AnalysisColumnTemplate."Analysis Area"::Purchase);

        // [WHEN] Open Purchase Analysis Report
        CreateAnalysisReportPurchase();

        // [THEN] No error was thrown
    end;

    [Test]
    [HandlerFunctions('SelectItemTemplListModalPageHandler,PurchaseAnalysisLinesModalPageHandler,ItemListModalPageHandler,PurchaseAnalysisMatrixModalPageHandler,PurchaseBudgetOverviewPageHandler,PurchaseAnalysisReportPageHandler,AnalysisLineTemplateModalPageHandler,AnalysisColumnsModalPageHandler,AnalysisColumnTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure UsingPurchaseBudgetsAndAnalysisReportsAsAccountant()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // [SCENARIO] Setup and use Purchase Budgets & Analysis Reports as External Accountant
        Initialize();

        // [GIVEN] The External Accountant plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [GIVEN] 2 items
        Item1Code := CreateItem();
        Item2Code := CreateItem();

        // [WHEN] Create Purchase Budget
        CreateBudgetNamesPurchase();

        // [WHEN] Use Purchase Analysis Report to compare actual sales with budget
        CreateAnalysisLineTemplate(AnalysisLineTemplate."Analysis Area"::Purchase);

        // [WHEN] Create AnalysisColumnTemplate
        CreateAnalysisColumnTemplate(AnalysisColumnTemplate."Analysis Area"::Purchase);

        // [WHEN] Open Purchase Analysis Report
        CreateAnalysisReportPurchase();

        // [THEN] No error was thrown
    end;

    [Test]
    [HandlerFunctions('AnalysisLineTemplateModalPageHandler,AnalysisColumnTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure UsingPurchaseBudgetsAndAnalysisReportsAsTeamMember()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        // [SCENARIO] Setup and use Purchase Budgets & Analysis Reports as Team Member
        Initialize();

        // [GIVEN] The Team Member plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [GIVEN] 2 items
        asserterror Item1Code := CreateItem();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        asserterror Item2Code := CreateItem();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        // [WHEN] Create Purchase Budget
        asserterror CreateBudgetNamesPurchase();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(InsertNotAllowedErr);

        // [WHEN] Use Purchase Analysis Report to compare actual sales with budget
        asserterror CreateAnalysisLineTemplate(AnalysisLineTemplate."Analysis Area"::Purchase);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(InsertNotAllowedErr);

        // [WHEN] Create AnalysisColumnTemplate
        asserterror CreateAnalysisColumnTemplate(AnalysisColumnTemplate."Analysis Area"::Purchase);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(InsertNotAllowedErr);

        // [WHEN] Open Purchase Analysis Report
        asserterror CreateAnalysisReportPurchase();
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        // [THEN] No error was thrown
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ItemBudgetName: Record "Item Budget Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisReportName: Record "Analysis Report Name";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Budgets & Analysis Reports E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        ItemBudgetName.DeleteAll();
        AnalysisLineTemplate.DeleteAll();
        AnalysisColumnTemplate.DeleteAll();
        AnalysisReportName.DeleteAll();

        LibraryTemplates.EnableTemplatesFeature();
    end;

    local procedure CreateItem() ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateBudgetNamesSales()
    var
        BudgetNamesSales: TestPage "Budget Names Sales";
    begin
        BudgetNamesSales.OpenEdit();
        BudgetNamesSales.New();
        BudgetNamesSales.Name.SetValue(Sales17Q1Tok);
        BudgetNamesSales.Description.SetValue(SalesBudgetQ1Txt);
        BudgetNamesSales.EditBudget.Invoke();
        BudgetNamesSales.OK().Invoke();
    end;

    local procedure CreateBudgetNamesPurchase()
    var
        BudgetNamesPurchase: TestPage "Budget Names Purchase";
    begin
        BudgetNamesPurchase.OpenEdit();
        BudgetNamesPurchase.New();
        BudgetNamesPurchase.Name.SetValue(Purchase17Q1Tok);
        BudgetNamesPurchase.Description.SetValue(PurchaseBudgetQ1Txt);
        BudgetNamesPurchase.EditBudget.Invoke();
        BudgetNamesPurchase.OK().Invoke();
    end;

    local procedure CreateAnalysisReportSales()
    var
        AnalysisReportSale: TestPage "Analysis Report Sale";
    begin
        AnalysisReportSale.OpenNew();
        AnalysisReportSale.Name.SetValue(SalesTok);
        AnalysisReportSale.Description.SetValue(SalesSelectedItemsTxt);
        AnalysisReportSale."Analysis Line Template Name".SetValue(SelectedTok);
        AnalysisReportSale."Analysis Column Template Name".SetValue(BudgetTok);
        AnalysisReportSale.EditAnalysisReport.Invoke();
    end;

    local procedure CreateAnalysisReportPurchase()
    var
        AnalysisReportPurchase: TestPage "Analysis Report Purchase";
    begin
        AnalysisReportPurchase.OpenNew();
        AnalysisReportPurchase.Name.SetValue(SalesTok);
        AnalysisReportPurchase.Description.SetValue(SalesSelectedItemsTxt);
        AnalysisReportPurchase."Analysis Line Template Name".SetValue(SelectedTok);
        AnalysisReportPurchase."Analysis Column Template Name".SetValue(BudgetTok);
        AnalysisReportPurchase.EditAnalysisReport.Invoke();
    end;

    local procedure SetValuesOnSalesBudgetMatrix(var SalesBudgetOverview: TestPage "Sales Budget Overview"; ItemCode: Code[20])
    begin
        SalesBudgetOverview.MATRIX.GotoKey(ItemCode);
        SalesBudgetOverview.MATRIX.Field1.SetValue(LibraryRandom.RandInt(1000));
        SalesBudgetOverview.MATRIX.Field2.SetValue(LibraryRandom.RandInt(1000));
        SalesBudgetOverview.MATRIX.Field3.SetValue(LibraryRandom.RandInt(1000));
    end;

    local procedure SetValuesOnPurchaseBudgetMatrix(var PurchaseBudgetOverview: TestPage "Purchase Budget Overview"; ItemCode: Code[20])
    begin
        PurchaseBudgetOverview.MATRIX.GotoKey(ItemCode);
        PurchaseBudgetOverview.MATRIX.Field1.SetValue(LibraryRandom.RandInt(1000));
        PurchaseBudgetOverview.MATRIX.Field2.SetValue(LibraryRandom.RandInt(1000));
        PurchaseBudgetOverview.MATRIX.Field3.SetValue(LibraryRandom.RandInt(1000));
    end;

    local procedure CreateAnalysisLineTemplate(AnalysisArea: Enum "Analysis Area Type")
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        AnalysisLineTemplate.FilterGroup := 2;
        AnalysisLineTemplate.SetRange("Analysis Area", AnalysisArea);
        AnalysisLineTemplate.FilterGroup := 0;
        PAGE.RunModal(0, AnalysisLineTemplate);
    end;

    local procedure CreateAnalysisColumnTemplate(AnalysisArea: Enum "Analysis Area Type")
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        AnalysisColumnTemplate.FilterGroup := 2;
        AnalysisColumnTemplate.SetRange("Analysis Area", AnalysisArea);
        AnalysisColumnTemplate.FilterGroup := 0;
        PAGE.RunModal(0, AnalysisColumnTemplate);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisLineTemplateModalPageHandler(var AnalysisLineTemplates: TestPage "Analysis Line Templates")
    begin
        AnalysisLineTemplates.New();
        AnalysisLineTemplates.Name.SetValue(SelectedTok);
        AnalysisLineTemplates.Description.SetValue(SelectedTxt);
        AnalysisLineTemplates.Lines.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisColumnTemplateModalPageHandler(var AnalysisColumnTemplates: TestPage "Analysis Column Templates")
    begin
        AnalysisColumnTemplates.New();
        AnalysisColumnTemplates.Name.SetValue(BudgetTok);
        AnalysisColumnTemplates.Description.SetValue(BudgetTok);
        AnalysisColumnTemplates.Columns.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisColumnsModalPageHandler(var AnalysisColumns: TestPage "Analysis Columns")
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        CreateColumn(AnalysisColumns, 'A1', TurnoverInActualTxt, true, AnalysisColumn."Column Type"::"Net Change",
          AnalysisColumn."Ledger Entry Type"::"Item Entries", '', AnalysisColumn."Value Type"::"Sales Amount");
        CreateColumn(AnalysisColumns, 'A2', TurnoverInBudgetTxt, false, AnalysisColumn."Column Type"::"Net Change",
          AnalysisColumn."Ledger Entry Type"::"Item Budget Entries", '', AnalysisColumn."Value Type"::"Sales Amount");
        CreateColumn(AnalysisColumns, 'A3', DeviationTxt, false, AnalysisColumn."Column Type"::"Net Change",
          AnalysisColumn."Ledger Entry Type"::"Item Entries", '(A2/A1-1)*100', AnalysisColumn."Value Type"::"Sales Amount");
    end;

    local procedure CreateColumn(var AnalysisColumns: TestPage "Analysis Columns"; ColumnNo: Code[10]; ColumnHeader: Text[50]; Invoiced: Boolean; ColumnType: Enum "Analysis Column Type"; LedgerEntryType: Option; Formula: Text[50]; ValueType: Enum "Analysis Value Type")
    begin
        AnalysisColumns.New();
        AnalysisColumns."Column No.".SetValue(ColumnNo);
        AnalysisColumns."Column Header".SetValue(ColumnHeader);
        AnalysisColumns.Invoiced.SetValue(Invoiced);
        AnalysisColumns."Column Type".SetValue(ColumnType);
        AnalysisColumns."Ledger Entry Type".SetValue(LedgerEntryType);
        AnalysisColumns.Formula.SetValue(Formula);
        AnalysisColumns."Value Type".SetValue(ValueType);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisLinesModalPageHandler(var SalesAnalysisLines: TestPage "Sales Analysis Lines")
    var
        AnalysisLine: Record "Analysis Line";
    begin
        LibraryVariableStorage.Enqueue(Item1Code);
        SalesAnalysisLines."Insert &Item".Invoke();

        LibraryVariableStorage.Enqueue(Item2Code);
        SalesAnalysisLines."Insert &Item".Invoke();

        SalesAnalysisLines.New();
        SalesAnalysisLines."Row Ref. No.".SetValue(TotalTxt);
        SalesAnalysisLines.Type.SetValue(AnalysisLine.Type::Formula);
        SalesAnalysisLines.Range.SetValue(StrSubstNo('%1..%2', Item1Code, Item2Code));

        SalesAnalysisLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisLinesModalPageHandler(var PurchaseAnalysisLines: TestPage "Purchase Analysis Lines")
    var
        AnalysisLine: Record "Analysis Line";
    begin
        LibraryVariableStorage.Enqueue(Item1Code);
        PurchaseAnalysisLines."Insert &Items".Invoke();

        LibraryVariableStorage.Enqueue(Item2Code);
        PurchaseAnalysisLines."Insert &Items".Invoke();

        PurchaseAnalysisLines.New();
        PurchaseAnalysisLines."Row Ref. No.".SetValue(TotalTxt);
        PurchaseAnalysisLines.Type.SetValue(AnalysisLine.Type::Formula);
        PurchaseAnalysisLines.Range.SetValue(StrSubstNo('%1..%2', Item1Code, Item2Code));

        PurchaseAnalysisLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemList: TestPage "Item List")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemList.FILTER.SetFilter("No.", ItemNo);
        ItemList.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesBudgetOverviewPageHandler(var SalesBudgetOverview: TestPage "Sales Budget Overview")
    begin
        SalesBudgetOverview.DateFilter.SetValue('p1..p3');
        SalesBudgetOverview.PeriodType.SetValue(PeriodType::Month);
        SalesBudgetOverview.ItemFilter.SetValue(StrSubstNo('%1..%2', Item1Code, Item2Code));

        SalesBudgetOverview.ValueType.SetValue(ValueType::"Sales Amount");
        SetValuesOnSalesBudgetMatrix(SalesBudgetOverview, Item1Code);
        SetValuesOnSalesBudgetMatrix(SalesBudgetOverview, Item2Code);

        SalesBudgetOverview.ValueType.SetValue(ValueType::"Cost Amount");
        SetValuesOnSalesBudgetMatrix(SalesBudgetOverview, Item1Code);
        SetValuesOnSalesBudgetMatrix(SalesBudgetOverview, Item2Code);

        SalesBudgetOverview.ValueType.SetValue(ValueType::Quantity);
        SetValuesOnSalesBudgetMatrix(SalesBudgetOverview, Item1Code);
        SetValuesOnSalesBudgetMatrix(SalesBudgetOverview, Item2Code);

        SalesBudgetOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseBudgetOverviewPageHandler(var PurchaseBudgetOverview: TestPage "Purchase Budget Overview")
    begin
        PurchaseBudgetOverview.DateFilter.SetValue('p1..p3');
        PurchaseBudgetOverview.PeriodType.SetValue(PeriodType::Month);
        PurchaseBudgetOverview.ItemFilter.SetValue(StrSubstNo('%1..%2', Item1Code, Item2Code));

        PurchaseBudgetOverview.ValueType.SetValue(ValueType::Quantity);
        SetValuesOnPurchaseBudgetMatrix(PurchaseBudgetOverview, Item1Code);
        SetValuesOnPurchaseBudgetMatrix(PurchaseBudgetOverview, Item2Code);

        PurchaseBudgetOverview.ValueType.SetValue(ValueType::"Cost Amount");
        SetValuesOnPurchaseBudgetMatrix(PurchaseBudgetOverview, Item1Code);
        SetValuesOnPurchaseBudgetMatrix(PurchaseBudgetOverview, Item2Code);
        PurchaseBudgetOverview.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportPageHandler(var SalesAnalysisReport: TestPage "Sales Analysis Report")
    var
        AnalysisLine: Record "Analysis Line";
    begin
        SalesAnalysisReport.CurrentLineTemplate.SetValue(SelectedTok);
        SalesAnalysisReport.CurrentColumnTemplate.SetValue(BudgetTok);
        SalesAnalysisReport.PeriodType.SetValue(PeriodType::Month);

        SalesAnalysisReport.CurrentSourceTypeFilter.SetValue(AnalysisLine."Source Type Filter"::Item);
        SalesAnalysisReport.CurrentSourceTypeNoFilter.SetValue(StrSubstNo('%1..%2', Item1Code, Item2Code));
        Commit();
        SalesAnalysisReport.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportPageHandler(var PurchaseAnalysisReport: TestPage "Purchase Analysis Report")
    var
        AnalysisLine: Record "Analysis Line";
    begin
        PurchaseAnalysisReport.CurrentLineTemplate.SetValue(SelectedTok);
        PurchaseAnalysisReport.CurrentColumnTemplate.SetValue(BudgetTok);
        PurchaseAnalysisReport.PeriodType.SetValue(PeriodType::Month);

        PurchaseAnalysisReport.CurrentSourceTypeFilter.SetValue(AnalysisLine."Source Type Filter"::Item);
        PurchaseAnalysisReport.CurrentSourceTypeNoFilter.SetValue(StrSubstNo('%1..%2', Item1Code, Item2Code));
        Commit();
        PurchaseAnalysisReport.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisMatrixModalPageHandler(var SalesAnalysisMatrix: TestPage "Sales Analysis Matrix")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisMatrixModalPageHandler(var PurchaseAnalysisMatrix: TestPage "Purchase Analysis Matrix")
    begin
    end;
}

