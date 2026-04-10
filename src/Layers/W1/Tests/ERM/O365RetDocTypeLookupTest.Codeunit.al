codeunit 134655 "O365 Ret. Doc Type Lookup Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Sales] [Return Order] [Line Subtype] [UI] [UT]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderTypeFieldVisibilityNonSaaS()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] Show Type field in OnPrem environment for Sales Return Order
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Sales Return Order
        SalesReturnOrder.OpenNew();

        // [THEN] The Type field is visible and the subtype field is not
        Assert.IsTrue(SalesReturnOrder.SalesLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(SalesReturnOrder.SalesLines.FilteredTypeField.Visible(), 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderTypeFieldVisibilitySaaS()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment for Sales Return Order
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new Sales Return Order
        SalesReturnOrder.OpenNew();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror SalesReturnOrder.SalesLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(SalesReturnOrder.SalesLines.FilteredTypeField.Visible(), 'Subtype field should be visible for OnPrem');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Sales Return Order and all values can be selected.
        Initialize();

        // [GIVEN] A Sales Return Order
        SalesReturnOrder.OpenNew();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Sales);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            SalesReturnOrder.SalesLines.FilteredTypeField.Lookup();

            // [THEN] The subtype is set to service
            SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSubtypeAutoComplete()
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete for Sales Return Order
        Initialize();

        // [GIVEN] A Sales Return Order
        SalesReturnOrder.OpenNew();

        // [WHEN] Setting the subtype on the Sales Line to ac
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::"G/L Account"));

        // [WHEN] Setting the subtype on the Sales Line to in
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(CopyStr(Format(SalesLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Inventory
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the subtype on the Sales Line to co
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(CopyStr(SalesLine.FormatType(), 1, 2));
        // [THEN] The Subtype is set to Comment
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderSubtypeBlank()
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank for Sales Return Order
        Initialize();

        // [GIVEN] A Sales Return Order
        SalesReturnOrder.OpenNew();

        // [WHEN] Setting the subtype on the Sales Line to ' '
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());

        // [WHEN] Setting the subtype on the Sales Line to ''
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(SalesLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderDisallowedSubtypes()
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, an Item Subtype is selected
        Initialize();
        LibraryApplicationArea.EnableSalesReturnOrderSetup();

        // [GIVEN] A Sales Return Order
        SalesReturnOrder.OpenNew();

        // [WHEN] Setting the subtype to Fixed Asset on the Sales Line
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the subtype to Resource on the Sales Line
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Resource));
        // [THEN] The Subtype is set to Item
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));

        // [WHEN] Setting the subtype to a random value on the Sales Line
        SalesReturnOrder.SalesLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        SalesReturnOrder.SalesLines.FilteredTypeField.AssertEquals(Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderTypeFieldVisibilityNonSaaS()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] Show Type field in OnPrem environment for Purchase Return Order
        Initialize();

        // [GIVEN] An OnPrem environment
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [WHEN] Opening a new Purchase Return Order
        PurchaseReturnOrder.OpenNew();

        // [THEN] The Type field is visible and the subtype field is not
        Assert.IsTrue(PurchaseReturnOrder.PurchLines.Type.Visible(), 'Regular type field should be visible for OnPrem');
        Assert.IsFalse(PurchaseReturnOrder.PurchLines.FilteredTypeField.Visible(), 'Subtype field should not be visible for OnPrem');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderTypeFieldVisibilitySaaS()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] Show the Subtype field in SaaS environment for Purchase Return Order
        Initialize();

        // [GIVEN] A SaaS environment

        // [WHEN] Opening a new Purchase Return Order
        PurchaseReturnOrder.OpenNew();

        // [THEN] The Subtype field is visible and the type field is not
        asserterror PurchaseReturnOrder.PurchLines.Type.Activate();
        Assert.ExpectedError('not found on the page');
        Assert.IsTrue(PurchaseReturnOrder.PurchLines.FilteredTypeField.Visible(), 'Subtype field should be visible for SaaS');
    end;

    [Test]
    [HandlerFunctions('OptionLookupListModalHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderSubtypeLookupTryAllOptions()
    var
        TempOptionLookupBuffer: Record "Option Lookup Buffer" temporary;
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] The lookup on Subtype contains the expected values for Purchase Return Order and all values can be selected.
        Initialize();

        // [GIVEN] A Purchase Return Order
        PurchaseReturnOrder.OpenNew();

        TempOptionLookupBuffer.FillLookupBuffer(TempOptionLookupBuffer."Lookup Type"::Purchases);
        TempOptionLookupBuffer.FindSet();
        repeat
            // [WHEN] Opening the Subtype lookup and selecting service
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Lookup Type");
            LibraryVariableStorage.Enqueue(TempOptionLookupBuffer."Option Caption");
            PurchaseReturnOrder.PurchLines.FilteredTypeField.Lookup();

            // [THEN] The subtype is set to service
            PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(TempOptionLookupBuffer."Option Caption");
        until TempOptionLookupBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderSubtypeAutoComplete()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] A partial Subtype is entered into the Subtype field triggers autocomplete for Purchase Return Order
        Initialize();

        // [GIVEN] A Purchase Return Order
        PurchaseReturnOrder.OpenNew();

        // [WHEN] Setting the subtype on the Purchase Line to ac
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::"G/L Account"), 1, 2));
        // [THEN] The Subtype is set to G/L Account
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::"G/L Account"));

        // [WHEN] Setting the subtype on the Purchase Line to in
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue(CopyStr(Format(PurchaseLine.Type::Item), 1, 2));
        // [THEN] The Subtype is set to Inventory
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));

        // [WHEN] Setting the subtype on the Purchase Line to co
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue(CopyStr(PurchaseLine.FormatType(), 1, 2));
        // [THEN] The Subtype is set to Comment
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderSubtypeBlank()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] A blank Subtype is entered into the Subtype field stays blank for Purchase Return Order
        Initialize();

        // [GIVEN] A Purchase Return Order
        PurchaseReturnOrder.OpenNew();

        // [WHEN] Setting the subtype on the Purchase Line to ' '
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue(' ');
        // [THEN] The Subtype is set to Blank
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());

        // [WHEN] Setting the subtype on the Purchase Line to ''
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue('');
        // [THEN] The Subtype is set to Blank
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(PurchaseLine.FormatType());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderDisallowedSubtypes()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO] When invalid values are entered into Subtype, an Item is selected
        Initialize();
        LibraryApplicationArea.EnablePurchaseReturnOrderSetup();

        // [GIVEN] A Purchase Return Order
        PurchaseReturnOrder.OpenNew();

        // [WHEN] Setting the subtype to Fixed Asset on the Purchase Line
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::"Fixed Asset"));
        // [THEN] The Subtype is set to Item
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));

        // [WHEN] Setting the subtype to a random value on the Purchase Line
        PurchaseReturnOrder.PurchLines.FilteredTypeField.SetValue(LibraryUtility.GenerateGUID());
        // [THEN] The Subtype is set to Item
        PurchaseReturnOrder.PurchLines.FilteredTypeField.AssertEquals(Format(PurchaseLine.Type::Item));
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
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Ret. Doc Type Lookup Test");
        LibraryApplicationArea.EnableReturnOrderSetup();
        LibraryVariableStorage.Clear();
    end;
}

