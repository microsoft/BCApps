codeunit 101096 "Create G/L Budget Entry"
{

    trigger OnRun()
    begin
        InsertData('51-1002', 19021031D, '1103000', 600000);
        InsertData('50-1000', 19021015D, '2102020', -75000);
        InsertData('50-1000', 19021031D, '2102020', -112920);
        InsertData('50-1000', 19021115D, '2102020', -75000);
        InsertData('50-1000', 19021130D, '2102020', -112920);
        InsertData('50-1000', 19031231D, '2102020', 112920);
        InsertData('50-1000', 19021215D, '2102020', -75000);
        InsertData('50-1000', 19021231D, '2102020', -112920);
        InsertData('51-1001', 19021031D, '2102030', -100000);
        InsertData('51-1001', 19021130D, '2102030', -100000);
        InsertData('51-1001', 19021231D, '2102030', -100000);
        InsertData('51-1001', 19021231D, '2200100', -244500);
        InsertData('52-2002', 19021231D, '2200100', -195319.22);
        InsertData('51-1001', 19021130D, '1103000', 124000);
        InsertData('51-1001', 19021231D, '1103000', 236000);
        InsertData('52-1001', 19021031D, '2100010', -960000);
        InsertData('51-1002', 19021001D, '2100010', -600000);
        InsertData('52-2002', 19021130D, '2200100', -176936.22);
        InsertData('51-1001', 19021130D, '2200100', -540000);
        InsertData('51-1001', 19021030D, '2200100', -600000);
        InsertData('51-1001', 19021001D, '1201000', 1900);
        InsertData('51-1001', 19021101D, '1201000', 3800);
        InsertData('51-1001', 19021201D, '1201000', 5182000);
        InsertData('51-1002', 19021210D, '7101010', -10000);
        InsertData('51-1002', 19021201D, '6101010', -1285000);
        InsertData('51-1002', 19021201D, '6101010', -8260000);
        InsertData('51-1002', 19031001D, '6101010', 3540000);
        InsertData('51-1002', 19021001D, '6101010', -3540000);
        InsertData('51-1002', 19021001D, '6101010', -650000);
        InsertData('51-1002', 19021101D, '6101010', -525000);
        InsertData('51-1001', 19021101D, '6101030', -10435000);
        InsertData('51-1001', 19021201D, '6101030', -1500000);
        InsertData('51-1001', 19021015D, '5102120', 15000000);
        InsertData('51-1001', 19021115D, '5102210', 20000000);
        InsertData('52-2002', 19021001D, '5102110', 28550000);
        InsertData('51-1002', 19021001D, '5101010', 7000000);
        InsertData('52-2002', 19030101D, '1103000', 30000);
        InsertData('52-2002', 19030201D, '1103000', 300000);
        InsertData('52-2002', 19030101D, '1103000', 300000);
        InsertData('50-1000', 19030115D, '2102020', -75000);
        InsertData('50-1000', 19030131D, '2102020', -112920);
        InsertData('50-1000', 19030215D, '2102020', -75000);
        InsertData('50-1000', 19030228D, '2102020', -112920);
        InsertData('50-1000', 19030315D, '2102020', -75000);
        InsertData('50-1000', 19030331D, '2102020', -112920);
        InsertData('51-1001', 19030131D, '2102030', -84672);
        InsertData('51-1001', 19030228D, '2102030', -84672);
        InsertData('51-1001', 19030131D, '2102030', -84672);
        InsertData('51-1001', 19030101D, '2100020', 570000);
        InsertData('51-1001', 19030101D, '2102190', -600000);
        InsertData('51-1001', 19030115D, '2102161', -380000);
        InsertData('51-1001', 19030101D, '2200100', -100000);
        InsertData('51-1001', 19030201D, '2200100', -100000);
        InsertData('51-1001', 19030301D, '2200100', -100000);
        InsertData('52-2002', 19030101D, '2200100', -180000);
        InsertData('52-2002', 19030201D, '2200100', -180000);
        InsertData('52-2002', 19030301D, '2200100', -180000);
        InsertData('51-1001', 19030101D, '5102120', -15000000);
        InsertData('51-1001', 19030101D, '5102220', 10000000);
        InsertData('52-2002', 19030101D, '5102110', -3600000);
        InsertData('51-1002', 19030125D, '5101010', 14000000);
        InsertData('51-1001', 19030101D, '7101010', -475000);
    end;

    var
        "G/L Budget Entry": Record "G/L Budget Entry";
        "Entry No.": Integer;
        CA: Codeunit "Make Adjustments";

    procedure InsertData("G/L Account No.": Code[20]; Date: Date; "Global Dimension 2 Code": Code[20]; Amount: Decimal)
    begin
        Date := CA.AdjustDate(Date);
        "G/L Budget Entry".Init();
        "Entry No." := "Entry No." + 1;
        "G/L Budget Entry".Validate("Entry No.", "Entry No.");
        "G/L Budget Entry".Validate("Budget Name", Format(Date2DMY(Date, 3)));
        "G/L Budget Entry".Validate("G/L Account No.", CA.Convert("G/L Account No."));
        "G/L Budget Entry".Validate(Date, Date);
        "G/L Budget Entry".Validate("Global Dimension 2 Code", "Global Dimension 2 Code");
        "G/L Budget Entry".Validate(Amount, Amount);
        "G/L Budget Entry".Insert(true);
    end;
}

