codeunit 118803 "Create Text To Account Mapping"
{

    trigger OnRun()
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InsertData(XLondonPostmaster, MakeAdjustments.Convert('998640'));
    end;

    var
        XLondonPostmaster: Label 'London Postmaster';

    procedure CreateEvaluationData()
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InsertData(XLondonPostmaster, MakeAdjustments.Convert('998640'));
    end;

    local procedure InsertData(MappingText: Text[250]; DebitAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        LastLineNo: Integer;
    begin
        if not GLAccount.Get(DebitAccNo) then
            exit;

        if TextToAccountMapping.FindLast() then
            LastLineNo := TextToAccountMapping."Line No.";

        TextToAccountMapping."Line No." := LastLineNo + 10000;
        TextToAccountMapping."Mapping Text" := MappingText;
        TextToAccountMapping."Debit Acc. No." := DebitAccNo;
        if TextToAccountMapping.Insert() then;
    end;
}

