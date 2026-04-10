codeunit 134647 "O365 P. Inv. Type Lookup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Invoice] [Line Subtype] [UI] [UT]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTypeFieldVisibilityNonSaaS()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Show Type field in OnPrem environment
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Purchase Invoice
        PurchaseInvoice.OpenNew();

        // [THEN] The Type field is visible and the Subtype field is not
        Assert.IsTrue(PurchaseInvoice.PurchLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(PurchaseInvoice.PurchLines.FilteredTypeField.Visible(), 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTypeFieldVisibilitySaaS()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new Purchase Invoice
        PurchaseInvoice.OpenNew();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror PurchaseInvoice.PurchLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(PurchaseInvoice.PurchLines.FilteredTypeField.Visible(), 'Subtype field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Purchase Invoice and all values can be selected.
        Initialize();

        // [GIVEN] A Purchase Invoice
        PurchaseInvoice.OpenNew();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Purchases);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            PurchaseInvoice.PurchLines.FilteredTypeField.Lookup();

            // [THEN] The Subtype is set to service
            PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceSubtypeAutoComplete()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete
        Initialize();

        // [GIVEN] A Purchase Invoice
        PurchaseInvoice.OpenNew();

        // [WHEN] Setting the Subtype on the Purchase Line to ac
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Purchase Line to in
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Inventory
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));

        // [WHEN] Setting the Subtype on the Purchase Line to co
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(CopyStr(PurchaseLine.FormatType(), 1, 2));
        // [THEN] The Subtype is set to Comment
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceSubtypeBlank()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank
        Initialize();

        // [GIVEN] A Purchase Invoice
        PurchaseInvoice.OpenNew();

        // [WHEN] Setting the Subtype on the Purchase Line to ' '
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());

        // [WHEN] Setting the Subtype on the Purchase Line to ''
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceDisallowedSubtypes()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, an error is raised
        Initialize();

        // [GIVEN] A Purchase Invoice
        PurchaseInvoice.OpenNew();

        // [WHEN] Setting the Subtype to Fixed Asset on the Purchase Line
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.Type::Item);

        // [WHEN] Setting the Subtype to a random value on the Purchase Line
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceNotMatchedSubtypeWhenTypeIsBlank()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 252686] When Subtype is blank and non standard value is entered into Subtype, Subtype = Item is assigned.
        Initialize();

        // [GIVEN] A blank Purchase Invoice.
        PurchaseInvoice.OpenNew();

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is set to Item.
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceNotMatchedSubtypeWhenTypeIsNotBlank()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 252686] When Subtype is not blank and non standard value is entered into Subtype, Subtype is not changed.
        Initialize();

        // [GIVEN] A Purchase Invoice with a line with Subtype = G/L Account.
        PurchaseInvoice.OpenNew();
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Setting the Subtype on the Sales Line to "AAA".
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue('AAA');

        // [THEN] The Subtype is not changed.
        PurchaseInvoice.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::"G/L Account"));
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 P. Inv. Type Lookup Test");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
    end;
}

