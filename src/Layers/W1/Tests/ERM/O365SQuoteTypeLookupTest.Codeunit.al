codeunit 134648 "O365 S. Quote Type Lookup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Quote] [Line Subtype] [UI] [UT]
        IsInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteTypeFieldVisibilityNonSaaS()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Sales Quote
        SalesQuote.OpenNew();

        // [THEN] The Type field is visible and the Subtype field is not
        Assert.IsTrue(SalesQuote.SalesLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(SalesQuote.SalesLines.FilteredTypeField.Visible(), 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteTypeFieldVisibilitySaaS()
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment
        Initialize();

        // [WHEN] Opening a new Sales Quote
        SalesQuote.OpenNew();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror SalesQuote.SalesLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(SalesQuote.SalesLines.FilteredTypeField.Visible(), 'Subtype field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Sales Quote and all values can be selected.
        Initialize();

        // [GIVEN] A Sales Quote
        SalesQuote.OpenNew();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Sales);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            SalesQuote.SalesLines.FilteredTypeField.Lookup();

            // [THEN] The Subtype is set to service
            SalesQuote.SalesLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteSubtypeAutoComplete()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete
        Initialize();

        // [GIVEN] A Sales Quote
        SalesQuote.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to ac
        SalesQuote.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to in
        SalesQuote.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Inventory
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype on the Sales Line to co
        SalesQuote.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.FormatType()), 1, 2));
        // [THEN] The Subtype is set to Comment
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteSubtypeBlank()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank
        Initialize();

        // [GIVEN] A Sales Quote
        SalesQuote.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to ' '
        SalesQuote.SalesLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.FormatType()));

        // [WHEN] Setting the Subtype on the Sales Line to ''
        SalesQuote.SalesLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.FormatType()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteDisallowedSubtypes()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, an error is raised
        Initialize();

        // [GIVEN] A Sales Quote
        SalesQuote.OpenNew();

        // [WHEN] Setting the Subtype to Fixed Asset on the Sales Line
        SalesQuote.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to Resource on the Sales Line
        SalesQuote.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Resource));
        // [THEN] The Subtype is set to Item
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the Subtype to a random value on the Sales Line
        SalesQuote.SalesLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteNotMatchedSubtypeWhenTypeIsBlank()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 252686] When Subtype is blank and non standard value is entered into Subtype, Subtype = Item is assigned.
        Initialize();

        // [GIVEN] A blank Sales Quote.
        SalesQuote.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        SalesQuote.SalesLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is set to Item.
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteNotMatchedSubtypeWhenTypeIsNotBlank()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 252686] When Subtype is not blank and non standard value is entered into Subtype, Subtype is not changed.
        Initialize();

        // [GIVEN] A Sales Quote with a line with Subtype = G/L Account.
        SalesQuote.OpenNew();
        SalesQuote.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        SalesQuote.SalesLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is not changed.
        SalesQuote.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 S. Quote Type Lookup Test");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 S. Quote Type Lookup Test");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 S. Quote Type Lookup Test");
    end;
}

