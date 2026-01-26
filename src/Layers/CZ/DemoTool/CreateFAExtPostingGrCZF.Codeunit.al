codeunit 163532 "Create FA Ext. Posting Gr. CZF"
{

    trigger OnRun()
    begin
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XCAR'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XCAR'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '996411', '996411', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XCAR'), 2, CreateFAMaintenance.GetMaintenanceCode('XSPAREPARTS'), '', '', '998210', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XCAR'), 2, CreateFAMaintenance.GetMaintenanceCode('XSERVICE'), '', '', '998130', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XMACHINERY'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XMACHINERY'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '996411', '996411', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XMACHINERY'), 2, CreateFAMaintenance.GetMaintenanceCode('XSPAREPARTS'), '', '', '998210', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XMACHINERY'), 2, CreateFAMaintenance.GetMaintenanceCode('XSERVICE'), '', '', '998130', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XTELEPHONE'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XTELEPHONE'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '996411', '996411', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XTELEPHONE'), 2, CreateFAMaintenance.GetMaintenanceCode('XSPAREPARTS'), '', '', '998210', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XTELEPHONE'), 2, CreateFAMaintenance.GetMaintenanceCode('XSERVICE'), '', '', '998130', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XBUILDING'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XBUILDING'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '996411', '996411', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XBUILDING'), 2, CreateFAMaintenance.GetMaintenanceCode('XSPAREPARTS'), '', '', '998210', '', '', '', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XBUILDING'), 2, CreateFAMaintenance.GetMaintenanceCode('XSERVICE'), '', '', '998130', '', '', '', 0, 0, 0);
    end;

    var
        FAExtendedPostingGroupCZF: Record "FA Extended Posting Group CZF";
        CreateFAPostingGroup: Codeunit "Create FA Posting Group";
        CreateReasonCode: Codeunit "Create Reason Code";
        CreateFAMaintenance: Codeunit "Create FA Maintenance";
        CA: Codeunit "Make Adjustments";

    procedure InsertData("FA Posting Group Code": Code[10]; "FA Posting Type": Option; "Code": Code[10]; "Book Val. Acc. on Disp. (Gain)": Code[20]; "Book Val. Acc. on Disp. (Loss)": Code[20]; "Maintenance Expense Account": Code[20]; "Maintenance Bal. Acc.": Code[20]; "Sales Acc. On Disp. (Gain)": Code[20]; "Sales Acc. On Disp. (Loss)": Code[20]; "Allocated Book Value % (Gain)": Decimal; "Allocated Book Value % (Loss)": Decimal; "Allocated Maintenance %": Decimal)
    begin
        FAExtendedPostingGroupCZF.Init();
        FAExtendedPostingGroupCZF.Validate("FA Posting Group Code", "FA Posting Group Code");
        FAExtendedPostingGroupCZF.Validate("FA Posting Type", "FA Posting Type");
        FAExtendedPostingGroupCZF.Validate(Code, Code);
        FAExtendedPostingGroupCZF.Validate("Book Val. Acc. on Disp. (Gain)", CA.Convert("Book Val. Acc. on Disp. (Gain)"));
        FAExtendedPostingGroupCZF.Validate("Book Val. Acc. on Disp. (Loss)", CA.Convert("Book Val. Acc. on Disp. (Loss)"));
        FAExtendedPostingGroupCZF.Validate("Maintenance Expense Account", CA.Convert("Maintenance Expense Account"));
        FAExtendedPostingGroupCZF.Validate("Maintenance Balance Account", CA.Convert("Maintenance Bal. Acc."));
        FAExtendedPostingGroupCZF.Validate("Sales Acc. On Disp. (Gain)", CA.Convert("Sales Acc. On Disp. (Gain)"));
        FAExtendedPostingGroupCZF.Validate("Sales Acc. On Disp. (Loss)", CA.Convert("Sales Acc. On Disp. (Loss)"));
        FAExtendedPostingGroupCZF.Validate("Allocated Book Value % (Gain)", "Allocated Book Value % (Gain)");
        FAExtendedPostingGroupCZF.Validate("Allocated Book Value % (Loss)", "Allocated Book Value % (Loss)");
        FAExtendedPostingGroupCZF.Validate("Allocated Maintenance %", "Allocated Maintenance %");
        FAExtendedPostingGroupCZF.Insert();
    end;

    procedure CreateTrialData()
    begin
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XBUILDING'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '991140', '991140', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XBUILDING'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '991140', '991140', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XFURNITUREFIXTURES'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '991240', '991240', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XFURNITUREFIXTURES'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '991240', '991240', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XSOFTWARE'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '992000', '992000', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XSOFTWARE'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '992000', '992000', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XVEHICLES'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '991340', '991340', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XVEHICLES'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '991340', '991340', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XEQUIPMENT'), 1, CreateReasonCode.GetReasonCode('XLIQUID'), '998840', '998840', '', '', '991240', '991240', 0, 0, 0);
        InsertData(CreateFAPostingGroup.GetFAPostingGroupCode('XEQUIPMENT'), 1, CreateReasonCode.GetReasonCode('XSALE'), '995411', '995411', '', '', '991240', '991240', 0, 0, 0);
    end;
}
