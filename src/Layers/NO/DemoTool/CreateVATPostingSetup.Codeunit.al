codeunit 101325 "Create VAT Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                begin
                    InsertVATReportingCodes();
                    InsertData(XCUSTNOVAT, XWITHOUT, XWITHOUT, 0, 0, 'E', '0', '84', '');
                    InsertData(XCUSTNOVAT, XHIGH, XWITHOUT, 0, 0, 'E', '', '81', '81');
                    InsertData(XCUSTNOVAT, XOUTSIDE, XOUTSIDE, 0, 0, 'E', '', '83', '83');
                    InsertData(XCUSTNOVAT, XLOW, XWITHOUT, 0, 0, 'E', '', '82', '82');
                    InsertData(XCUSTHIGH, XFULL, XFULL, 0, 2, 'E', '13', '52', '');
                    InsertData(XCUSTHIGH, XWITHOUT, XWITHOUT, 0, 0, 'E', '', '5', '');
                    InsertData(XCUSTHIGH, XHIGH, XHIGH, 25, 0, 'S', '3', '3', '');
                    InsertData(XCUSTHIGH, XOUTSIDE, XOUTSIDE, 0, 0, 'E', '', '52', '');
                    InsertData(XCUSTHIGH, XLOW, XLOW, 11.11, 0, 'S', '', '33', '');
                    InsertData(XCUSTLOW, XWITHOUT, XWITHOUT, 0, 0, 'E', '', '5', '');
                    InsertData(XCUSTLOW, XHIGH, XLOW, 11.11, 0, 'S', '', '31', '');
                    InsertData(XCUSTLOW, XOUTSIDE, XOUTSIDE, 0, 0, 'E', '', '52', '');
                    InsertData(XCUSTLOW, XLOW, XLOW, 11.11, 0, 'S', '', '32', '');
                    InsertData(XVENDNOVAT, XWITHOUT, XWITHOUT, 0, 0, 'E', '', '89', '');
                    InsertData(XVENDNOVAT, XHIGH, XWITHOUT, 0, 0, 'E', '', '88', '88');
                    InsertData(XVENDNOVAT, XLOW, XWITHOUT, 0, 0, 'E', '', '87', '');
                    InsertData(XVENDNOVAT, XSERVVAT, XWITHOUT, 25, 1, 'S', '14', '86', '86');
                    InsertData(XVENDHIGH, XFULL, XFULL, 0, 2, 'E', '11', '', '15');
                    InsertData(XVENDHIGH, XWITHOUT, XWITHOUT, 0, 0, 'E', '', '', '13');
                    InsertData(XVENDHIGH, XHIGH, XHIGH, 25, 0, 'S', '1', '', '1');
                    InsertData(XVENDHIGH, XLOW, XLOW, 25, 0, 'S', '', '', '1');
                    InsertData(XVENDLOW, XWITHOUT, XWITHOUT, 0, 0, 'E', '', '', '13');
                    InsertData(XVENDLOW, XHIGH, XLOW, 11.11, 0, 'S', '', '', '11');
                    InsertData(XVENDLOW, XLOW, XLOW, 11.11, 0, 'S', '', '', '12');
                end;
            DemoDataSetup."Company Type"::"Sales Tax":
                InsertSalesTaxData('E');
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        XPostingSetupTxt: Label 'Setup for %1 / %2', Comment = '%1 = Business Group; %2 = Product Group';
        XFULL: Label 'FULL';
        XWITHOUT: Label 'WITHOUT';
        XHIGH: Label 'HIGH';
        XLOW: Label 'LOW';
        XOUTSIDE: Label 'OUTSIDE';
        XSERVVAT: Label 'SERVICE';
        XCUSTNOVAT: Label 'CUSTNOVAT';
        XCUSTHIGH: Label 'CUSTHIGH';
        XCUSTLOW: Label 'CUSTLOW';
        XVENDNOVAT: Label 'VENDNOVAT';
        XVENDHIGH: Label 'VENDHIGH';
        XVENDLOW: Label 'VENDLOW';
        XVATCode_0: Label 'No VAT treatment';
        XVATCode_1: Label 'Input VAT deduct. (domestic)';
        XVATCode_11: Label 'Input VAT deduct. (domestic)';
        XVATCode_12: Label 'Input VAT deduct. (domestic)';
        XVATCode_13: Label 'Input VAT deduct. (domestic)';
        XVATCode_14: Label 'Input VAT deduct. (import)';
        XVATCode_15: Label 'Input VAT deduct. (import)';
        XVATCode_2: Label 'Purchase - VAT and Inv. Tax';
        XVATCode_21: Label 'Basis on import of goods';
        XVATCode_22: Label 'Basis on import of goods';
        XVATCode_23: Label 'Basis on import of goods';
        XVATCode_3: Label 'Output VAT';
        XVATCode_31: Label 'Output VAT';
        XVATCode_32: Label 'Output VAT';
        XVATCode_33: Label 'Output VAT';
        XVATCode_4: Label 'Purch. - VAT and 0% Inv. Tax';
        XVATCode_5: Label 'No output VAT';
        XVATCode_51: Label 'Dom. sales of rev.ch./VAT obl';
        XVATCode_52: Label 'Export of goods and services';
        XVATCode_6: Label 'Not liable to VAT treatment';
        XVATCode_7: Label 'No VAT treatment';
        XVATCode_81: Label 'Imp. of goods, VAT deduct.';
        XVATCode_82: Label 'Imp. of goods, w/o ded. of VAT';
        XVATCode_83: Label 'Imp. of goods, VAT deduct.';
        XVATCode_84: Label 'Imp. of goods, w/o ded. of VAT';
        XVATCode_85: Label 'Imp. of goods, n/a for VAT';
        XVATCode_86: Label 'Serv.purch.abroad, VAT deduct.';
        XVATCode_87: Label 'Serv.purch.abroad, w/o ded.VAT';
        XVATCode_88: Label 'Serv.purch.abroad, VAT deduct.';
        XVATCode_89: Label 'Serv.purch.abroad, w/o ded.VAT';
        XVATCode_91: Label 'Purch. of emiss.tr,gold,deduct';
        XVATCode_92: Label 'Pur.of emiss.tr,gold,w/o deduc';

    procedure InsertSalesTaxData(TaxCategory: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", '');
        VATPostingSetup.Validate("VAT Prod. Posting Group", '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        VATPostingSetup.Insert();
    end;

    procedure InsertData("VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "VAT Identifier": Code[10]; "VAT %": Decimal; "VAT Calculation Type": Option; TaxCategory: Code[10]; VATCode: Code[10]; SalesVATReportingCode: Code[10]; PurchaseVATReportingCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATPostingSetup.Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        VATPostingSetup.Validate(Description,
          CopyStr(
            StrSubstNo(XPostingSetupTxt, "VAT Bus. Posting Group", "VAT Prod. Posting Group"),
            1, MaxStrLen(VATPostingSetup.Description)));
        VATPostingSetup.Validate("VAT %", "VAT %");
        VATPostingSetup.Validate("VAT Calculation Type", "VAT Calculation Type");
        VATPostingSetup."VAT Identifier" := "VAT Identifier";
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        VATPostingSetup.Validate("Adjust for Payment Discount", DemoDataSetup."Adjust for Payment Discount");
        if DemoDataSetup."Advanced Setup" then
            VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);

        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            case VATPostingSetup."VAT Prod. Posting Group" of
                XHIGH:
                    SetAccounts(VATPostingSetup, '995610', '995630', '995630', '995615', '995635', '995625');
                XLOW:
                    SetAccounts(VATPostingSetup, '995611', '995631', '995621', '995616', '995636', '995626');
                XWITHOUT:
                    SetAccounts(VATPostingSetup, '995610', '995630', '995630', '995615', '995635', '995625');
                else
                    SetAccounts(VATPostingSetup, '995610', '995630', '995630', '995615', '995635', '995625');
            end;

        VATPostingSetup.Validate("VAT Number", VATCode);
        VATPostingSetup.Validate("Sale VAT Reporting Code", SalesVATReportingCode);
        VATPostingSetup.Validate("Purch. VAT Reporting Code", PurchaseVATReportingCode);
        if VATPostingSetup."VAT %" = 12 then
            VATPostingSetup."VAT Settlement Rate" := 1;

        VATPostingSetup.Insert();
    end;

    local procedure SetAccounts(var VATPostingSetup: Record "VAT Posting Setup"; SalesVATAccount: Code[20]; PurchaseVATAccount: Code[20]; ReverseChargeVATAcc: Code[20]; SalesVATUnrealAccount: Code[20]; PurchaseVATUnrealAccount: Code[20]; ReverseChargeVATUnrealAcc: Code[20])
    begin
        VATPostingSetup.Validate("Sales VAT Account", CA.Convert(SalesVATAccount));
        VATPostingSetup.Validate("Purchase VAT Account", CA.Convert(PurchaseVATAccount));
        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert(ReverseChargeVATAcc));
        if VATPostingSetup."Unrealized VAT Type" > 0 then begin
            VATPostingSetup.Validate("Sales VAT Unreal. Account", CA.Convert(SalesVATUnrealAccount));
            VATPostingSetup.Validate("Purch. VAT Unreal. Account", CA.Convert(PurchaseVATUnrealAccount));
            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", CA.Convert(ReverseChargeVATUnrealAcc));
        end;
    end;

    local procedure InsertVATReportingCodes()
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        InsertVATReportingCode('0', false, XVATCode_0, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('1', false, XVATCode_1, VATReportingCode."Trade Settlement 2017 Box No."::"14", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('11', false, XVATCode_11, VATReportingCode."Trade Settlement 2017 Box No."::"15", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('12', false, XVATCode_12, VATReportingCode."Trade Settlement 2017 Box No."::"15", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('13', false, XVATCode_13, VATReportingCode."Trade Settlement 2017 Box No."::"16", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('14', false, XVATCode_14, VATReportingCode."Trade Settlement 2017 Box No."::"17", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('15', false, XVATCode_15, VATReportingCode."Trade Settlement 2017 Box No."::"18", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('2', false, XVATCode_2, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('21', false, XVATCode_21, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('22', false, XVATCode_22, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('23', false, XVATCode_23, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('3', true, XVATCode_3, VATReportingCode."Trade Settlement 2017 Box No."::"3", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('31', true, XVATCode_31, VATReportingCode."Trade Settlement 2017 Box No."::"4", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('32', true, XVATCode_32, VATReportingCode."Trade Settlement 2017 Box No."::"4", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('33', true, XVATCode_33, VATReportingCode."Trade Settlement 2017 Box No."::"5", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('4', false, XVATCode_4, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('5', true, XVATCode_5, VATReportingCode."Trade Settlement 2017 Box No."::"6", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('51', true, XVATCode_51, VATReportingCode."Trade Settlement 2017 Box No."::"7", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('52', true, XVATCode_52, VATReportingCode."Trade Settlement 2017 Box No."::"8", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('6', true, XVATCode_6, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('7', true, XVATCode_7, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('81', false, XVATCode_81, VATReportingCode."Trade Settlement 2017 Box No."::"9", VATReportingCode."Reverse Charge Report Box No."::"17");
        InsertVATReportingCode('82', false, XVATCode_82, VATReportingCode."Trade Settlement 2017 Box No."::"9", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('83', false, XVATCode_83, VATReportingCode."Trade Settlement 2017 Box No."::"10", VATReportingCode."Reverse Charge Report Box No."::"18");
        InsertVATReportingCode('84', false, XVATCode_84, VATReportingCode."Trade Settlement 2017 Box No."::"10", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('85', false, XVATCode_85, VATReportingCode."Trade Settlement 2017 Box No."::" ", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('86', false, XVATCode_86, VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::"17");
        InsertVATReportingCode('87', false, XVATCode_87, VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('88', false, XVATCode_88, VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::"17");
        InsertVATReportingCode('89', false, XVATCode_89, VATReportingCode."Trade Settlement 2017 Box No."::"12", VATReportingCode."Reverse Charge Report Box No."::" ");
        InsertVATReportingCode('91', false, XVATCode_91, VATReportingCode."Trade Settlement 2017 Box No."::"13", VATReportingCode."Reverse Charge Report Box No."::"14");
        InsertVATReportingCode('92', false, XVATCode_92, VATReportingCode."Trade Settlement 2017 Box No."::"14", VATReportingCode."Reverse Charge Report Box No."::" ");
    end;

    local procedure InsertVATReportingCode(NewCode: Code[20]; IsSales: Boolean; NewDescription: Text; BoxNo: Option; ReverseChargeBoxNo: Option)
    var
        VATReportingCode: Record "VAT Reporting Code";
    begin
        VATReportingCode.Init();
        VATReportingCode.Validate(Code, NewCode);
        VATReportingCode.Validate("Test Gen. Posting Type", VATReportingCode."Test Gen. Posting Type"::" ");
        if IsSales then
            VATReportingCode.Validate("Gen. Posting Type", VATReportingCode."Gen. Posting Type"::Sale)
        else
            VATReportingCode.Validate("Gen. Posting Type", VATReportingCode."Gen. Posting Type"::Purchase);
        VATReportingCode.Validate(Description, CopyStr(NewDescription, 1, MaxStrLen(VATReportingCode.Description)));
        VATReportingCode.Validate("Trade Settlement 2017 Box No.", BoxNo);
        VATReportingCode.Validate("Reverse Charge Report Box No.", ReverseChargeBoxNo);
        if VATReportingCode.Insert() then;
    end;
}