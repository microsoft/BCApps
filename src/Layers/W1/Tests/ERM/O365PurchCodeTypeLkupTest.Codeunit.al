codeunit 134653 "O365 Purch Code Type Lkup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Standard Code] [Line Subtype] [UI] [SaaS] [UT]
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
    procedure StandardPurchaseCodesTypeFieldVisibilityNonSaaS()
    var
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Standard Purchase Code page
        StandardPurchaseCodeCard.OpenNew();

        // [THEN] The Type field is visible and the SaaS type field is not
        Assert.IsTrue(StandardPurchaseCodeCard.StdPurchaseLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.Visible(),
          'SaaS type field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodesTypeFieldVisibilitySaaS()
    var
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [SCENARIO] Show the SaaS type field in SaaS environment
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new standard purchase code page
        StandardPurchaseCodeCard.OpenNew();

        // [THEN] The SaaS type field is visible and the type field is not
        asserterror StandardPurchaseCodeCard.StdPurchaseLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.Visible(),
          'SaaS type field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodesrSaaSTypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [SCENARIO] The lookup on SaaS type contains the expected values for Standard Purchase Code and all values can be selected.
        Initialize();

        // [GIVEN] A standard purchase code
        StandardPurchaseCodeCard.OpenNew();
        StandardPurchaseCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardPurchaseCode.Code));
        StandardPurchaseCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardPurchaseCodeCard."Currency Code".Value := CreateOrFindCurrency();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Purchases);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the SaaS type lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.Lookup();

            // [THEN] The SaaS type is set to service
            StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodesSaaSTypeAutoComplete()
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [SCENARIO] A partial SaaS type is entered into the type field triggers autocomplete
        Initialize();

        // [GIVEN] A standard purchase code
        StandardPurchaseCodeCard.OpenNew();
        StandardPurchaseCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardPurchaseCode.Code));
        StandardPurchaseCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardPurchaseCodeCard."Currency Code".Value := CreateOrFindCurrency();

        // [WHEN] Setting the saas type on the standard Purchase Line to ac
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue(
          CopyStr(Format(StandardPurchaseLine.Type::"G/L Account"), 1, 2));
        // [THEN] The SaaS type is set to G/L Account
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(Format(StandardPurchaseLine.Type::"G/L Account"));

        // [WHEN] Setting the saas type on the standard Purchase Line to in
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue(CopyStr(Format(StandardPurchaseLine.Type::Item), 1, 2));
        // [THEN] The SaaS type is set to Item
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(Format(StandardPurchaseLine.Type::Item));

        // [WHEN] Setting the saas type on the standard Purchase Line to co
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue(CopyStr(StandardPurchaseLine.FormatType(), 1, 2));
        // [THEN] The SaaS type is set to Comment
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(StandardPurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodesSaaSTypeBlank()
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [SCENARIO] A partial SaaS type is entered into the SaaS type field triggers autocomplete
        Initialize();

        // [GIVEN] A standard purchase code
        StandardPurchaseCodeCard.OpenNew();
        StandardPurchaseCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardPurchaseCode.Code));
        StandardPurchaseCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardPurchaseCodeCard."Currency Code".Value := CreateOrFindCurrency();

        // [WHEN] Setting the saas type on the standard Purchase Line to ' '
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue(' ');
        // [THEN] The SaaS type is set to Blank
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(StandardPurchaseLine.FormatType());

        // [WHEN] Setting the saas type on the standard Purchase Line to ''
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue('');
        // [THEN] The SaaS type is set to Blank
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(StandardPurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodesDisallowedSaaSTypes()
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardPurchaseCode: Record "Standard Purchase Code";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
    begin
        // [SCENARIO] When invalid values are entered into SaaS type, an Item Subtype is selected
        Initialize();

        // [GIVEN] A standard purchase code
        StandardPurchaseCodeCard.OpenNew();
        StandardPurchaseCodeCard.Code.Value := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardPurchaseCode.Code));
        StandardPurchaseCodeCard.Description.Value := LibraryUtility.GenerateGUID();
        StandardPurchaseCodeCard."Currency Code".Value := CreateOrFindCurrency();

        // [WHEN] Setting the saas type to Fixed Asset on the standard Purchase Line
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue(Format(StandardPurchaseLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(Format(StandardPurchaseLine.Type::Item));

        // [WHEN] Setting the saas type to a random value on the standard Purchase Line
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.AssertEquals(Format(StandardPurchaseLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardPurchaseCodeSaaSTypeGLAccount()
    var
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardPurchaseCodeCard: TestPage "Standard Purchase Code Card";
        StandardPurchaseCodeValue: Code[10];
        GLAccNo: Code[20];
    begin
        // [SCENARIO 225925] Stan can create Standard Purchase Code with Type = G/L Account under SaaS

        // [GIVEN] SaaS
        // Called by LibraryApplicationArea.EnableFoundationSetup();
        Initialize();

        StandardPurchaseCodeValue := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(StandardPurchaseLine."Standard Purchase Code"));

        // [GIVEN] Open "Standard Purchase Code" card and assign "X" to Code
        StandardPurchaseCodeCard.OpenNew();
        StandardPurchaseCodeCard.Code.Value := StandardPurchaseCodeValue;

        // [WHEN] Validate Type with "G/L Account" and "No." with new "G/L Account" = "Y"
        StandardPurchaseCodeCard.StdPurchaseLines.FilteredTypeField.SetValue(Format(StandardPurchaseLine.Type::"G/L Account"));
        GLAccNo := LibraryERM.CreateGLAccountWithPurchSetup();
        StandardPurchaseCodeCard.StdPurchaseLines."No.".SetValue(GLAccNo);
        StandardPurchaseCodeCard.Close();

        // [THEN] Standard Purchase Line with code "X", Type = "G/L Account" and "No." = "Y"
        StandardPurchaseLine.Get(StandardPurchaseCodeValue, 10000);
        StandardPurchaseLine.TestField(Type, StandardPurchaseLine.Type::"G/L Account");
        StandardPurchaseLine.TestField("No.", GLAccNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Purch Code Type Lkup Test");
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

