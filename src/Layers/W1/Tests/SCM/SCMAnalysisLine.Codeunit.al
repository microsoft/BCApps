codeunit 137202 "SCM Analysis Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Analysis Line] [SCM]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ItemNo: Code[20];
        CustomerNo: Code[20];
        DimensionCode: Code[20];

    [Test]
    [HandlerFunctions('ItemListPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisLineForItem()
    var
        Item: Record Item;
        AnalysisLine: Record "Analysis Line";
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        AnalysisLineTemplateName: Code[10];
    begin
        // Setup: Create Item. Create Analysis Line template and partial Analysis Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        AnalysisLineTemplateName := CreatePartialAnalysisLine(AnalysisLine, AnalysisLine.Type::Item);

        // Exercise: Insert Analysis Line with Type - Item.
        InsertAnalysisLine.InsertItems(AnalysisLine);

        // Verify: Check that the Analysis line for the particular Template and Type is available.
        VerifyAnalysisLine(AnalysisLine.Type::Item, AnalysisLineTemplateName);
    end;

    [Test]
    [HandlerFunctions('DimensionValueListPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisLineForItemGroups()
    var
        AnalysisLine: Record "Analysis Line";
        Dimension: Record Dimension;
        InventorySetup: Record "Inventory Setup";
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        AnalysisLineTemplateName: Code[10];
    begin
        // Setup: Select Dimension Code. Update Item group Dimension code. Create Analysis Line template and partial Analysis Line.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        DimensionCode := Dimension.Code;
        InventorySetup.Get();
        UpdateInventorySetup(DimensionCode);
        AnalysisLineTemplateName := CreatePartialAnalysisLine(AnalysisLine, AnalysisLine.Type::"Item Group");

        // Exercise: Insert Analysis Line with Type - Item Group.
        InsertAnalysisLine.InsertItemGrDim(AnalysisLine);

        // Verify: Check that the Analysis line for the particular Template and Type is available.
        VerifyAnalysisLine(AnalysisLine.Type::"Item Group", AnalysisLineTemplateName);

        // Tear Down.
        UpdateInventorySetup(InventorySetup."Item Group Dimension Code");
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisLineForCustomer()
    var
        Customer: Record Customer;
        AnalysisLine: Record "Analysis Line";
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        LibrarySales: Codeunit "Library - Sales";
        AnalysisLineTemplateName: Code[10];
    begin
        // Setup: Create Customer. Create Analysis Line template and partial Analysis Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        AnalysisLineTemplateName := CreatePartialAnalysisLine(AnalysisLine, AnalysisLine.Type::Customer);

        // Exercise: Insert Analysis Line with Type - Customer.
        InsertAnalysisLine.InsertCust(AnalysisLine);

        // Verify: Check that the Analysis line for the particular Template and Type is available.
        VerifyAnalysisLine(AnalysisLine.Type::Customer, AnalysisLineTemplateName);
    end;

    [Test]
    [HandlerFunctions('DimensionValueListPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisLineForCustomerGroups()
    var
        AnalysisLine: Record "Analysis Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        AnalysisLineTemplateName: Code[10];
    begin
        // Setup: Select Customer Group Dimension Code. Create Analysis Line template and partial Analysis Line.
        Initialize();
        SalesReceivablesSetup.Get();
        DimensionCode := SalesReceivablesSetup."Customer Group Dimension Code";
        AnalysisLineTemplateName := CreatePartialAnalysisLine(AnalysisLine, AnalysisLine.Type::"Customer Group");

        // Exercise: Insert Analysis Line with Type - Customer Group.
        InsertAnalysisLine.InsertCustGrDim(AnalysisLine);

        // Verify: Check that the Analysis line for the particular Template and Type is available.
        VerifyAnalysisLine(AnalysisLine.Type::"Customer Group", AnalysisLineTemplateName);
    end;

    [Test]
    [HandlerFunctions('DimensionValueListPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisLineForSalesperson()
    var
        AnalysisLine: Record "Analysis Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        AnalysisLineTemplateName: Code[10];
    begin
        // Setup: Select Salesperson Dimension Code. Create Analysis Line template and partial Analysis Line.
        Initialize();
        SalesReceivablesSetup.Get();
        DimensionCode := SalesReceivablesSetup."Salesperson Dimension Code";
        AnalysisLineTemplateName := CreatePartialAnalysisLine(AnalysisLine, AnalysisLine.Type::"Sales/Purchase person");

        // Exercise: Insert Analysis Line with Type - Sales/Purchase person.
        InsertAnalysisLine.InsertSalespersonPurchaser(AnalysisLine);

        // Verify: Check that the Analysis line for the particular Template and Type is available.
        VerifyAnalysisLine(AnalysisLine.Type::"Sales/Purchase person", AnalysisLineTemplateName);
    end;

    [Test]
    [HandlerFunctions('ItemListPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysesLineRowRefNoLength()
    var
        Item: Record Item;
        AnalysisLine: Record "Analysis Line";
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        AnalysisLineTemplateName: Code[10];
    begin
        // [FEATURE] [UT] [Analysis Line]
        // [SCENARIO 375383] Lenght of "Row Ref No." field of "Analysis Line" table should be brought into line with lenght of "No." field of "Item" table

        // [GIVEN] Item "I" with "No." = "X", where lenght of "X" is 20
        ItemNo := PadStr(Item."No.", MaxStrLen(Item."No."), '0');
        Item.Init();
        Item."No." := ItemNo;
        Item.Insert();
        AnalysisLineTemplateName := CreatePartialAnalysisLine(AnalysisLine, AnalysisLine.Type::Item);

        // [WHEN] "Insert Lines" for Item "I" into Analyses Line
        InsertAnalysisLine.InsertItems(AnalysisLine);

        // [THEN] Analyses Line is created with "Row Ref No." = "X"
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLineTemplateName);
        AnalysisLine.SetRange(Type, AnalysisLine.Type::Item);
        AnalysisLine.FindFirst();
        AnalysisLine.TestField("Row Ref. No.", ItemNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Analysis Line");
        LibraryApplicationArea.EnableFoundationSetup();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Analysis Line");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Analysis Line");
    end;

    local procedure UpdateInventorySetup(ItemGroupDimensionCode: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Item Group Dimension Code", ItemGroupDimensionCode);
        InventorySetup.Modify(true);
    end;

    local procedure CreatePartialAnalysisLine(var AnalysisLine: Record "Analysis Line"; Type: Enum "Analysis Line Type") AnalysisLineTemplateName: Code[10]
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        LibraryUtility: Codeunit "Library - Utility";
        RecRef: RecordRef;
    begin
        // Create New Analysis Line Template and partial Analysis Line.
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        AnalysisLine.Validate("Analysis Area", AnalysisLine."Analysis Area"::Sales);
        AnalysisLine.Validate("Analysis Line Template Name", AnalysisLineTemplate.Name);
        RecRef.GetTable(AnalysisLine);
        AnalysisLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, AnalysisLine.FieldNo("Line No.")));
        AnalysisLine.Validate(Type, Type);
        AnalysisLineTemplateName := AnalysisLine."Analysis Line Template Name";
    end;

    local procedure VerifyAnalysisLine(Type: Enum "Analysis Line Type"; AnalysisLineTemplateName: Code[10])
    var
        AnalysisLine: Record "Analysis Line";
    begin
        // Verify that Analysis line record for the particular Analysis line template is available.
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLineTemplateName);
        AnalysisLine.SetRange(Type, Type);
        AnalysisLine.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListPageHandler(var ItemList: Page "Item List"; var Response: Action)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        ItemList.SetRecord(Item);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionValueListPageHandler(var DimensionValueList: Page "Dimension Value List"; var Response: Action)
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        DimensionValueList.SetRecord(DimensionValue);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandler(var CustomerList: Page "Customer List"; var Response: Action)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        CustomerList.SetRecord(Customer);
        Response := ACTION::LookupOK;
    end;
}

