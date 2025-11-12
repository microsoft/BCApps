codeunit 101800 "Create Fixed Asset"
{

    trigger OnRun()
    begin
        "Vendor No." := '44127914';
        InsertData(
          XFA000010, XMercedes300, XTANGIBLE, XCAR, XADM, XMERCEDES, XADM, 0, '', XOF,
          XEA12394Q, 19030412D, "Vendor No.", "Vendor No.");
        InsertData(
          XFA000020, XToyotaSupra30, XTANGIBLE, XCAR, XSALES, XTOYOTA, XSALES, 0, '', XJO,
          XEA12395Q, 19030718D, "Vendor No.", "Vendor No.");
        InsertData(
          XFA000030, XVWTransporter, XTANGIBLE, XCAR, XPROD, XVW, XPROD, 0, '', XRB,
          XEA15397Q, 19030821D, "Vendor No.", "Vendor No.");

        "Vendor No." := '44127904';
        InsertData(
          XFA000040, XConveyorMainAsset, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 1, XFA000040, XMH,
          X23111SW0, 19030815D, "Vendor No.", "Vendor No.");
        InsertData(
          XFA000050, XConveyorBelt, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 2, XFA000040, XMH,
          X23111SW1, 19030815D, "Vendor No.", "Vendor No.");
        InsertData(
          XFA000060, XConveyorLift, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 2, XFA000040, XMH,
          X23111SW2, 19030815D, "Vendor No.", "Vendor No.");
        InsertData(
          XFA000070, XConveyorComputer, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 2, XFA000040, XMH,
          X23111SW3, 19030815D, "Vendor No.", "Vendor No.");
        InsertData(
          XFA000080, XLiftforFurniture, XTANGIBLE, XMACHINERY, XPROD, '', XPROD, 0, '', XMH,
          XAKW2476111, 19030421D, "Vendor No.", "Vendor No.");
        InsertData(
          XFA000090, XSwitchboard, XTANGIBLE, XTELEPHONE, XADM, '', XRECEPTION, 0, '', XEH,
          XTELE4476Z, 19031212D, "Vendor No.", "Vendor No.");
    end;

    var
        "Fixed Asset": Record "Fixed Asset";
        CA: Codeunit "Make Adjustments";
        "Vendor No.": Code[20];
        XFA000010: Label 'FA000010';
        XMercedes300: Label 'Mercedes 300';
        XTANGIBLE: Label 'TANGIBLE';
        XCAR: Label 'CAR';
        XMERCEDES: Label 'MERCEDES';
        XADM: Label 'ADM';
        XOF: Label 'OF';
        XEA12394Q: Label 'EA 12 394 Q';
        XFA000020: Label 'FA000020';
        XToyotaSupra30: Label 'Toyota Supra 3.0';
        XSALES: Label 'SALES';
        XTOYOTA: Label 'TOYOTA';
        XJO: Label 'JO';
        XEA12395Q: Label 'EA 12 395 Q';
        XFA000030: Label 'FA000030';
        XVWTransporter: Label 'VW Transporter';
        XPROD: Label 'PROD';
        XVW: Label 'VW';
        XRB: Label 'RB';
        XEA15397Q: Label 'EA 15 397 Q';
        XFA000040: Label 'FA000040';
        XConveyorMainAsset: Label 'Conveyor, Main Asset';
        XMACHINERY: Label 'MACHINERY';
        XBUILD2: Label 'BUILD_2';
        XMH: Label 'MH';
        X23111SW0: Label '23 111 SW0';
        XFA000050: Label 'FA000050';
        XConveyorBelt: Label 'Conveyor Belt';
        X23111SW1: Label '23 111 SW1';
        XFA000070: Label 'FA000070';
        X23111SW2: Label '23 111 SW2';
        XConveyorComputer: Label 'Conveyor Computer';
        X23111SW3: Label '23 111 SW3';
        XFA000080: Label 'FA000080';
        XLiftforFurniture: Label 'Lift for Furniture';
        XFA000060: Label 'FA000060';
        XConveyorLift: Label 'Conveyor Lift';
        XAKW2476111: Label 'AKW2476111';
        XFA000090: Label 'FA000090';
        XSwitchboard: Label 'Switchboard';
        XTELEPHONE: Label 'TELEPHONE';
        XRECEPTION: Label 'RECEPTION';
        XEH: Label 'EH';
        XTELE4476Z: Label 'TELE 4476 Z';

    procedure InsertData("No.": Code[20]; Description: Text[30]; "FA Class Code": Code[10]; "FA Subclass Code": Code[10]; "Global Dimension 1 Code": Code[20]; "Global Dimension 2 Code": Code[20]; "FA Location Code": Code[10]; "Main Asset/Component": Integer; "Component of Main Asset": Code[20]; "Responsible Employee": Code[20]; "Serial No.": Text[30]; "Next Service Date": Date; "Vendor No.": Code[20]; "Maintenance Vendor No.": Code[20])
    begin
        "Fixed Asset".Init();
        "Fixed Asset"."No." := "No.";
        "Fixed Asset".Description := Description;
        "Fixed Asset"."Search Description" := Description;
        "Fixed Asset".Validate("FA Class Code", "FA Class Code");
        "Fixed Asset".Validate("FA Subclass Code", "FA Subclass Code");
        "Fixed Asset".Validate("FA Location Code", "FA Location Code");
        "Fixed Asset"."Main Asset/Component" := "FA Component Type".FromInteger("Main Asset/Component");
        "Fixed Asset"."Component of Main Asset" := "Component of Main Asset";
        "Fixed Asset".Validate("Responsible Employee", "Responsible Employee");
        "Fixed Asset".Validate("Serial No.", "Serial No.");
        if "Next Service Date" <> 0D then
            "Fixed Asset".Validate("Next Service Date", CA.AdjustDate("Next Service Date"));
        "Fixed Asset".Validate("Vendor No.", "Vendor No.");
        "Fixed Asset".Validate("Maintenance Vendor No.", "Maintenance Vendor No.");
        "Fixed Asset".Insert();
        "Fixed Asset".Validate("Global Dimension 1 Code", "Global Dimension 1 Code");
        "Fixed Asset".Validate("Global Dimension 2 Code", "Global Dimension 2 Code");
        "Fixed Asset".Modify();
    end;
}

