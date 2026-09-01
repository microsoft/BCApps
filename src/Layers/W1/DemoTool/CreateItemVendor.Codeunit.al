codeunit 101099 "Create Item Vendor"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('70000', '30000', '<2D>', '6789-11');
        InsertData('70001', '30000', '<2D>', '6789-12');
        InsertData('70002', '30000', '<2D>', '6789-13');
        InsertData('70003', '30000', '<2D>', '6789-14');
        InsertData('70010', '30000', '<1W>', '22-T-111');
        InsertData('70011', '30000', '<14D>', '22-G-111');
        InsertData('70040', '30000', '<2D>', '4554-201');
        InsertData('70041', '30000', '<2D>', '4554-310');
        InsertData('70060', '30000', '<3D>', '3-47/55');
        InsertData('70100', '30000', '<1W>', 'P-ProBlack');
        InsertData('70101', '30000', '<1W>', 'P-102');
        InsertData('70102', '30000', '<1W>', 'P-2695');
        InsertData('70103', '30000', '<1W>', 'P-1795');
        InsertData('70104', '30000', '<1W>', 'P-3292');
        InsertData('70200', '30000', '<2D>', '3/47-202');
        InsertData('70201', '30000', '<1W>', '3-47/2205');
    end;

    var
        "Item Vendor": Record "Item Vendor";
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("Item No.": Code[20]; "Vendor No.": Code[20]; "Lead Time Calculation": Text[20]; "Vendor Item No.": Text[20])
    begin
        "Item Vendor".Init();
        "Item Vendor".Validate("Item No.", "Item No.");
        "Item Vendor".Validate("Vendor No.", "Vendor No.");
        Evaluate("Item Vendor"."Lead Time Calculation", "Lead Time Calculation");
        "Item Vendor".Validate("Lead Time Calculation");
        "Item Vendor".Validate("Vendor Item No.", "Vendor Item No.");
        "Item Vendor".Insert();
    end;
}

