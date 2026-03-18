namespace System.Integration.PowerBI;

/// <summary>
/// Records a history entry for each status transition of a Power BI deployment operation,
/// tracking when each status was reached and whether it failed (and why).
/// The current status of a deployment is derived from the latest record in this table.
/// </summary>
table 6317 "Power BI Deployment State"
{
    Caption = 'Power BI Deployment State';
    ReplicateData = false;
    Access = Internal;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Report Id"; Enum "Power BI Deployable Report")
        {
            Caption = 'Report Id';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// The upload status that had been reached when this record was created.
        /// Only forward-progress statuses are stored here:
        /// ImportStarted, ImportFinished, ParametersUpdated, DataRefreshed, Completed.
        /// Failed is never written here — failure is indicated by a non-zero "Failed At" timestamp.
        /// NotStarted means the upload had not progressed at all when failure occurred.
        /// The absence of any state record also implies NotStarted.
        /// </summary>
        field(3; "Status Reached"; Enum "Power BI Upload Status")
        {
            Caption = 'Status Reached';
            DataClassification = SystemMetadata;
        }
        field(4; "Reached At"; DateTime)
        {
            Caption = 'Reached At';
            DataClassification = SystemMetadata;
        }
        field(6; "Failed At"; DateTime)
        {
            Caption = 'Failed At';
            DataClassification = SystemMetadata;
        }
        field(7; "Failed Reason"; Blob)
        {
            Caption = 'Failed Reason';
            DataClassification = SystemMetadata;
        }
        field(8; "Failed Callstack"; Blob)
        {
            Caption = 'Failed Callstack';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key1; "Report Id", "Status Reached")
        {
        }
    }

    procedure SetFailedReason(FailedReason: Text)
    var
        OutStr: OutStream;
    begin
        Rec."Failed Reason".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(FailedReason);
    end;

    procedure GetFailedReason(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Rec.CalcFields("Failed Reason");
        if not Rec."Failed Reason".HasValue() then
            exit('');
        Rec."Failed Reason".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
        exit(Result);
    end;

    procedure SetFailedCallstack(FailedCallstack: Text)
    var
        OutStr: OutStream;
    begin
        Rec."Failed Callstack".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(FailedCallstack);
    end;

    procedure GetFailedCallstack(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Rec.CalcFields("Failed Callstack");
        if not Rec."Failed Callstack".HasValue() then
            exit('');
        Rec."Failed Callstack".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
        exit(Result);
    end;
}
