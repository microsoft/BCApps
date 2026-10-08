codeunit 119088 "Create Cost Acct. Jnl Line"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        DemoDataSetup.Get();

        InsertData(XINTINVC, DMY2Date(30, 6, DemoDataSetup."Starting Year"), 'U12', '9225', '', '', '9920', '', '',
          XCalcAssetInterest, 15200);
        InsertData(XINTINVC, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'U15', '9225', '', '', '9920', '', '',
          XCalcAssetInterest2, 15800);
        InsertData(XINTINVC, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'U18', MakeAdjustments.Convert('998710'), '',
          XFURNITURE, MakeAdjustments.Convert('998710'), XPERS, '', Text119, 1422000);
        InsertData(XINTINVC, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'U19', MakeAdjustments.Convert('998710'), '',
          XCHAIRS, MakeAdjustments.Convert('998710'), XPERS, '', Text120, 580000);
        InsertData(XINTINVC, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'U20', MakeAdjustments.Convert('998710'), '',
          XACCESSO, MakeAdjustments.Convert('998710'), XPERS, '', Text121, 226000);

        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        // Depreciation

        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year"), 'A11',
          MakeAdjustments.Convert('998810'), '', '', '9920', '', '', Text122, 4800);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year"), 'A12',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text123, 10200);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year"), 'A13',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text124, 5000);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year"), 'A14',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text125, 13000);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year"), 'A15',
          MakeAdjustments.Convert('998830'), '', '', '9920', '', '', Text126, 2500);

        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year"), 'A21',
          MakeAdjustments.Convert('998810'), '', '', '9920', '', '', Text127, 4800);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year"), 'A22',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text128, 10500);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year"), 'A23',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text129, 5000);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year"), 'A24',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text130, 14000);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year"), 'A25',
          MakeAdjustments.Convert('998830'), '', '', '9920', '', '', Text131, 3000);

        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        InsertData(XDEPRECIAT, DMY2Date(30, 9, DemoDataSetup."Starting Year"), 'A31',
          MakeAdjustments.Convert('998810'), '', '', '9920', '', '', Text132, 4800);
        InsertData(XDEPRECIAT, DMY2Date(30, 9, DemoDataSetup."Starting Year"), 'A32',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text133, 10700);
        InsertData(XDEPRECIAT, DMY2Date(30, 9, DemoDataSetup."Starting Year"), 'A33',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text134, 6000);
        InsertData(XDEPRECIAT, DMY2Date(30, 9, DemoDataSetup."Starting Year"), 'A34',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text135, 15000);
        InsertData(XDEPRECIAT, DMY2Date(30, 9, DemoDataSetup."Starting Year"), 'A35',
          MakeAdjustments.Convert('998830'), '', '', '9920', '', '', Text136, 3500);

        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        InsertData(XDEPRECIAT, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'A41',
          MakeAdjustments.Convert('998810'), '', '', '9920', '', '', Text137, 5000);
        InsertData(XDEPRECIAT, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'A42',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text138, 10000);
        InsertData(XDEPRECIAT, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'A43',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text139, 5000);
        InsertData(XDEPRECIAT, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'A44',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text140, 12000);
        InsertData(XDEPRECIAT, DMY2Date(31, 12, DemoDataSetup."Starting Year"), 'A45',
          MakeAdjustments.Convert('998830'), '', '', '9920', '', '', Text141, 2000);

        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year" + 1), 'A51',
          MakeAdjustments.Convert('998810'), '', '', '9920', '', '', Text142, 6000);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year" + 1), 'A52',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text143, 12000);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year" + 1), 'A53',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text144, 4000);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year" + 1), 'A54',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text145, 13000);
        InsertData(XDEPRECIAT, DMY2Date(30, 3, DemoDataSetup."Starting Year" + 1), 'A55',
          MakeAdjustments.Convert('998830'), '', '', '9920', '', '', Text146, 2500);

        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJournalLine);

        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year" + 1), 'A61',
          MakeAdjustments.Convert('998810'), '', '', '9920', '', '', Text147, 6000);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year" + 1), 'A62',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text148, 12000);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year" + 1), 'A63',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text149, 4000);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year" + 1), 'A64',
          MakeAdjustments.Convert('998820'), '', '', '9920', '', '', Text150, 13000);
        InsertData(XDEPRECIAT, DMY2Date(30, 6, DemoDataSetup."Starting Year" + 1), 'A65',
          MakeAdjustments.Convert('998830'), '', '', '9920', '', '', Text151, 2500);
    end;

    var
        XINTINVC: Label 'INTINVC', Comment = 'INTINVC stands for Internal Invoicing.';
        XDEPRECIAT: Label 'DEPRECIAT', Comment = 'DEPRECIAT stands for Depreciation.';
        XCOSTACCT: Label 'COSTACCT', Comment = 'COSTACCT stands for Cost Accounting.';
        XPERS: Label 'PERS', Comment = 'PERS stands for Person.';
        XFURNITURE: Label 'FURNITURE', Comment = 'Furniture is a name of Cost Object.';
        XCHAIRS: Label 'CHAIRS', Comment = 'Chairs is a name of Cost Object.';
        XACCESSO: Label 'ACCESSO', Comment = 'ACCESSO stands for Accessories and it is a name of cost object.';
        XCalcAssetInterest: Label 'Calc. Asset Interest 1/2000';
        XCalcAssetInterest2: Label 'Calc. Asset Interest 2/2000';
        Text119: Label 'Direct Labor Costs Furniture 2000';
        Text120: Label 'Direct Labor Costs Chairs 2000';
        Text121: Label 'Direct Labor Costs Accessories 2000';
        Text122: Label 'Depreciation Costs Building 1/2000';
        Text123: Label 'Depreciation Costs Machines 1/2000';
        Text124: Label 'Depreciation Costs Furniture 1/2000';
        Text125: Label 'Depreciation Costs Vehicles 1/2000';
        Text126: Label 'Depreciation Costs Misc. 1/2000';
        Text127: Label 'Depreciation Costs Building 2/2000';
        Text128: Label 'Depreciation Costs Machines 2/2000';
        Text129: Label 'Depreciation Costs Furniture 2/2000';
        Text130: Label 'Depreciation Costs Vehicles 2/2000';
        Text131: Label 'Depreciation Costs Misc. 2/2000';
        Text132: Label 'Depreciation Costs Building 3/2000';
        Text133: Label 'Depreciation Costs Machines 3/2000';
        Text134: Label 'Depreciation Costs Furniture 3/2000';
        Text135: Label 'Depreciation Costs Vehicles 3/2000';
        Text136: Label 'Depreciation Costs Misc. 3/2000';
        Text137: Label 'Depreciation Costs Building 4/2000';
        Text138: Label 'Depreciation Costs Machines 4/2000';
        Text139: Label 'Depreciation Costs Furniture 4/2000';
        Text140: Label 'Depreciation Costs Vehicles 4/2000';
        Text141: Label 'Depreciation Costs Misc. 4/2000';
        Text142: Label 'Depreciation Costs Building 1/2001';
        Text143: Label 'Depreciation Costs Machines 1/2001';
        Text144: Label 'Depreciation Costs Furniture 1/2001';
        Text145: Label 'Depreciation Costs Vehicles 1/2001';
        Text146: Label 'Depreciation Costs Misc. 1/2001';
        Text147: Label 'Depreciation Costs Building 2/2001';
        Text148: Label 'Depreciation Costs Machines 2/2001';
        Text149: Label 'Depreciation Costs Furniture 2/2001';
        Text150: Label 'Depreciation Costs Vehicles 2/2001';
        Text151: Label 'Depreciation Costs Misc. 2/2001';
        CostJournalLine: Record "Cost Journal Line";

    procedure InsertData(JournalBatch: Code[10]; PostingDate: Date; DocumentNo: Code[10]; CostTypeNo: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20]; BalCostTypeNo: Code[20]; BalCostCenterCode: Code[20]; BalCostObjectCode: Code[20]; JournalLineText: Text[80]; AmountVar: Decimal)
    var
        LastLineNo: Integer;
    begin
        CostJournalLine.Reset();
        CostJournalLine.SetRange("Journal Template Name", XCOSTACCT);
        CostJournalLine.SetRange("Journal Batch Name", JournalBatch);
        if CostJournalLine.FindLast() then
            LastLineNo := CostJournalLine."Line No."
        else
            LastLineNo := 0;
        CostJournalLine.Init();
        CostJournalLine."Journal Template Name" := XCOSTACCT;
        CostJournalLine."Journal Batch Name" := JournalBatch;
        CostJournalLine."Line No." := LastLineNo + 10000;
        CostJournalLine."Posting Date" := PostingDate;
        CostJournalLine."Document No." := DocumentNo;
        CostJournalLine.Validate("Cost Type No.", CostTypeNo);
        CostJournalLine.Validate("Bal. Cost Type No.", BalCostTypeNo);
        CostJournalLine.Description := JournalLineText;
        CostJournalLine.Validate(Amount, AmountVar);
        // Overwrite Default
        if (CostCenterCode <> '') or (CostObjectCode <> '') then begin
            CostJournalLine."Cost Center Code" := CostCenterCode;
            CostJournalLine."Cost Object Code" := CostObjectCode;
        end;

        if (BalCostCenterCode <> '') or (BalCostObjectCode <> '') then begin
            CostJournalLine."Bal. Cost Center Code" := BalCostCenterCode;
            CostJournalLine."Bal. Cost Object Code" := BalCostObjectCode;
        end;

        if not CostJournalLine.Insert(true) then
            CostJournalLine.Modify();
    end;
}

