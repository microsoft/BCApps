codeunit 101024 "Create Vendor Invoice Disc."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('10000', 0, 5, 0, '');
        InsertData('20000', 0, 10, 0, '');
        InsertData('K1', 42808.219, 5, 0, '');
        InsertData('K1', 6000, 5, 0, 'EUR');
        InsertData('K1', 8000, 5, 0, 'USD');
    end;

    var
        "Vendor Invoice Disc.": Record "Vendor Invoice Disc.";
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("Code": Code[10]; "Minimum Amount": Decimal; "Discount %": Decimal; "Service Charge": Decimal; "Currency Code": Code[5])
    begin
        if "Currency Code" = DemoDataSetup."Currency Code" then
            exit;
        "Vendor Invoice Disc.".Init();
        "Vendor Invoice Disc.".Validate(Code, Code);
        if "Currency Code" = '' then
            "Vendor Invoice Disc.".Validate("Minimum Amount",
              Round(
                "Minimum Amount" * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"))
        else
            "Vendor Invoice Disc.".Validate("Minimum Amount", "Minimum Amount");
        "Vendor Invoice Disc.".Validate("Discount %", "Discount %");
        "Vendor Invoice Disc.".Validate("Service Charge", "Service Charge");
        "Vendor Invoice Disc.".Validate("Currency Code", "Currency Code");
        "Vendor Invoice Disc.".Insert();
    end;
}

