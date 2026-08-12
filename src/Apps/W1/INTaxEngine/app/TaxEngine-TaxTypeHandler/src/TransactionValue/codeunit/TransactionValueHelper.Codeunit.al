// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.TaxTypeHandler;

codeunit 20236 "Transaction Value Helper"
{
    var
        SeqNameTok: Label 'TaxTransactionValueId', Locked = true;

    procedure UpdateCaseID(var SourceRecordRef: RecordRef; TaxType: Code[20]; CaseID: Guid)
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.SetCurrentKey("Tax Record ID", "Tax Type");
        TaxTransactionValue.SetRange("Tax Type", TaxType);
        TaxTransactionValue.SetRange("Tax Record ID", SourceRecordRef.RecordId());
        TaxTransactionValue.SetFilter("Case ID", '<>%1', CaseID);
        if not TaxTransactionValue.IsEmpty() then
            TaxTransactionValue.ModifyAll("Case ID", CaseID);
    end;

    // Provides BigInteger IDs for Tax Transaction Value, replacing SQL AutoIncrement which is capped at MaxInt.
    procedure GetNextTransactionValueID(): BigInteger
    begin
        if not NumberSequence.Exists(SeqNameTok) then
            if not TryInitSequence() then
                ClearLastError();
        exit(NumberSequence.Next(SeqNameTok));
    end;

    // Seeds the sequence just above the current maximum ID so it never collides with existing rows. Runs once (first insert / after upgrade).
    [TryFunction]
    local procedure TryInitSequence()
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        StartID: BigInteger;
    begin
        TaxTransactionValue.ReadIsolation := IsolationLevel::ReadUncommitted;
        TaxTransactionValue.SetLoadFields(ID);
        if TaxTransactionValue.FindLast() then
            StartID := TaxTransactionValue.ID + 1
        else
            StartID := 1;

        NumberSequence.Insert(SeqNameTok, StartID - 1, 1);
        // Consume the seed so the first value handed out is strictly greater than the last existing ID.
        if NumberSequence.Next(SeqNameTok) = StartID then;
    end;
}
