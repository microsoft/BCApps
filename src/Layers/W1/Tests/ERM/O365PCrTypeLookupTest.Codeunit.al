codeunit 134651 "O365 P. Cr. Type Lookup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Line Subtype] [UI] [UT]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoTypeFieldVisibilityNonSaaS()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();

        // [THEN] The Type field is visible and the Subtype field is not
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(PurchaseCreditMemo.PurchLines.FilteredTypeField.Visible(), 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoTypeFieldVisibilitySaaS()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror PurchaseCreditMemo.PurchLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.FilteredTypeField.Visible(), 'Subtype field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Purchase Credit Memo and all values can be selected.
        Initialize();

        // [GIVEN] A Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Purchases);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            PurchaseCreditMemo.PurchLines.FilteredTypeField.Lookup();

            // [THEN] The Subtype is set to service
            PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoSubtypeAutoComplete()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete
        Initialize();

        // [GIVEN] A Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype on the Purchase Line to ac
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Purchase Line to in
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Inventory
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));

        // [WHEN] Setting the Subtype on the Purchase Line to co
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(CopyStr(PurchaseLine.FormatType(), 1, 2));
        // [THEN] The Subtype is set to Comment
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoSubtypeBlank()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank
        Initialize();

        // [GIVEN] A Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype on the Purchase Line to ' '
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());

        // [WHEN] Setting the Subtype on the Purchase Line to ''
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoDisallowedSubtypes()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, an error is raised
        Initialize();

        // [GIVEN] A Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype to Fixed Asset on the Purchase Line
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.Type::Item);

        // [WHEN] Setting the Subtype to a random value on the Purchase Line
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoNotMatchedSubtypeWhenTypeIsBlank()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 252686] When Subtype is blank and non standard value is entered into Subtype, Subtype = Item is assigned.
        Initialize();

        // [GIVEN] A blank Purchase Credit Memo
        PurchaseCreditMemo.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is set to Item.
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoNotMatchedSubtypeWhenTypeIsNotBlank()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 252686] When Subtype is not blank and non standard value is entered into Subtype, Subtype is not changed.
        Initialize();

        // [GIVEN] A Purchase Credit Memo with a line with Subtype = G/L Account.
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is not changed.
        PurchaseCreditMemo.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::"G/L Account"));
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 P. Cr. Type Lookup Test");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
    end;
}

