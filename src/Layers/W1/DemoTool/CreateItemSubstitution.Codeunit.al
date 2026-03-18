codeunit 118800 "Create Item Substitution"
{

    trigger OnRun()
    begin
        ItemSubst.DeleteAll();
        DemoDataSetup.Get();
        InsertData('1968-S', '1980-S', XMOSCOWSwivelChairred, false);
        InsertData('1968-W', '1972-W', XSAPPOROWhiteboardblack, true);
        InsertData('1980-S', '1988-S', XSEOULGuestChairred, true);
    end;

    var
        ItemSubst: Record "Item Substitution";
        XMOSCOWSwivelChairred: Label 'MOSCOW Swivel Chair, red';
        XSAPPOROWhiteboardblack: Label 'SAPPORO Whiteboard, black';
        XSEOULGuestChairred: Label 'SEOUL Guest Chair, red';
        DemoDataSetup: Record "Demo Data Setup";

    local procedure InsertData("Item No.": Code[20]; "Substitute Item No.": Code[20]; Description: Text[30]; Interchangeable: Boolean)
    begin
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then
            if StrPos("Item No.", 'S') = 0 then
                exit;

        ItemSubst.Init();
        ItemSubst.Validate("No.", "Item No.");
        ItemSubst.Validate("Substitute No.", "Substitute Item No.");
        ItemSubst.Validate(Description, Description);
        ItemSubst.Validate(Interchangeable, Interchangeable);
        ItemSubst.Insert();
    end;
}

