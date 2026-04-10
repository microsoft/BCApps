codeunit 132473 "Payroll Service Extension Mock"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempAvailableServiceConnection: Record "Service Connection" temporary;
        TempNewGenJournalLine: Record "Gen. Journal Line" temporary;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payroll Management", 'OnRegisterPayrollService', '', false, false)]
    local procedure RegisterPayrollService(var TempServiceConnection: Record "Service Connection" temporary)
    begin
        TempAvailableServiceConnection.Reset();
        if TempAvailableServiceConnection.FindSet() then
            repeat
                TempServiceConnection.Copy(TempAvailableServiceConnection);
                TempServiceConnection.Insert(true);
            until TempAvailableServiceConnection.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payroll Management", 'OnImportPayroll', '', false, false)]
    procedure ImportPayrollTransactions(var TempServiceConnection: Record "Service Connection" temporary; GenJournalLine: Record "Gen. Journal Line")
    begin
        TempNewGenJournalLine.Reset();
        if TempNewGenJournalLine.FindSet() then
            repeat
                GenJournalLine.SetRange("Line No.");
                GenJournalLine.Init();
                GenJournalLine.TransferFields(TempNewGenJournalLine);
                GenJournalLine."Line No." := GetGenJournalNewLineNo(TempNewGenJournalLine);
                GenJournalLine.Insert();
            until TempNewGenJournalLine.Next() = 0;
    end;

    procedure SetAvailableServiceConnections(var TempSetupAvailableServiceConnection: Record "Service Connection" temporary)
    begin
        TempAvailableServiceConnection.Reset();
        TempAvailableServiceConnection.DeleteAll();

        if TempSetupAvailableServiceConnection.FindSet() then
            repeat
                TempAvailableServiceConnection.Copy(TempSetupAvailableServiceConnection);
                TempAvailableServiceConnection.Insert();
            until TempSetupAvailableServiceConnection.Next() = 0;
    end;

    procedure SetNewGenJournalLine(var TempSetupGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
        TempNewGenJournalLine.Reset();
        TempNewGenJournalLine.DeleteAll();

        if TempSetupGenJournalLine.FindSet() then
            repeat
                TempNewGenJournalLine.Copy(TempSetupGenJournalLine);
                TempNewGenJournalLine.Insert();
            until TempSetupGenJournalLine.Next() = 0;
    end;

    procedure GetAvailableServiceConnections(var TempSetupAvailableServiceConnection: Record "Service Connection" temporary)
    begin
        TempAvailableServiceConnection.Reset();
        if TempAvailableServiceConnection.FindSet() then
            repeat
                TempSetupAvailableServiceConnection.Copy(TempAvailableServiceConnection);
                TempSetupAvailableServiceConnection.Insert();
            until TempAvailableServiceConnection.Next() = 0;
    end;

    local procedure GetGenJournalNewLineNo(var GenJournalLine: Record "Gen. Journal Line"): Integer
    var
        LastGenJournalLine: Record "Gen. Journal Line";
        LineNo: Integer;
    begin
        LastGenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        LastGenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        if LastGenJournalLine.FindLast() then
            LineNo := LastGenJournalLine."Line No." + 10000
        else
            LineNo := 10000;
        exit(LineNo);
    end;

    procedure CleanUp()
    begin
        TempAvailableServiceConnection.Reset();
        TempAvailableServiceConnection.DeleteAll();
        TempNewGenJournalLine.Reset();
        TempNewGenJournalLine.DeleteAll();
    end;
}

