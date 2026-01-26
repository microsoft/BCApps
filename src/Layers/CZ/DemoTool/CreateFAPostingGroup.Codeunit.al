codeunit 101803 "Create FA Posting Group"
{

    trigger OnRun()
    begin
        // NAVCZ
        InsertData(XCAR, '991310', '991340', '991310', '991340', '991310', '991340', '998130', '998830', '991320');
        InsertData(XMACHINERY, '991210', '991240', '991210', '991240', '991210', '991240', '998640', '998820', '991220');
        InsertData(XTELEPHONE, '991210', '991240', '991210', '991240', '991210', '991240', '998640', '998820', '991220');
        InsertData(XBUILDING, '991110', '991140', '991110', '991140', '991110', '991140', '998130', '998810', '991120');
        // NAVCZ
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
        XVEHICLES: Label 'VEHICLES';
        XFURNITUREFIXTURES: Label 'FURNITURE';
        XBUILDING: Label 'BUILDING';
        XSOFTWARE: Label 'SOFTWARE';

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
        // NAVCZ
        "FA Posting Group".Validate("Acq. Cost Bal. Acc. Disp. CZF", CA.Convert("Accum. Depreciation Account"));
        "FA Posting Group".Validate("Write-Down Account", CA.Convert("Acquisition Cost Account"));
        "FA Posting Group".Validate("Write-Down Acc. on Disposal", CA.Convert("Acquisition Cost Account"));
        "FA Posting Group".Validate("Appreciation Account", CA.Convert("Acquisition Cost Account"));
        "FA Posting Group".Validate("Appreciation Bal. Account", CA.Convert("Acquisition Cost Bal. Acc."));
        "FA Posting Group".Validate("Appreciation Acc. on Disposal", CA.Convert("Acquisition Cost Account"));
        "FA Posting Group".Validate("Apprec. Bal. Acc. on Disp.", CA.Convert("Accum. Depreciation Account"));
        "FA Posting Group".Validate("Sales Acc. on Disp. (Gain)", CA.Convert("Accum. Depreciation Account"));
        "FA Posting Group".Validate("Sales Acc. on Disp. (Loss)", CA.Convert("Accum. Depreciation Account"));
        "FA Posting Group".Validate("Sales Bal. Acc.", '395100');
        "FA Posting Group".Validate("Book Value Bal. Acc. Disp. CZF", CA.Convert("Accum. Depreciation Account"));
        "FA Posting Group".Validate("Custom 2 Account", CA.Convert("Acquisition Cost Bal. Acc."));
        "FA Posting Group".Validate("Custom 2 Account on Disposal", CA.Convert("Acquisition Cost Bal. Acc."));
        "FA Posting Group".Validate("Book Val. Acc. on Disp. (Gain)", '541100');
        "FA Posting Group".Validate("Book Val. Acc. on Disp. (Loss)", '541100');
        // NAVCZ

        "FA Posting Group".Insert();
    end;

    procedure InsertDataCZ("Code": Code[10]; "Acquisition Cost Account": Code[20]; "Accum. Depreciation Account": Code[20]; "Acq. Cost Acc. on Disposal": Code[20]; "Accum. Depr. Acc. on Disposal": Code[20]; "Gains Acc. on Disposal": Code[20]; "Losses Acc. on Disposal": Code[20]; "Maintenance Expense Account": Code[20]; "Depreciation Expense Acc.": Code[20]; "Acquisition Cost Bal. Acc.": Code[20])
    begin
        // NAVCZ
        "FA Posting Group".Init();
        "FA Posting Group".Validate(Code, Code);
        "FA Posting Group".Validate("Acquisition Cost Account", "Acquisition Cost Account");
        "FA Posting Group".Validate("Accum. Depreciation Account", "Accum. Depreciation Account");
        "FA Posting Group".Validate("Acq. Cost Acc. on Disposal", "Acq. Cost Acc. on Disposal");
        "FA Posting Group".Validate("Accum. Depr. Acc. on Disposal", "Accum. Depr. Acc. on Disposal");
        "FA Posting Group".Validate("Gains Acc. on Disposal", "Gains Acc. on Disposal");
        "FA Posting Group".Validate("Losses Acc. on Disposal", "Losses Acc. on Disposal");
        "FA Posting Group".Validate("Maintenance Expense Account", "Maintenance Expense Account");
        "FA Posting Group".Validate("Depreciation Expense Acc.", "Depreciation Expense Acc.");
        "FA Posting Group".Validate("Acquisition Cost Bal. Acc.", "Acquisition Cost Bal. Acc.");
        "FA Posting Group".Validate("Acq. Cost Bal. Acc. Disp. CZF", "Accum. Depreciation Account");
        "FA Posting Group".Validate("Write-Down Account", "Acquisition Cost Account");
        "FA Posting Group".Validate("Write-Down Acc. on Disposal", "Acquisition Cost Account");
        "FA Posting Group".Validate("Appreciation Account", "Acquisition Cost Account");
        "FA Posting Group".Validate("Appreciation Acc. on Disposal", "Acquisition Cost Account");
        "FA Posting Group".Validate("Appreciation Bal. Account", "Acquisition Cost Bal. Acc.");
        "FA Posting Group".Validate("Apprec. Bal. Acc. on Disp.", "Accum. Depreciation Account");
        "FA Posting Group".Validate("Sales Acc. on Disp. (Gain)", "Accum. Depreciation Account");
        "FA Posting Group".Validate("Sales Acc. on Disp. (Loss)", "Accum. Depreciation Account");
        "FA Posting Group".Validate("Sales Bal. Acc.", '395100');
        "FA Posting Group".Validate("Book Value Bal. Acc. Disp. CZF", "Accum. Depreciation Account");
        "FA Posting Group".Validate("Custom 2 Account", "Acquisition Cost Bal. Acc.");
        "FA Posting Group".Validate("Custom 2 Account on Disposal", "Acquisition Cost Bal. Acc.");
        "FA Posting Group".Validate("Book Val. Acc. on Disp. (Gain)", '541100');
        "FA Posting Group".Validate("Book Val. Acc. on Disp. (Loss)", '541100');

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
        // NAVCZ
        InsertDataCZ(XBUILDING, '021100', '081100', '021100', '081100', '551900', '551900', '511100', '551100', '042100');
        InsertDataCZ(XGOODWILL, '015100', '075100', '015100', '075100', '551900', '551900', '511100', '551700', '041100');
        InsertDataCZ(XFURNITUREFIXTURES, '022100', '082100', '022100', '082100', '551900', '551900', '511100', '551200', '042200');
        InsertDataCZ(XPATENTS, '012100', '072100', '012100', '072100', '551900', '551900', '511100', '551400', '041100');
        InsertDataCZ(XSOFTWARE, '013100', '073100', '013100', '073100', '551900', '551900', '511100', '551500', '041100');
        InsertDataCZ(XVEHICLES, '022300', '082300', '022300', '082300', '551900', '551900', '511100', '551300', '042300');
        InsertDataCZ(XEQUIPMENT, '022100', '082100', '022100', '082100', '551900', '551900', '511100', '551200', '042200');
    end;

    procedure GetFAPostingGroupCode(FAPostingGroupCode: Text): Code[10]
    begin
        case UpperCase(FAPostingGroupCode) of
            'XCAR':
                exit(XCAR);
            'XMACHINERY':
                exit(XMACHINERY);
            'XTELEPHONE':
                exit(XTELEPHONE);
            'XBUILDING':
                exit(XBUILDING);
            'XGOODWILL':
                exit(XGOODWILL);
            'XFURNITUREFIXTURES':
                exit(XFURNITUREFIXTURES);
            'XPATENTS':
                exit(XPATENTS);
            'XSOFTWARE':
                exit(XSOFTWARE);
            'XVEHICLES':
                exit(XVEHICLES);
            'XEQUIPMENT':
                exit(XEQUIPMENT);
        end;
    end;
}
