codeunit 134298 "Test Platform Event"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Event] [Sales] [Order] [Release] [UI]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        TestPlatformEvent: Codeunit "Test Platform Event";

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderReleaseOnActionEventSubscriber()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup
        BindSubscription(TestPlatformEvent);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(1, 10, 0));
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // Exercise
        SalesOrder.Release.Invoke();

        // Verify;
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual(SalesHeader.Status::Released, SalesHeader.Status, 'Sales Order is not released');
        VerifyDataTypeBuffer(StrSubstNo('Sales Order Release: %1', SalesHeader."No."))
    end;

    local procedure InsertDataTypeBuffer(EventText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        if DataTypeBuffer.FindLast() then;

        DataTypeBuffer.Init();
        DataTypeBuffer.ID += 1;
        DataTypeBuffer.Text := CopyStr(EventText, 1, 30);
        DataTypeBuffer.Insert(true);
    end;

    local procedure VerifyDataTypeBuffer(VerifyText: Text)
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        DataTypeBuffer.SetRange(Text, VerifyText);
        Assert.IsFalse(DataTypeBuffer.IsEmpty, 'The event was not executed');
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order", 'OnAfterActionEvent', 'Release', false, false)]
    local procedure InsertDataTypeBufferOnAfterSalesOrderReleaseActionEvent(var Rec: Record "Sales Header")
    begin
        InsertDataTypeBuffer(StrSubstNo('Sales Order Release: %1', Rec."No."));
    end;
}

