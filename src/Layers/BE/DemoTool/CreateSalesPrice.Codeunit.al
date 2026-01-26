codeunit 101028 "Create Sales Price"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        Item.Get('1936-S');
        InsertData(
          '1936-S', '', '', 19030120D,
          Round(
            Item."Unit Price" * 1.15, 1 *
            DemoDataSetup."Local Precision Factor"));
        InsertData('1972-W', '', '', 19030101D, 843.345);
    end;

    var
        SalesPrice: Record "Sales Price";
        DemoDataSetup: Record "Demo Data Setup";
        Item: Record Item;
        CA: Codeunit "Make Adjustments";

    procedure InsertData("Item No.": Code[20]; "Price Group Code": Code[10]; "Currency Code": Code[10]; "Starting Date": Date; "Unit Price": Decimal)
    begin
        if "Currency Code" = DemoDataSetup."Currency Code" then
            "Currency Code" := '';

        SalesPrice.Init();
        SalesPrice.Validate("Item No.", "Item No.");
        SalesPrice.Validate("Sales Type", SalesPrice."Sales Type"::"All Customers");
        SalesPrice.Validate("Sales Code", "Price Group Code");
        SalesPrice.Validate("Currency Code", "Currency Code");
        SalesPrice.Validate("Starting Date", CA.AdjustDate("Starting Date"));
        SalesPrice.Validate("Unit Price", "Unit Price");
        SalesPrice.Insert(true);
    end;
}
