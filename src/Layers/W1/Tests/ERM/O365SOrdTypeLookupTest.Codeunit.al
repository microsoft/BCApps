codeunit 134646 "O365 S. Ord. Type Lookup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Order] [Line Subtype] [UI] [UT]
        IsInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderTypeFieldVisibilityNonSaaS()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Sales Order
        SalesOrder.OpenNew();

        // [THEN] The Type field is visible and the Subtype field is not
        Assert.IsTrue(SalesOrder.SalesLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(SalesOrder.SalesLines.FilteredTypeField.Visible(), 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderTypeFieldVisibilitySaaS()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new Sales Order
        SalesOrder.OpenNew();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror SalesOrder.SalesLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(SalesOrder.SalesLines.FilteredTypeField.Visible(), 'Subtype field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Sales Order and all values can be selected.
        Initialize();

        // [GIVEN] A Sales Order
        SalesOrder.OpenNew();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Sales);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            SalesOrder.SalesLines.FilteredTypeField.Lookup();

            // [THEN] The Subtype is set to service
            SalesOrder.SalesLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSubtypeAutoComplete()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete
        Initialize();

        // [GIVEN] A Sales Order
        SalesOrder.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to ac
        SalesOrder.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to in
        SalesOrder.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Inventory
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype on the Sales Line to co
        SalesOrder.SalesLines.FilteredTypeField.SetValue(CopyStr(SalesLine.FormatType(), 1, 2));
        // [THEN] The Subtype is set to Comment
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSubtypeBlank()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank
        Initialize();

        // [GIVEN] A Sales Order
        SalesOrder.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to ' '
        SalesOrder.SalesLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());

        // [WHEN] Setting the Subtype on the Sales Line to ''
        SalesOrder.SalesLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDisallowedSubtypes()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, an error is raised
        Initialize();

        // [GIVEN] A Sales Order
        SalesOrder.OpenNew();

        // [WHEN] Setting the Subtype to Fixed Asset on the Sales Line
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to Resource on the Sales Line
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Resource));
        // [THEN] The Subtype is set to Item
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to a random value on the Sales Line
        SalesOrder.SalesLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNotMatchedSubtypeWhenTypeIsBlank()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 252686] When Subtype is blank and non standard value is entered into Subtype, Subtype = Item is assigned.
        Initialize();

        // [GIVEN] A blank Sales Order.
        SalesOrder.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        SalesOrder.SalesLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is set to Item.
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNotMatchedSubtypeWhenTypeIsNotBlank()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 252686] When Subtype is not blank and non standard value is entered into Subtype, Subtype is not changed.
        Initialize();

        // [GIVEN] A Sales Order with a line with Subtype = G/L Account.
        SalesOrder.OpenNew();
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        SalesOrder.SalesLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is not changed.
        SalesOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OptionLookupListModalHandler(var OptionLookupList: TestPage "Option Lookup List")
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
    begin
        TempOptionLookupBuffer.FillLookupBuffer(
            "Option Lookup Type".FromInteger(LibraryVariableStorage.DequeueInteger()));
        TempOptionLookupBuffer.FindSet();
        repeat
            OptionLookupList.GotoKey(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;

        OptionLookupList.GotoKey(LibraryVariableStorage.DequeueText());
        OptionLookupList.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 S. Ord. Type Lookup Test");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 S. Ord. Type Lookup Test");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 S. Ord. Type Lookup Test");
    end;
}

