codeunit 101803 "Create FA Posting Group"
{

    trigger OnRun()
    begin
        InsertData(XCAR, '2180001', '2818001', '2180001', '2818001', '', '6710001', '6220001', '6810001', '2180001');
        InsertData(XMACHINERY, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XTELEPHONE, '2190001', '2819001', '2190001', '2819001', '', '6710001', '6220001', '6810001', '2190001');
    end;

    var
        "FA Posting Group": Record "FA Posting Group";
        CA: Codeunit "Make Adjustments";
        XCAR: Label 'CAR';
        XMACHINERY: Label 'MACHINERY';
        XTELEPHONE: Label 'TELEPHONE';
        XEQUIPMENT: Label 'EQUIPMENT';
        XPATENTS: Label 'PATENTS';
        XGOODWILL: Label 'GOODWILL';
        XPLANT: Label 'PLANT';
        XPROPERTY: Label 'PROPERTY';
        XVEHICLES: Label 'VEHICLES';
        XFURNITUREFIXTURES: Label 'FURNITURE';
        XIP: Label 'IP';
        XLEASEHOLD: Label 'LEASEHOLD';

    procedure InsertData("Code": Code[10]; "Acquisition Cost Account": Code[20]; "Accum. Depreciation Account": Code[20]; "Acq. Cost Acc. on Disposal": Code[20]; "Accum. Depr. Acc. on Disposal": Code[20]; "Gains Acc. on Disposal": Code[20]; "Losses Acc. on Disposal": Code[20]; "Maintenance Expense Account": Code[20]; "Depreciation Expense Acc.": Code[20]; "Acquisition Cost Bal. Acc.": Code[20])
    begin
        "FA Posting Group".Init();
        "FA Posting Group".Validate(Code, Code);
        "FA Posting Group".Validate("Acquisition Cost Account", CA.Convert("Acquisition Cost Account"));
        "FA Posting Group".Validate("Accum. Depreciation Account", CA.Convert("Accum. Depreciation Account"));
        "FA Posting Group".Validate("Acq. Cost Acc. on Disposal", CA.Convert("Acq. Cost Acc. on Disposal"));
        "FA Posting Group".Validate("Accum. Depr. Acc. on Disposal", CA.Convert("Accum. Depr. Acc. on Disposal"));
        "FA Posting Group".Validate("Gains Acc. on Disposal", CA.Convert("Gains Acc. on Disposal"));
        "FA Posting Group".Validate("Losses Acc. on Disposal", CA.Convert("Losses Acc. on Disposal"));
        "FA Posting Group".Validate("Maintenance Expense Account", CA.Convert("Maintenance Expense Account"));
        "FA Posting Group".Validate("Depreciation Expense Acc.", CA.Convert("Depreciation Expense Acc."));
        "FA Posting Group".Validate("Acquisition Cost Bal. Acc.", CA.Convert("Acquisition Cost Bal. Acc."));
        "FA Posting Group".Insert();
    end;

    procedure InsertDataKey("Code": Code[10])
    begin
        "FA Posting Group".Init();
        "FA Posting Group".Validate(Code, Code);
        "FA Posting Group".Insert();
    end;

    procedure CreateTrialData()
    begin
        InsertData(XEQUIPMENT, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');

        InsertData(XPATENTS, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XGOODWILL, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XPLANT, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XPROPERTY, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XVEHICLES, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XFURNITUREFIXTURES, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XIP, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
        InsertData(XLEASEHOLD, '2130001', '2813001', '2130001', '2813001', '', '6710001', '6220001', '6810001', '2130001');
    end;
}

