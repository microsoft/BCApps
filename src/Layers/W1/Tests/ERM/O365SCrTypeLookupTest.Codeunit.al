codeunit 134650 "O365 S. Cr. Type Lookup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Credit Memo] [Line Subtype] [UI] [UT]
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
    procedure SalesCreditMemoTypeFieldVisibilityNonSaaS()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [THEN] The Type field is visible and the Subtype field is not
        Assert.IsTrue(SalesCreditMemo.SalesLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(SalesCreditMemo.SalesLines.FilteredTypeField.Visible(), 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoTypeFieldVisibilitySaaS()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror SalesCreditMemo.SalesLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(SalesCreditMemo.SalesLines.FilteredTypeField.Visible(), 'Subtype field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Sales credit memo and all values can be selected.
        Initialize();

        // [GIVEN] A Sales Credit Memo
        SalesCreditMemo.OpenNew();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Sales);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            SalesCreditMemo.SalesLines.FilteredTypeField.Lookup();

            // [THEN] The Subtype is set to service
            SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoSubtypeAutoComplete()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete
        Initialize();

        // [GIVEN] A Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to ac
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to in
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Inventory
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype on the Sales Line to co
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(CopyStr(SalesLine.FormatType(), 1, 2));
        // [THEN] The Subtype is set to Comment
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoSubtypeBlank()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank
        Initialize();

        // [GIVEN] A Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to ' '
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());

        // [WHEN] Setting the Subtype on the Sales Line to ''
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoDisallowedSubtypes()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, an error is raised
        Initialize();

        // [GIVEN] A Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype to Fixed Asset on the Sales Line
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to Resource on the Sales Line
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Resource));
        // [THEN] The Subtype is set to Item
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to a random value on the Sales Line
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoNotMatchedSubtypeWhenTypeIsBlank()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 252686] When Subtype is blank and non standard value is entered into Subtype, Subtype = Item is assigned.
        Initialize();

        // [GIVEN] A blank Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is set to Item.
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoMatchedSubtypeWhenTypeIsNotBlank()
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 252686] When Subtype is not blank and non standard value is entered into Subtype, Subtype is not changed.
        Initialize();

        // [GIVEN] A Sales Credit Memo with a line with Subtype = G/L Account.
        SalesCreditMemo.OpenNew();
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is not changed.
        SalesCreditMemo.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 S. Cr. Type Lookup Test");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 S. Cr. Type Lookup Test");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 S. Cr. Type Lookup Test");
    end;
}

