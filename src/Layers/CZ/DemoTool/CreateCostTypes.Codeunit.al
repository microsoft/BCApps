codeunit 119085 "Create Cost Types"
{

    trigger OnRun()
    begin
        // NAVCZ
        WriteCostType('500', XEXPENSES, "Cost Account Type"::"Begin-Total", '', '', '');
        WriteCostType('501', XMaterialconsumption, "Cost Account Type"::"Cost Type", XPROD, '', '501000..501999');
        WriteCostType('502', XEnergyconsumption, "Cost Account Type"::"Cost Type", XPROD, '', '502000..502999');
        WriteCostType('503', XNonstorablesupplies, "Cost Account Type"::"Cost Type", XPROD, '', '503000..503999');
        WriteCostType('504', XCOGS, "Cost Account Type"::"Cost Type", XSALES, '', '504000..504999');
        WriteCostType('510', XServices, "Cost Account Type"::"Cost Type", XPROD, '', '510000..519999');
        WriteCostType('520', XPersonalexpenses, "Cost Account Type"::"Cost Type", XPERS, '', '520000..529999');
        WriteCostType('530', XTaxesandfees, "Cost Account Type"::"Cost Type", XGL, '', '530000..539999');
        WriteCostType('540', XOperatingexpenses, "Cost Account Type"::"Cost Type", XGL, '', '540000..549999');
        WriteCostType('550', XDeprecationreserves, "Cost Account Type"::"Cost Type", XBUILDING, '', '550000..559999');
        WriteCostType('560', XFinancialexpenses, "Cost Account Type"::"Cost Type", XADM, '', '560000..569999');
        WriteCostType('570', XReservesandcorrectionentriesoffinancialexpenses, "Cost Account Type"::"Cost Type", XGL, '', '570000..579999');
        WriteCostType('580', XChangeininventoryofownproductionandactivation, "Cost Account Type"::"Cost Type", XPROD, '', '580000..589999');
        WriteCostType('590', XIncomeTax, "Cost Account Type"::"Cost Type", XGL, '', '590000..599900');
        WriteCostType('599', XExpensesTotal, "Cost Account Type"::"End-Total", '', '', '');
        WriteCostType('600', XREVENUES, "Cost Account Type"::"Begin-Total", '', '', '');
        WriteCostType('601', XChangeininventoryofownproductionandactivation, "Cost Account Type"::"Cost Type", XPROD, '', '600001..603999');
        WriteCostType('604', XSalesGoods, "Cost Account Type"::"Cost Type", XSALES, '', '604000..609999');
        WriteCostType('640', XOperatingrevenues, "Cost Account Type"::"Cost Type", XADM, '', '640000..649999');
        WriteCostType('660', XFinancialrevenues, "Cost Account Type"::"Cost Type", XADM, '', '660000..669999');
        WriteCostType('690', XTransferaccounts, "Cost Account Type"::"Cost Type", XGL, '', '690000..699900');
        WriteCostType('699', XRevenuestotal, "Cost Account Type"::"End-Total", '', '', '');
        // NAVCZ

        EnhanceCostType();
    end;

    var
        MakeAdjustments: Codeunit "Make Adjustments";
        XExpensesTotal: Label 'Expenses Total';
        XMaterialconsumption: Label 'Material consumption';
        XEnergyconsumption: Label 'Energy consumption';
        XCOGS: Label 'COGS', Comment = 'Cost of Goods Sold';
        XServices: Label 'Services';
        XPersonalexpenses: Label 'Personal expenses';
        XTaxesandfees: Label 'Taxes and fees';
        XOperatingexpenses: Label 'Operating expenses';
        XDeprecationreserves: Label 'Deprecation, reserves';
        XFinancialexpenses: Label 'Financial expenses';
        XReservesandcorrectionentriesoffinancialexpenses: Label 'Reserves and correction entries of financial expenses';
        XChangeininventoryofownproductionandactivation: Label 'Change in inventory of own production and activation';
        XREVENUES: Label 'REVENUES';
        XOperatingrevenues: Label 'Operating revenues';
        XFinancialrevenues: Label 'Financial revenues';
        XRevenuestotal: Label 'Revenues total';
        XFURNITURE: Label 'FURNITURE', Comment = 'Furniture is a name of Cost Object.';
        XPAINT: Label 'PAINT', Comment = 'Paint is a name of Cost Object.';
        XADM: Label 'ADM';
        XSALES: Label 'SALES', Comment = 'Sales is a name of the Cost Center.';
        XBUILDING: Label 'BUILDING', Comment = 'Building is a name of the Cost Center.';
        XVEHICLE: Label 'VEHICLE', Comment = 'Vehicle is a name of Cost Center.';
        XADVERT: Label 'ADVERT', Comment = 'ADVERT stands for Advertisement and it is a name of cost center.';
        XACCESSO: Label 'ACCESSO', Comment = 'ACCESSO stands for Accessories and it is a name of cost center.';
        XWORKSHOP: Label 'WORKSHOP', Comment = 'Workshop is a name of Cost Center.';
        XCONSULTING: Label 'CONSULTING', Comment = 'Consulting is a name of Cost Object.';
        XCHAIRS: Label 'CHAIRS', Comment = 'Chairs is a name of Cost Object.';
        XFITTINGS: Label 'FITTINGS', Comment = 'Fittings is a name of Cost Object.';
        XPERS: Label 'PERS', Comment = 'PERS stands for Person and it is a name of cost center.';
        XCostCostCenterNoOpen: Label 'Cost center %1 not open.';
        XCostCostObjectNoOpen: Label 'Cost object %1 not open.';
        XGL: Label 'GL';
        XALLOCATIONS: Label 'ALLOCATIONS', Comment = 'Allocation is a name of Cost Type.';
        XTOTALALLOC: Label 'TOTAL ALLOCATIONS';
        XACTACCR: Label 'ACTACCR', Comment = 'ACTACCR stands for Actual Accurals and it is a name of cost center.';
        XEXPENSES: Label 'EXPENSES', Comment = 'Expenses is a name of the Cost Type.';
        XActualAccurals: Label 'Actual Accruals';
        XEmployersSalary: Label 'Employer''s salary';
        XCalcInterestOnAssets: Label 'Calc. Interest on Assets';
        XInitialCostCenter: Label 'Alloc. of Initial Cost Center';
        XMainCostCenter: Label 'Alloc. of Main Cost Center';
        XAllocOfCostObject: Label 'Alloc. of Cost Object';
        XNonstorablesupplies: Label 'Non-storable supplies';
        XIncomeTax: Label 'Income tax';
        XSalesgoods: Label 'Sales goods';
        XTransferaccounts: Label 'Transfer accounts';
        XPROD: Label 'PROD', Comment = 'Production';

    procedure UpdateDimOnCostTypes()
    begin
        WriteDimOnCostType(MakeAdjustments.Convert('996210'), MakeAdjustments.Convert('996290'), '', XFURNITURE);
        WriteDimOnCostType(MakeAdjustments.Convert('996110'), MakeAdjustments.Convert('996190'), '', XPAINT);
        WriteDimOnCostType(MakeAdjustments.Convert('996410'), MakeAdjustments.Convert('996490'), '', XCONSULTING);
        WriteDimOnCostType(MakeAdjustments.Convert('996710'), MakeAdjustments.Convert('996910'), XSALES, '');

        WriteDimOnCostType(MakeAdjustments.Convert('997210'), MakeAdjustments.Convert('997210'), '', XFURNITURE);
        WriteDimOnCostType(MakeAdjustments.Convert('997220'), MakeAdjustments.Convert('997220'), '', XCHAIRS);
        WriteDimOnCostType(MakeAdjustments.Convert('997230'), MakeAdjustments.Convert('997230'), '', XACCESSO);

        WriteDimOnCostType(MakeAdjustments.Convert('997110'), MakeAdjustments.Convert('997110'), '', XPAINT);
        WriteDimOnCostType(MakeAdjustments.Convert('997120'), MakeAdjustments.Convert('997120'), '', XFITTINGS);
        WriteDimOnCostType(MakeAdjustments.Convert('997130'), MakeAdjustments.Convert('997130'), '', XFITTINGS);
        WriteDimOnCostType(MakeAdjustments.Convert('998710'), MakeAdjustments.Convert('998750'), XPERS, '');
        WriteDimOnCostType(MakeAdjustments.Convert('998110'), MakeAdjustments.Convert('998120'), XBUILDING, '');
        WriteDimOnCostType(MakeAdjustments.Convert('998130'), MakeAdjustments.Convert('998130'), XWORKSHOP, '');
        WriteDimOnCostType(MakeAdjustments.Convert('998510'), MakeAdjustments.Convert('998530'), XVEHICLE, '');

        // BK outcommented  - not needed in W1
        // WriteDimOnCostType(MakeAdjustments.Convert('996300'),MakeAdjustments.Convert('996399'),Text006,'');

        WriteDimOnCostType(MakeAdjustments.Convert('996410'), MakeAdjustments.Convert('996490'), XBUILDING, '');
        WriteDimOnCostType(MakeAdjustments.Convert('998210'), MakeAdjustments.Convert('998240'), XADM, '');
        WriteDimOnCostType(MakeAdjustments.Convert('998410'), MakeAdjustments.Convert('998450'), XADVERT, '');
        WriteDimOnCostType(MakeAdjustments.Convert('998610'), MakeAdjustments.Convert('998640'), XADM, '');
        WriteDimOnCostType(MakeAdjustments.Convert('999210'), MakeAdjustments.Convert('999270'), XADM, '');
        WriteDimOnCostType(MakeAdjustments.Convert('998810'), MakeAdjustments.Convert('998830'), XBUILDING, '');
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
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        // Create new Cost Type  --> may need localization.. adjust also in definecostallocation()
        WriteCostType('8725', XEmployersSalary, "Cost Account Type"::"Cost Type", XGL, '', '');
        WriteCostType('9225', XCalcInterestOnAssets, "Cost Account Type"::"Cost Type", XADM, '', '');

        WriteCostType('9900', XALLOCATIONS, "Cost Account Type"::"Begin-Total", '', '', '');   // From
        WriteCostType('9901', XInitialCostCenter, "Cost Account Type"::"Cost Type", '', '', '');
        WriteCostType('9902', XMainCostCenter, "Cost Account Type"::"Cost Type", '', '', '');
        WriteCostType('9903', XAllocOfCostObject, "Cost Account Type"::"Cost Type", '', '', '');
        WriteCostType('9999', XTOTALALLOC, "Cost Account Type"::"End-Total", '', '', '');  // To

        WriteCostType('9920', XActualAccurals, "Cost Account Type"::"Cost Type", XACTACCR, '', '');

        // Indent Cost Types
        CostAccountMgt.IndentCostTypes(false);

        // Transfer Cost Types to GLAccounts / check
        CostAccountMgt.LinkCostTypesToGLAccounts();
    end;

    procedure WriteCostType(CostTypeNo: Code[20]; CostTypeName: Text[100]; Type: Enum "Cost Account Type"; CostCenterCode: Code[20]; CostObjectCode: Code[20]; CostGLAccountRange: Text[50])
    var
        CostType: Record "Cost Type";
    begin
        CostType.Init();
        CostType."No." := CostTypeNo;
        CostType.Name := CostTypeName;
        CostType.Type := Type;
        CostType."Cost Center Code" := CostCenterCode;
        CostType."Cost Object Code" := CostObjectCode;
        CostType."G/L Account Range" := CostGLAccountRange; // NAVCZ
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

