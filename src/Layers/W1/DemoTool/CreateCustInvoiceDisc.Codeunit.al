codeunit 101019 "Create Cust. Invoice Disc."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('10000', 0, 5, 0, '');
        InsertData('20000', 0, 3, 0, '');
        InsertData('A', 85616.438, 5, 0, '');
        InsertData('A', 12607.8, 5, 0, 'EUR');
    end;

    var
        "Cust. Invoice Disc.": Record "Cust. Invoice Disc.";
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("Code": Code[20]; "Minimum Amount": Decimal; "Discount %": Decimal; "Service Charge": Decimal; "Currency Code": Code[5])
    begin
        if "Currency Code" = DemoDataSetup."Currency Code" then
            exit;
        "Cust. Invoice Disc.".Init();
        "Cust. Invoice Disc.".Validate(Code, Code);
        if "Currency Code" = '' then
            "Cust. Invoice Disc.".Validate(
              "Minimum Amount", Round(
                "Minimum Amount" * DemoDataSetup."Local Currency Factor",
                1 * DemoDataSetup."Local Precision Factor"))
        else
            "Cust. Invoice Disc.".Validate("Minimum Amount", "Minimum Amount");
        "Cust. Invoice Disc.".Validate("Discount %", "Discount %");
        "Cust. Invoice Disc.".Validate("Service Charge", "Service Charge");
        "Cust. Invoice Disc.".Validate("Currency Code", "Currency Code");
        "Cust. Invoice Disc.".Insert();
    end;
}

