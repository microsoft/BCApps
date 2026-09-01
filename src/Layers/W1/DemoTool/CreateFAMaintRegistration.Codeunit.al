codeunit 101811 "Create FA Maint. Registration"
{

    trigger OnRun()
    begin
        InsertData(XFA000010, 19030131D, X3000mileservice, XGregoryJErickson);
        InsertData(XFA000020, 19030515D, X3000mileservice, XLarryZhang);
        InsertData(XFA000030, 19030618D, X3000mileservice, XJoshBarnhill);
        InsertData(XFA000050, 19030114D, XInitialservice, XKellyFocht);
        InsertData(XFA000060, 19030218D, XInitialservice, XKellyFocht);
        InsertData(XFA000070, 19030415D, XInitialservice, XKellyFocht);
        InsertData(XFA000080, 19030420D, X100hoursservice, XTaylorMaxwell);
        InsertData(XFA000090, 19030202D, XInitialservice, XJohnCampbellIII);
    end;

    var
        CA: Codeunit "Make Adjustments";
        XFA000010: Label 'FA000010';
        XFA000020: Label 'FA000020';
        XFA000030: Label 'FA000030';
        XFA000050: Label 'FA000050';
        XFA000060: Label 'FA000060';
        XFA000070: Label 'FA000070';
        XFA000080: Label 'FA000080';
        XFA000090: Label 'FA000090';
        X3000mileservice: Label '3000-mile service';
        XInitialservice: Label 'Initial service';
        X100hoursservice: Label '100 hours service';
        XGregoryJErickson: Label 'Gregory J. Erickson';
        XLarryZhang: Label 'Larry Zhang';
        XJoshBarnhill: Label 'Josh Barnhill';
        XKellyFocht: Label 'Kelly Focht';
        XTaylorMaxwell: Label 'Taylor Maxwell';
        XJohnCampbellIII: Label 'John Campbell III';

    procedure InsertData("FA No.": Code[20]; "Service Date": Date; Comment: Text[50]; "Service Agent Name": Text[50])
    var
        "Fixed Asset": Record "Fixed Asset";
        "Maintenance Registration": Record "Maintenance Registration";
    begin
        "Fixed Asset".Get("FA No.");
        "Maintenance Registration"."FA No." := "FA No.";
        "Maintenance Registration"."Service Date" := CA.AdjustDate("Service Date");
        "Maintenance Registration"."Maintenance Vendor No." := "Fixed Asset"."Maintenance Vendor No.";
        "Maintenance Registration".Comment := Comment;
        "Maintenance Registration"."Service Agent Name" := "Service Agent Name";
        "Maintenance Registration"."Line No." := 10000;
        "Maintenance Registration".Insert(true);
    end;
}

