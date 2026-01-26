codeunit 120553 "Create No. Series IN"
{

    trigger OnRun()
    begin
        "Create No. Series".InsertSeries(
            "FA Setup"."Fixed Asset Nos.", PostedDist, PostedDistributionInvoiceLbl, 'PD-INV-0001',
            '', LastNoUsedPostedDisLbl, '', 10, false);
        "Create No. Series".InsertSeries(
            "FA Setup"."Fixed Asset Nos.", GSTCreditLbl, GSTCreditJournalAdjustment, 'GST-CRJNL-00001',
            '', LastNoUsedGStCreditLbl, '', 10, false);
        "Create No. Series".InsertSeries(
            "FA Setup"."Fixed Asset Nos.", GSTSettelement, GSTSettelementDesLbl, 'GST-STL_JNL/001',
             '', LastNoUsedGstSettelment, '', 10, false);

        InventorySetup.Get();
        "Create No. Series".InsertSeries(InventorySetup."Inward Gate Entry Nos.", XGEINW, XGateEntryInwards, 'GATE/IN/00001', '', '', '', 1, true);
        "Create No. Series".InsertSeries(InventorySetup."Outward Gate Entry Nos.", XGEOUT, XGateEntryOutward, 'GATE/OUT/00001', '', '', '', 1, true);
        InventorySetup.Modify();

        PostingNoSeries.Init();
        PostingNoSeries.ID := 0;
        PostingNoSeries.Validate("Document Type", PostingNoSeries."Document Type"::"Gate Entry");
        "Create No. Series".InsertSeries(PostingNoSeries."Posting No. Series", XGTINBL, XGateBlue, 'GTINBL000001', '', '', '', 1, true);
        PostingNoSeries.Insert();
        "Posting No. Series Mgmt.".SetTablesCondition(PostingNoSeries, 'VERSION(1) SORTING(Field1,Field2) where(Field1=1(0),Field7=1(BLUE))');

        PostingNoSeries.Init();
        PostingNoSeries.ID := 0;
        PostingNoSeries.Validate("Document Type", PostingNoSeries."Document Type"::"Gate Entry");
        "Create No. Series".InsertSeries(PostingNoSeries."Posting No. Series", XGTOUTBL, XGateOUTBlue, 'GTOUTBL000001', '', '', '', 1, true);
        PostingNoSeries.Insert();
        "Posting No. Series Mgmt.".SetTablesCondition(PostingNoSeries, 'VERSION(1) SORTING(Field1,Field2) where(Field1=1(1),Field7=1(BLUE))');
    end;

    var
        "FA Setup": Record "FA Setup";
        InventorySetup: Record "Inventory Setup";
        PostingNoSeries: Record "Posting No. Series";
        "Create No. Series": Codeunit "Create No. Series";
        "Posting No. Series Mgmt.": Codeunit "Posting No. Series Mgmt.";
        PostedDist: Label 'P-D-INV', Locked = true;
        PostedDistributionInvoiceLbl: Label 'Posted Distribution Invoice', Locked = true;
        LastNoUsedPostedDisLbl: Label 'PD-INV-0001', Locked = true;
        GSTCreditLbl: Label 'GST-CR-JNL', Locked = true;
        GSTCreditJournalAdjustment: Label 'GST Credit Journal Adjustment', Locked = true;
        LastNoUsedGStCreditLbl: Label 'GST-CRJNL-00001', Locked = true;
        GSTSettelement: Label 'GST-SETTLE', Locked = true;
        GSTSettelementDesLbl: Label 'GST Settlement', Locked = true;
        LastNoUsedGstSettelment: Label 'GST-STL_JNL/001', Locked = true;
        XGEINW: Label 'GEINW', Locked = true;
        XGateEntryInwards: Label 'Gate Entry-Inwards', Locked = true;
        XGEOUT: Label 'GEOUT', Locked = true;
        XGateEntryOutward: Label 'Gate Entry Outward', Locked = true;
        XGTINBL: Label 'GT-IN-BL+', Locked = true;
        XGateBlue: Label 'Gate Blue', Locked = true;
        XGTOUTBL: Label 'GT-OUT-BL+', Locked = true;
        XGateOUTBlue: Label 'Gate OUT Blue', Locked = true;
}

