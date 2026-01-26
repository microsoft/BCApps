codeunit 144007 "UT PAG Address"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service Item] [UI]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordServiceItemCard()
    var
        ServiceItem: Record "Service Item";
        ServiceItemCard: TestPage "Service Item Card";
    begin
        // Purpose of the test is to validate Trigger OnAfterGetRecord of Page 5980 - Service Item Card.

        // Setup: Create Service Item.
        CreateServiceItem(ServiceItem);

        // Exercise.
        ServiceItemCard.OpenEdit();
        ServiceItemCard.FILTER.SetFilter("No.", ServiceItem."No.");

        // Verify: Verify Ship-to County Field on Page - Service Item Card.
        ServiceItem.CalcFields(County);
        ServiceItemCard."Ship-to County".AssertEquals(ServiceItem.County);
        ServiceItemCard.Close();
    end;


    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.County := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item")
    begin
        ServiceItem."No." := LibraryUTUtility.GetNewCode();
        ServiceItem."Customer No." := CreateCustomer();
        ServiceItem.Insert();
    end;
}
