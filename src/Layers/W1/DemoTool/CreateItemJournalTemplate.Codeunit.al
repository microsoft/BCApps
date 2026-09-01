codeunit 101082 "Create Item Journal Template"
{

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        InsertData(
          XITEM, XItemJournal, "Item Journal Template".Type::Item, false, SourceCodeSetup."Item Journal",
          XIJNLGEN, XItemJournal, '1', XT01000);
        InsertData(
          XRECLASS, XItemReclassJournal, "Item Journal Template".Type::Transfer, false, SourceCodeSetup."Item Reclass. Journal",
          XIJNLRCL, XItemReclassJournal, '1001', XT02000);
        InsertData(
          XPHYSINV, XItemJournal, "Item Journal Template".Type::"Phys. Inventory", false, SourceCodeSetup."Phys. Inventory Journal",
          XIJNLPHYS, XPhysicalInventoryJournal, '2001', XT03000);
        InsertData(
          XRECURRING, XRecurringItemJournal, "Item Journal Template".Type::Item, true, SourceCodeSetup."Item Journal",
          XIJNLREC, XRecurringItemJournal, '3001', XT04000);
        InsertData(
          XREVAL, XRevaluationJournal, "Item Journal Template".Type::Revaluation, false, SourceCodeSetup."Revaluation Journal",
          XIJNLREVAL, XRevaluationJournal, '4001', XT05000);
        InsertData(
          XCONSUMP, XConsumptionJournal, "Item Journal Template".Type::Consumption, false, SourceCodeSetup."Consumption Journal",
          '', XConsumptionJournal, '', '');
        InsertData(
          XOUTPUT, XOutputJournal, "Item Journal Template".Type::Output, false, SourceCodeSetup."Output Journal",
          '', XOutputJournal, '', '');
        InsertData(
          XCAPACITY, XCapacityJournal, "Item Journal Template".Type::Capacity, false, SourceCodeSetup."Capacity Journal",
          '', XCapacityJournal, '', '');
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        "Item Journal Template": Record "Item Journal Template";
        "Create No. Series": Codeunit "Create No. Series";
        XITEM: Label 'ITEM';
        XItemJournal: Label 'Item Journal';
        XIJNLGEN: Label 'IJNL-GEN';
        XT01000: Label 'T01000';
        XRECLASS: Label 'RECLASS';
        XItemReclassJournal: Label 'Item Reclass. Journal';
        XIJNLRCL: Label 'IJNL-RCL';
        XT02000: Label 'T02000';
        XPHYSINV: Label 'PHYS. INV.';
        XIJNLPHYS: Label 'IJNL-PHYS';
        XPhysicalInventoryJournal: Label 'Physical Inventory Journal';
        XT03000: Label 'T03000';
        XRECURRING: Label 'RECURRING';
        XRecurringItemJournal: Label 'Recurring Item Journal';
        XIJNLREC: Label 'IJNL-REC';
        XT04000: Label 'T04000';
        XREVAL: Label 'REVAL';
        XRevaluationJournal: Label 'Revaluation Journal';
        XIJNLREVAL: Label 'IJNL-REVAL';
        XT05000: Label 'T05000';
        XCONSUMP: Label 'CONSUMP';
        XConsumptionJournal: Label 'Consumption Journal';
        XOUTPUT: Label 'OUTPUT';
        XOutputJournal: Label 'Output Journal';
        XCAPACITY: Label 'CAPACITY';
        XCapacityJournal: Label 'Capacity Journal';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Type: Enum "Item Journal Template Type"; Recurring: Boolean; "Source Code": Code[10]; "No. Series": Code[10]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    begin
        if "No. Series" <> '' then
            "Create No. Series".InitBaseSeries(
              "No. Series", "No. Series", NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1);

        "Item Journal Template".Init();
        "Item Journal Template".Validate(Name, Name);
        "Item Journal Template".Validate(Description, Description);
        "Item Journal Template".Insert(true);
        "Item Journal Template".Validate(Type, Type);
        "Item Journal Template".Validate(Recurring, Recurring);
        if Recurring then
            "Item Journal Template".Validate("Posting No. Series", "No. Series")
        else
            "Item Journal Template".Validate("No. Series", "No. Series");
        "Item Journal Template".Validate("Source Code", "Source Code");
        "Item Journal Template".Modify();
    end;

    procedure InsertMiniAppData()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        InsertData(
          XITEM, XItemJournal, "Item Journal Template".Type::Item, false, SourceCodeSetup."Item Journal",
          XIJNLGEN, XItemJournal, '1', XT01000);
    end;
}

