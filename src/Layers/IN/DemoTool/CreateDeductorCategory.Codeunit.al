codeunit 101124 "Create Deductor Category"
{
    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('A', XA, false, false, false, false, false);
        InsertData('S', XS, true, true, true, false, true);
        InsertData('D', XD, true, true, false, true, true);
        InsertData('E', XE, true, true, true, false, true);
        InsertData('G', XG, true, true, false, true, true);
        InsertData('H', XH, true, true, true, false, true);
        InsertData('L', XL, true, true, false, false, true);
        InsertData('N', XN, true, true, true, false, true);
        InsertData('K', XK, false, false, false, false, true);
        InsertData('M', XM, false, false, false, false, true);
        InsertData('P', XP, false, false, false, false, true);
        InsertData('T', XT, false, false, false, false, true);
        InsertData('J', XJ, false, false, false, false, true);
        InsertData('B', XB, false, false, false, false, true);
        InsertData('Q', XQ, false, false, false, false, true);
        InsertData('F', XF, false, false, false, false, true);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XA: Label 'Central Government';
        XS: Label 'State Government';
        XD: Label 'Statutory body (Central Govt.)';
        XE: Label 'Statutory body (State Govt.)';
        XG: Label 'Autonomous body (Central Govt.)';
        XH: Label 'Autonomous body (State Govt.)';
        XL: Label 'Local Authority (Central Govt.)';
        XN: Label 'Local Authority (State Govt.)';
        XK: Label 'Company';
        XM: Label 'Branch / Division of Company';
        XP: Label 'Association of Person (AOP)';
        XT: Label 'Association of Person (Trust)';
        XJ: Label 'Artificial Juridical Person';
        XB: Label 'Body of Individuals';
        XQ: Label 'Individual/HUF';
        XF: Label 'Firm';



    procedure InsertMiniAppData()
    begin
        AddDeductoreCategoryForMini();
    end;

    local procedure AddDeductoreCategoryForMini()
    begin
        DemoDataSetup.Get();
        InsertData('A', XA, false, false, false, false, false);
        InsertData('S', XS, true, true, true, false, true);
        InsertData('D', XD, true, true, false, true, true);
        InsertData('E', XE, true, true, true, false, true);
        InsertData('G', XG, true, true, false, true, true);
        InsertData('H', XH, true, true, true, false, true);
        InsertData('L', XL, true, true, false, false, true);
        InsertData('N', XN, true, true, true, false, true);
        InsertData('K', XK, false, false, false, false, true);
        InsertData('M', XM, false, false, false, false, true);
        InsertData('P', XP, false, false, false, false, true);
        InsertData('T', XT, false, false, false, false, true);
        InsertData('J', XJ, false, false, false, false, true);
        InsertData('B', XB, false, false, false, false, true);
        InsertData('Q', XQ, false, false, false, false, true);
        InsertData('F', XF, false, false, false, false, true);
    end;

    procedure InsertData(Code: Code[1]; Description: Text[50]; PAO: Boolean; DDO: Boolean; StateMandatory: Boolean; MinistryMandate: Boolean; TransferVoucherMandate: Boolean)
    var
        DeductorCategory: Record "Deductor Category";
    begin
        DeductorCategory.Init();
        DeductorCategory.Validate(Code, Code);
        DeductorCategory.Validate(Description, Description);
        DeductorCategory.Validate("PAO Code Mandatory", PAO);
        DeductorCategory.Validate("DDO Code Mandatory", DDO);
        DeductorCategory.Validate("State Code Mandatory", StateMandatory);
        DeductorCategory.Validate("Ministry Details Mandatory", MinistryMandate);
        DeductorCategory.Validate("Transfer Voucher No. Mandatory", TransferVoucherMandate);
        DeductorCategory.Insert();
    end;
}