namespace Microsoft.Samples.BCLESnapshotDebugging;

codeunit 70950 "BCLE Heavy SQL Workload"
{
    procedure Run(RowCount: Integer; var Setup: Record "BCLE Profiling Setup"): BigInteger
    var
        Result: BigInteger;
    begin
        EnsureSeeded(RowCount, Setup);

        UpdateProgress(Setup, 'Executing SQL self-join 1 of 2', 35, 0);
        Result := ExecuteHeavySqlJoin();

        UpdateProgress(Setup, 'Executing SQL self-join 2 of 2', 60, 0);
        Result += ExecuteHeavySqlJoin();

        UpdateProgress(Setup, 'Loading BLOBs row by row', 80, 0);
        Result += ScanPayloadsByUnindexedCategory(RowCount, Setup);

        UpdateProgress(Setup, 'Finalizing workload pass', 98, RowCount);
        exit(Result);
    end;

    procedure Seed(RowCount: Integer; var Setup: Record "BCLE Profiling Setup")
    var
        Buffer: Record "BCLE Profiling Buffer";
        Chunk: Text;
        EntryNo: Integer;
        OutStream: OutStream;
    begin
        Buffer.DeleteAll();
        Chunk := BuildPayloadChunk();
        Setup."Total Rows" := RowCount;

        for EntryNo := 1 to RowCount do begin
            Buffer.Init();
            Buffer."Entry No." := EntryNo;
            Buffer."Category Code" := WorkloadCategory();
            Buffer.Bucket := EntryNo mod 16;
            Buffer.Payload.CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(Chunk);
            Buffer."Payload Size" := StrLen(Chunk);
            Buffer.Insert();

            if (EntryNo mod 100) = 0 then
                UpdateProgress(Setup, 'Seeding SQL workload data', Round(EntryNo / RowCount * 30, 1), EntryNo);
        end;

        UpdateProgress(Setup, 'SQL workload data ready', 30, RowCount);
    end;

    local procedure EnsureSeeded(RowCount: Integer; var Setup: Record "BCLE Profiling Setup")
    var
        Buffer: Record "BCLE Profiling Buffer";
    begin
        if Buffer.Count() = RowCount then begin
            UpdateProgress(Setup, 'Existing SQL workload data ready', 30, RowCount);
            exit;
        end;

        Seed(RowCount, Setup);
    end;

    local procedure ExecuteHeavySqlJoin(): BigInteger
    var
        HeavySqlJoin: Query "BCLE Heavy SQL Join";
        Result: BigInteger;
    begin
        HeavySqlJoin.Open();
        while HeavySqlJoin.Read() do
            Result += HeavySqlJoin.JoinedRows;
        HeavySqlJoin.Close();
        exit(Result);
    end;

    local procedure ScanPayloadsByUnindexedCategory(RowCount: Integer; var Setup: Record "BCLE Profiling Setup"): BigInteger
    var
        Buffer: Record "BCLE Profiling Buffer";
        ProcessedRows: Integer;
        Result: BigInteger;
    begin
        Buffer.SetRange("Category Code", WorkloadCategory());
        if Buffer.FindSet() then
            repeat
                Buffer.CalcFields(Payload);
                Result += ProcessBlobPayload(Buffer);
                ProcessedRows += 1;
                if (ProcessedRows mod 250) = 0 then
                    UpdateProgress(Setup, 'Loading BLOBs row by row', 80 + Round(ProcessedRows / RowCount * 15, 1), ProcessedRows);
            until Buffer.Next() = 0;

        exit(Result);
    end;

    local procedure ProcessBlobPayload(var Buffer: Record "BCLE Profiling Buffer"): BigInteger
    var
        InStream: InStream;
        Line: Text;
        Rolling: BigInteger;
    begin
        Buffer.Payload.CreateInStream(InStream, TextEncoding::UTF8);
        Rolling := 1;
        while not InStream.EOS() do begin
            InStream.ReadText(Line);
            Rolling := ((Rolling * 1000003) + StrLen(Line)) mod 1000000007;
        end;

        exit(Rolling);
    end;

    local procedure BuildPayloadChunk(): Text
    var
        Builder: TextBuilder;
        Index: Integer;
    begin
        for Index := 1 to 32 do
            Builder.Append('BCLE-SAMPLING-PROFILER-SQL-PAYLOAD-0123456789ABCDEF-');

        exit(Builder.ToText());
    end;

    local procedure UpdateProgress(var Setup: Record "BCLE Profiling Setup"; Phase: Text[100]; Progress: Decimal; ProcessedRows: Integer)
    begin
        Setup.Get(Setup."Primary Key");
        Setup.Phase := Phase;
        Setup."Progress %" := Progress;
        Setup."Processed Rows" := ProcessedRows;
        Setup.Modify();
        Commit();
    end;

    local procedure WorkloadCategory(): Code[20]
    begin
        exit('BCLE-SLOW-SQL');
    end;
}
