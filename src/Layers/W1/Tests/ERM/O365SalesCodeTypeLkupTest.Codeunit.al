codeunit 134654 "O365 Sales Code Type Lkup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Standard Code] [Line Subtype] [UI] [SaaS] [UT]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCodesTypeFieldVisibilityNonSaaS()
    var
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Standard Sales Code page
        StandardSalesCodeCard.OpenNew();

        // [THEN] The Type field is visible and the SaaS type field is not
        Assert.IsTrue(StandardSalesCodeCard.StdSalesLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(StandardSalesCodeCard.StdSalesLines.FilteredTypeField.Visible(),
          'SaaS type field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCodesTypeFieldVisibilitySaaS()
    var
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
    begin
        // [SCENARIO] Show the SaaS type field in SaaS environment
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new standard Sales code page
        StandardSalesCodeCard.OpenNew();

        // [THEN] The SaaS type field is visible and the type field is not
        asserterror StandardSalesCodeCard.StdSalesLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(StandardSalesCodeCard.StdSalesLines.FilteredTypeField.Visible(),
          'SaaS type field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure StandardSalesCodesrSaaSTypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
    begin
        // [SCENARIO] The lookup on SaaS type contains the expected values for Standard Sales Code and all values can be selected.
        Initialize();

        // [GIVEN] A standard Sales code
        StandardSalesCodeCard.OpenNew();
        StandardSalesCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardSalesCode.Code));
        StandardSalesCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardSalesCodeCard."Currency Code".Value := CreateOrFindCurrency();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Sales);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the SaaS type lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            StandardSalesCodeCard.StdSalesLines.FilteredTypeField.Lookup();

            // [THEN] The SaaS type is set to service
            StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCodesSaaSTypeAutoComplete()
    var
        StandardSalesLine: Record "Standard Sales Line";
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
    begin
        // [SCENARIO] A partial SaaS type is entered into the type field triggers autocomplete
        Initialize();

        // [GIVEN] A standard Sales code
        StandardSalesCodeCard.OpenNew();
        StandardSalesCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardSalesCode.Code));
        StandardSalesCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardSalesCodeCard."Currency Code".Value := CreateOrFindCurrency();

        // [WHEN] Setting the saas type on the standard Sales Line to ac
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue(
          CopyStr(Format(StandardSalesLine.Type::"G/L Account"), 1, 2));
        // [THEN] The SaaS type is set to G/L Account
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(Format(StandardSalesLine.Type::"G/L Account"));

        // [WHEN] Setting the saas type on the standard Sales Line to in
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue(CopyStr(Format(StandardSalesLine.Type::Item), 1, 2));
        // [THEN] The SaaS type is set to Item
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(Format(StandardSalesLine.Type::Item));

        // [WHEN] Setting the saas type on the standard Sales Line to co
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue(CopyStr(StandardSalesLine.FormatType(), 1, 2));
        // [THEN] The SaaS type is set to Comment
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(StandardSalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCodesSaaSTypeBlank()
    var
        StandardSalesLine: Record "Standard Sales Line";
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
    begin
        // [SCENARIO] A partial SaaS type is entered into the SaaS type field triggers autocomplete
        Initialize();

        // [GIVEN] A standard Sales code
        StandardSalesCodeCard.OpenNew();
        StandardSalesCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardSalesCode.Code));
        StandardSalesCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardSalesCodeCard."Currency Code".Value := CreateOrFindCurrency();

        // [WHEN] Setting the saas type on the standard Sales Line to ' '
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue(' ');
        // [THEN] The SaaS type is set to Blank
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(StandardSalesLine.FormatType());

        // [WHEN] Setting the saas type on the standard Sales Line to ''
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue('');
        // [THEN] The SaaS type is set to Blank
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(StandardSalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCodesDisallowedSaaSTypes()
    var
        StandardSalesLine: Record "Standard Sales Line";
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
    begin
        // [SCENARIO] When invalid values are entered into SaaS type, an Item Subtype is selected
        Initialize();

        // [GIVEN] A standard Sales code
        StandardSalesCodeCard.OpenNew();
        StandardSalesCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardSalesCode.Code));
        StandardSalesCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardSalesCodeCard."Currency Code".Value := CreateOrFindCurrency();

        // [WHEN] Setting the saas type to Fixed Asset on the standard Sales Line
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue(Format(StandardSalesLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(Format(StandardSalesLine.Type::Item));

        // [WHEN] Setting the saas type to a random value on the standard Sales Line
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.AssertEquals(Format(StandardSalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardSalesCodeSaaSTypeGLAccount()
    var
        StandardSalesLine: Record "Standard Sales Line";
        StandardSalesCodeCard: TestPage "Standard Sales Code Card";
        StandardSalesCodeValue: Code[10];
        GLAccNo: Code[20];
    begin
        // [SCENARIO 225925] Stan can create Standard Sales Code with Type = G/L Account under SaaS

        // [GIVEN] SaaS
        // Called by LibraryApplicationArea.EnableFoundationSetup();
        Initialize();

        StandardSalesCodeValue := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardSalesLine."Standard Sales Code"));

        // [GIVEN] Open "Standard Sales Code" card and assign "X" to Code
        StandardSalesCodeCard.OpenNew();
        StandardSalesCodeCard.Code.Value := StandardSalesCodeValue;

        // [WHEN] Validate Type with "G/L Account" and "No." with new "G/L Account" = "Y"
        StandardSalesCodeCard.StdSalesLines.FilteredTypeField.SetValue(Format(StandardSalesLine.Type::"G/L Account"));
        GLAccNo := LibraryERM.CreateGLAccountWithSalesSetup();
        StandardSalesCodeCard.StdSalesLines."No.".SetValue(GLAccNo);
        StandardSalesCodeCard.Close();

        // [THEN] Standard Sales Line with code "X", Type = "G/L Account" and "No." = "Y"
        StandardSalesLine.Get(StandardSalesCodeValue, 10000);
        StandardSalesLine.TestField(Type, StandardSalesLine.Type::"G/L Account");
        StandardSalesLine.TestField("No.", GLAccNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Sales Code Type Lkup Test");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateOrFindCurrency(): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        if not Currency.FindFirst() then begin
            LibraryERM.CreateCurrency(Currency);
            LibraryERM.CreateRandomExchangeRate(Currency.Code);
        end;
        exit(Currency.Code);
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
}

