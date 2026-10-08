codeunit 118831 "Create Whse. Journal Template"
{

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        InsertData(
          XADJMT, XAdjustmentJournal, "Warehouse Journal Template".Type::Item,
          SourceCodeSetup."Whse. Item Journal", XWJNLADJ, XWhseAdjustmentJournal, '5001', 'T06000');
        InsertData(
          XRECLASS, XReclassificationJournal, "Warehouse Journal Template".Type::Reclassification,
          SourceCodeSetup."Whse. Reclassification Journal", XWJNLRCLSS, XWhseReclassificationJournal, '6001', 'T07000');
        InsertData(
          XPHYSINVT, XPhysicalInventoryJournal, "Warehouse Journal Template".Type::"Physical Inventory",
          SourceCodeSetup."Whse. Phys. Invt. Journal", XWJNLPHYS, XWhsePhysInvtJournal, '7001', 'T08000');
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        "Warehouse Journal Template": Record "Warehouse Journal Template";
        "Create No. Series": Codeunit "Create No. Series";
        XADJMT: Label 'ADJMT';
        XAdjustmentJournal: Label 'Adjustment Journal';
        XWJNLADJ: Label 'WJNL-ADJ';
        XWhseAdjustmentJournal: Label 'Whse. Adjustment Journal';
        XRECLASS: Label 'RECLASS';
        XReclassificationJournal: Label 'Reclassification Journal';
        XWJNLRCLSS: Label 'WJNL-RCLSS';
        XWhseReclassificationJournal: Label 'Whse. Reclassification Journal';
        XPHYSINVT: Label 'PHYSINVT';
        XPhysicalInventoryJournal: Label 'Physical Inventory Journal';
        XWJNLPHYS: Label 'WJNL-PHYS';
        XWhsePhysInvtJournal: Label 'Whse. Phys. Invt. Journal';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Type: Enum "Warehouse Journal Template Type"; "Source Code": Code[10]; "No. Series": Code[10]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    begin
        if "No. Series" <> '' then
            "Create No. Series".InitBaseSeries(
              "No. Series", "No. Series", NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1);

        "Warehouse Journal Template".Init();
        "Warehouse Journal Template".Validate(Name, Name);
        "Warehouse Journal Template".Validate(Description, Description);
        "Warehouse Journal Template".Insert(true);
        "Warehouse Journal Template".Validate(Type, Type);
        "Warehouse Journal Template".Validate("No. Series", "No. Series");
        "Warehouse Journal Template".Validate("Source Code", "Source Code");
        "Warehouse Journal Template".Modify();
    end;
}

