codeunit 118000 "Interface Distribution"
{

    trigger OnRun()
    var
        DeleteDemoTable: Boolean;
    begin
        if not DemoDataSetup.Get() then begin
            DemoDataSetup.Init();
            DemoDataSetup."Progress Window Design" :=
              XDemonstrationDataTool3 +
              '#1#####################################\\' +
              '@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\';
            DemoDataSetup.Insert();
            DeleteDemoTable := true;
        end;

        CreateData();
        "Before Posting"();
        Post(CA.AdjustDate(19030126D));
        "After Posting"();

        if DeleteDemoTable then
            DemoDataSetup.Delete();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        ModSalesSetup: Codeunit "Dist. Modify Sales Setup";
        ModPurchaseSetup: Codeunit "Dist. Modify Purchase Setup";
        CA: Codeunit "Make Adjustments";
        XDemonstrationDataTool3: Label 'Demonstration Data Tool:#3#############\\';

    procedure CreateData()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Distribution Data');
        Steps := 0;
        MaxSteps := 18;

        RunCodeunit(CODEUNIT::"Create In-Transit Location");
        RunCodeunit(CODEUNIT::"Update Inventory Posting Setup");
        RunCodeunit(CODEUNIT::"Create Put-away Templates");
        RunCodeunit(CODEUNIT::"Create Transfer Route");
        RunCodeunit(CODEUNIT::"Create Responsibility Center");
        RunCodeunit(CODEUNIT::"Create Dist. Whse. Filter");
        RunCodeunit(CODEUNIT::"Create Dist. Item");
        RunCodeunit(CODEUNIT::"Create Dist. Item UOM");
        RunCodeunit(CODEUNIT::"Create Dist. Item Variants");
        RunCodeunit(CODEUNIT::"Create Stockkeeping Unit");
        RunCodeunit(CODEUNIT::"Create Item Substitution");
        RunCodeunit(CODEUNIT::"Create Item Cross Reference");
        RunCodeunit(CODEUNIT::"Create Catalog Item");
        RunCodeunit(CODEUNIT::"Create Dist. Customer");
        RunCodeunit(CODEUNIT::"Create Dist. Vendor");
        RunCodeunit(CODEUNIT::"Create Warehouse Mgt. Setup");
        RunCodeunit(CODEUNIT::"Create Availability Setup");
        RunCodeunit(CODEUNIT::"Create Shipping Agent Service");
        RunCodeunit(CODEUNIT::"Update Customer Ship. Service");
        RunCodeunit(CODEUNIT::"Item Tracking - Item");
        RunCodeunit(CODEUNIT::"Item Tracking - Item Transl.");
        RunCodeunit(CODEUNIT::"Create Warehouse Classes");
        RunCodeunit(CODEUNIT::"Create Bin Types");
        RunCodeunit(CODEUNIT::"Create Special Equipments");
        RunCodeunit(CODEUNIT::"Create Physical Inventory");
        RunCodeunit(CODEUNIT::"Create Zones / Bins");
        RunCodeunit(CODEUNIT::"Update Location");
        RunCodeunit(CODEUNIT::"Create Whse. Journal Template");
        RunCodeunit(CODEUNIT::"Create Whse. Journal Batch");
        RunCodeunit(CODEUNIT::"Create Whse. Wksh.-Template");
        RunCodeunit(CODEUNIT::"Create Whse. Wksh.-Name");
        RunCodeunit(CODEUNIT::"Create Bin Create Wksh.-Templ.");
        RunCodeunit(CODEUNIT::"Create Bin Create Wksh.-Name");
        RunCodeunit(CODEUNIT::"Create Dist. Production");
        RunCodeunit(CODEUNIT::"Add WMS BOM Component");

        // ADCS
        RunCodeunit(CODEUNIT::"Create Miniform Header");
        RunCodeunit(CODEUNIT::"Create Miniform Line");
        RunCodeunit(CODEUNIT::"Create Miniform Function Group");
        RunCodeunit(CODEUNIT::"Create Miniform Function");

        // Assembly
        RunCodeunit(CODEUNIT::"Create Assembly Setup");

        Window.Close();
    end;

    procedure "Before Posting"()
    begin
    end;

    procedure Post(PostingDate: Date)
    begin
        if PostingDate <> CA.AdjustDate(19030126D) then
            exit;

        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Distribution Post');
        Steps := 0;
        MaxSteps := 20;

        RunCodeunit(CODEUNIT::"Update Location");
        RunCodeunit(CODEUNIT::"Create Transfer Order");
        RunCodeunit(CODEUNIT::"Dist. Modify Sales Setup");
        RunCodeunit(CODEUNIT::"Dist. Create Sales Header");
        RunCodeunit(CODEUNIT::"Dist. Create Sales Line");
        RunCodeunit(CODEUNIT::"Dist. Release Sales Documents");
        RunCodeunit(CODEUNIT::"Dist. Create Whse. Shipments");
        RunCodeunit(CODEUNIT::"Dist. Create Whse. Shpt. Lines");
        RunCodeunit(CODEUNIT::"Dist. Modify Purchase Setup");
        RunCodeunit(CODEUNIT::"Dist. Create Purchase Header");
        RunCodeunit(CODEUNIT::"Dist. Create Purchase Line");
        RunCodeunit(CODEUNIT::"Dist. Release Purch. Documents");
        RunCodeunit(CODEUNIT::"Dist. Create Receipts");
        RunCodeunit(CODEUNIT::"Dist. Create Receipt Lines");
        RunCodeunit(CODEUNIT::"Dist. Post Receipt");
        RunCodeunit(CODEUNIT::"Dist. Post Put-away");
        RunCodeunit(CODEUNIT::"Create Transfer Order Add.");
        RunCodeunit(CODEUNIT::"Create Dist. Item Journal");
        RunCodeunit(CODEUNIT::"Create Dist. Inv. Adj. Journal");
        RunCodeunit(CODEUNIT::"Post Dist. Item Journal");
        RunCodeunit(CODEUNIT::"Post Dist. Inv. Adj. Journal");
        RunCodeunit(CODEUNIT::"Dist. Create/Register Pick");
        RunCodeunit(CODEUNIT::"Dist. Create Whse. Movement");

        ModSalesSetup.Finalize();
        ModPurchaseSetup.Finalize();

        Window.Close();
    end;

    procedure "After Posting"()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Distribution After Post');
        Steps := 0;
        MaxSteps := 1;

        Window.Close();
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        CODEUNIT.Run(CodeunitID);
    end;
}

