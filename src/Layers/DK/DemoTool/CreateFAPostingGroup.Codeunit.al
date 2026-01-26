codeunit 101803 "Create FA Posting Group"
{

    trigger OnRun()
    begin
        InsertData(XCAR, '991320', '991340', '991330', '991340', '998840', '998840', '998530', '998830', '991320');
        InsertData(XMACHINERY, '991220', '991240', '991230', '991240', '998840', '998840', '998640', '998820', '991220');
        InsertData(XTELEPHONE, '991220', '991240', '991230', '991240', '998840', '998840', '998640', '998820', '991220');
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
        InsertData(XEQUIPMENT, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');

        InsertData(XPATENTS, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
        InsertData(XGOODWILL, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
        InsertData(XPLANT, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
        InsertData(XPROPERTY, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
        InsertData(XVEHICLES, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
        InsertData(XFURNITUREFIXTURES, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
        InsertData(XIP, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
        InsertData(XLEASEHOLD, '12100', '12400', '12300', '12400', '01600', '02600', '05020', '12100', '06100');
    end;
}

