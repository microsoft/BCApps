codeunit 119085 "Create Cost Types"
{

    trigger OnRun()
    begin
        CostAccMgt.GetCostTypesFromChartDirect();
        UpdateDimOnCostTypes();
        EnhanceCostType();
    end;

    var
        CostAccMgt: Codeunit "Cost Account Mgt";
        MakeAdjustments: Codeunit "Make Adjustments";
        XFURNITURE: Label 'FURNITURE', Comment = 'Furniture is a name of Cost Object.';
        XPAINT: Label 'PAINT', Comment = 'Paint is a name of Cost Object.';
        XADM: Label 'ADM';
        XSALES: Label 'SALES', Comment = 'Sales is a name of the Cost Center.';
        XBUILDING: Label 'BUILDING', Comment = 'Building is a name of the Cost Center.';
        XACCESSO: Label 'ACCESSO', Comment = 'ACCESSO stands for Accessories and it is a name of cost center.';
        XCONSULTING: Label 'CONSULTING', Comment = 'Consulting is a name of Cost Object.';
        XCHAIRS: Label 'CHAIRS', Comment = 'Chairs is a name of Cost Object.';
        XFITTINGS: Label 'FITTINGS', Comment = 'Fittings is a name of Cost Object.';
        XPERS: Label 'PERS', Comment = 'PERS stands for Person and it is a name of cost center.';
        XCostCostCenterNoOpen: Label 'Cost center %1 not open.';
        XCostCostObjectNoOpen: Label 'Cost object %1 not open.';
        XMATERIAL: Label 'MATERIAL', Comment = 'Material is a name of Cost Center.';
        XGL: Label 'GL';
        XALLOCATIONS: Label 'ALLOCATIONS', Comment = 'Allocation is a name of Cost Type.';
        XTOTALALLOC: Label 'TOTAL ALLOCATIONS';
        XACTACCR: Label 'ACTACCR', Comment = 'ACTACCR stands for Actual Accurals and it is a name of cost center.';
        XEXPENSES: Label 'EXPENSES', Comment = 'Expenses is a name of the Cost Type.';
        XCOSTS: Label 'COSTS';
        XEXP: Label 'Expense';
        XCOS: Label 'Costs';
        XEXPE: Label 'expense';
        XCOST: Label 'costs', Comment = 'costs is a name of Cost Type.';
        XEARNINGS: Label 'EARNINGS', Comment = 'Earnings is a name of the Cost Type.';
        XREVENUE: Label 'REVENUE';
        XEARN: Label 'Earning';
        XREV: Label 'Revenue';
        XEARNI: Label 'earning';
        XREVE: Label 'revenue', Comment = 'revenue is a name of Cost Type.';
        XActualAccurals: Label 'Actual Accruals';
        xPurchaseTrade: Label 'Purchase Trade';
        XPurchaseRawMat: Label 'Purchase Raw Mat.';
        XEmployersSalary: Label 'Employer''s salary';
        XCalcInterestOnAssets: Label 'Calc. Interest on Assets';
        XInitialCostCenter: Label 'Alloc. of Initial Cost Center';
        XMainCostCenter: Label 'Alloc. of Main Cost Center';
        XAllocOfCostObject: Label 'Alloc. of Cost Object';

    procedure UpdateDimOnCostTypes()
    begin
        WriteDimOnCostType(MakeAdjustments.Convert('90-1310'), MakeAdjustments.Convert('90-1340'), '', XFURNITURE);
        WriteDimOnCostType(MakeAdjustments.Convert('90-1110'), MakeAdjustments.Convert('90-1140'), '', XPAINT);
        WriteDimOnCostType(MakeAdjustments.Convert('90-1210'), MakeAdjustments.Convert('90-1240'), '', XCONSULTING);
        WriteDimOnCostType(MakeAdjustments.Convert('91-1301'), MakeAdjustments.Convert('91-1390'), XSALES, '');

        WriteDimOnCostType(MakeAdjustments.Convert('91-2310'), MakeAdjustments.Convert('91-2310'), '', XFURNITURE);
        WriteDimOnCostType(MakeAdjustments.Convert('91-2110'), MakeAdjustments.Convert('91-2110'), '', XCHAIRS);
        WriteDimOnCostType(MakeAdjustments.Convert('91-2210'), MakeAdjustments.Convert('91-2210'), '', XACCESSO);

        WriteDimOnCostType(MakeAdjustments.Convert('41-1000'), MakeAdjustments.Convert('41-1000'), '', XPAINT);
        WriteDimOnCostType(MakeAdjustments.Convert('41-2000'), MakeAdjustments.Convert('41-2000'), '', XFITTINGS);
        WriteDimOnCostType(MakeAdjustments.Convert('41-4000'), MakeAdjustments.Convert('41-4000'), '', XFITTINGS);
        WriteDimOnCostType(MakeAdjustments.Convert('44-2200'), MakeAdjustments.Convert('44-2200'), XPERS, '');
        WriteDimOnCostType(MakeAdjustments.Convert('02-1010'), MakeAdjustments.Convert('02-1040'), XBUILDING, '');
        //WriteDimOnCostType(MakeAdjustments.Convert('998110'),MakeAdjustments.Convert('998120'),XBUILDING,'');
        //WriteDimOnCostType(MakeAdjustments.Convert('998130'),MakeAdjustments.Convert('998130'),XWORKSHOP,'');
        //WriteDimOnCostType(MakeAdjustments.Convert('998510'),MakeAdjustments.Convert('998530'),XVEHICLE,'');

        // BK outcommented  - not needed in W1
        // WriteDimOnCostType(MakeAdjustments.Convert('996300'),MakeAdjustments.Convert('996399'),Text006,'');

        //WriteDimOnCostType(MakeAdjustments.Convert('996410'),MakeAdjustments.Convert('996490'),XBUILDING,'');
        //WriteDimOnCostType(MakeAdjustments.Convert('998210'),MakeAdjustments.Convert('998240'),XADM,'');
        //WriteDimOnCostType(MakeAdjustments.Convert('998410'),MakeAdjustments.Convert('998450'),XADVERT,'');
        //WriteDimOnCostType(MakeAdjustments.Convert('998610'),MakeAdjustments.Convert('998640'),XADM,'');
        //WriteDimOnCostType(MakeAdjustments.Convert('999210'),MakeAdjustments.Convert('999270'),XADM,'');
        //WriteDimOnCostType(MakeAdjustments.Convert('998810'),MakeAdjustments.Convert('998830'),XBUILDING,'');
    end;

    procedure WriteDimOnCostType(FromAccount: Code[20]; ToAccount: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    var
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
    begin
        CostType.Reset();
        CostType.SetRange("No.", FromAccount, ToAccount);
        if CostCenterCode <> '' then begin
            if not CostCenter.Get(CostCenterCode) then
                Error(XCostCostCenterNoOpen, CostCenterCode);
            CostType.ModifyAll("Cost Center Code", CostCenterCode);
        end;

        if CostObjectCode <> '' then begin
            if not CostObject.Get(CostObjectCode) then
                Error(XCostCostObjectNoOpen, CostObjectCode);
            CostType.ModifyAll("Cost Object Code", CostObjectCode);
        end;
    end;

    procedure EnhanceCostType()
    var
        CostType: Record "Cost Type";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        ModifyCostType: Boolean;
    begin
        // Total: Delete Cost Type and create ne From/To Range
        CostType.SetRange("No.", MakeAdjustments.Convert('41-2000'), MakeAdjustments.Convert('41-4000'));
        CostType.DeleteAll();
        CostType.SetRange("No.", MakeAdjustments.Convert('91-2310'), MakeAdjustments.Convert('91-2390'));
        CostType.DeleteAll();
        CostType.Reset();

        CostType."No." := MakeAdjustments.Convert('41-1000');
        CostType.Name := xPurchaseTrade;
        CostType."G/L Account Range" := MakeAdjustments.Convert('41-1000') + '..' + MakeAdjustments.Convert('41-4000');
        CostType."Cost Center Code" := XMATERIAL;
        if CostType.Modify() then;

        CostType."No." := MakeAdjustments.Convert('91-2310');
        CostType.Name := XPurchaseRawMat;
        CostType."G/L Account Range" := MakeAdjustments.Convert('91-2310') + '..' + MakeAdjustments.Convert('91-2390');
        CostType."Cost Center Code" := XMATERIAL;
        if CostType.Modify() then;

        // Delete some Entries
        //CostType.SETRANGE("No.",MakeAdjustments.Convert('999395'),MakeAdjustments.Convert('999510'));
        //CostType.DeleteAll();
        //CostType.Reset();

        // Combine Entries per Day/month
        CostType.SetRange(Type, 0);
        CostType.SetRange("No.", MakeAdjustments.Convert('41-1000'), MakeAdjustments.Convert('41-5000'));
        CostType.ModifyAll("Combine Entries", CostType."Combine Entries"::Day);

        CostType.SetRange("No.", MakeAdjustments.Convert('90-1110'), MakeAdjustments.Convert('90-1340'));
        CostType.ModifyAll("Combine Entries", CostType."Combine Entries"::Day);

        //CostType.SETRANGE("No.",MakeAdjustments.Convert('996710'),MakeAdjustments.Convert('996910'));
        //CostType.MODIFYALL("Combine Entries",CostType."Combine Entries"::Month);
        //CostType.Reset();

        // Create new Cost Type  --> may need localization.. adjust also in definecostallocation()
        WriteCostType('8725', XEmployersSalary, "Cost Account Type"::"Cost Type", XGL, '');
        WriteCostType('9225', XCalcInterestOnAssets, "Cost Account Type"::"Cost Type", XADM, '');

        WriteCostType('9900', XALLOCATIONS, "Cost Account Type"::"Begin-Total", '', '');   // From
        WriteCostType('9901', XInitialCostCenter, "Cost Account Type"::"Cost Type", '', '');
        WriteCostType('9902', XMainCostCenter, "Cost Account Type"::"Cost Type", '', '');
        WriteCostType('9903', XAllocOfCostObject, "Cost Account Type"::"Cost Type", '', '');
        WriteCostType('9999', XTOTALALLOC, "Cost Account Type"::"End-Total", '', '');  // To

        WriteCostType('9920', XActualAccurals, "Cost Account Type"::"Cost Type", XACTACCR, '');

        if CostType.Find('-') then
            repeat
                ModifyCostType := false;
                if ReplaceCostTypeDescPart(CostType, XEXPENSES, XCOSTS) then
                    ModifyCostType := true;
                if ReplaceCostTypeDescPart(CostType, XEXP, XCOS) then
                    ModifyCostType := true;
                if ReplaceCostTypeDescPart(CostType, XEXPE, XCOST) then
                    ModifyCostType := true;
                if ReplaceCostTypeDescPart(CostType, XEARNINGS, XREVENUE) then
                    ModifyCostType := true;
                if ReplaceCostTypeDescPart(CostType, XEARN, XREV) then
                    ModifyCostType := true;
                if ReplaceCostTypeDescPart(CostType, XEARNI, XREVE) then
                    ModifyCostType := true;
                if ModifyCostType then
                    CostType.Modify();
            until CostType.Next() = 0;

        //CostType.Get(MakeAdjustments.Convert('996000'));
        //CostType.Name := XCOSTACC;
        //CostType.Modify();

        // Indent Cost Types
        CostAccountMgt.IndentCostTypes(false);

        // Transfer Cost Types to GLAccounts / check
        CostAccountMgt.LinkCostTypesToGLAccounts();
    end;

    procedure WriteCostType(CostTypeNo: Code[20]; CostTypeName: Text[30]; Type: Enum "Cost Account Type"; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    var
        CostType: Record "Cost Type";
    begin
        CostType.Init();
        CostType."No." := CostTypeNo;
        CostType.Name := CostTypeName;
        CostType.Type := Type;
        CostType."Cost Center Code" := CostCenterCode;
        CostType."Cost Object Code" := CostObjectCode;
        if not CostType.Modify() then
            CostType.Insert();
    end;

    procedure ReplaceCostTypeDescPart(CostType: Record "Cost Type"; FromText: Text[30]; NewText: Text[30]): Boolean
    var
        Position: Integer;
    begin
        Position := StrPos(CostType.Name, FromText);
        if Position > 0 then
            CostType.Name := CopyStr(CopyStr(CostType.Name, 1, Position - 1) + NewText + CopyStr(CostType.Name, Position + StrLen(FromText) + 1), 1, MaxStrLen(CostType.Name));
        exit(Position <> 0);
    end;
}

