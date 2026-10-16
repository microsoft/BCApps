namespace Microsoft.Samples.BCLESnapshotDebugging;

table 70951 "BCLE Profiling Setup"
{
    Caption = 'BCLE Profiling Demo Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Workload enabled';
            DataClassification = SystemMetadata;
        }
        field(3; "Interval (ms)"; Integer)
        {
            Caption = 'Interval (ms)';
            DataClassification = SystemMetadata;
            MinValue = 1000;
        }
        field(4; "Rows to Seed"; Integer)
        {
            Caption = 'Rows to seed';
            DataClassification = SystemMetadata;
            MinValue = 1;
            MaxValue = 100000;
        }
        field(5; "Maximum Runtime"; Duration)
        {
            Caption = 'Maximum runtime';
            DataClassification = SystemMetadata;
        }
        field(6; "Task ID"; Guid)
        {
            Caption = 'Task ID';
            DataClassification = SystemMetadata;
        }
        field(7; "Last Started At"; DateTime)
        {
            Caption = 'Last started at';
            DataClassification = SystemMetadata;
        }
        field(8; "Last Completed At"; DateTime)
        {
            Caption = 'Last completed at';
            DataClassification = SystemMetadata;
        }
        field(9; "Last Duration"; Duration)
        {
            Caption = 'Last duration';
            DataClassification = SystemMetadata;
        }
        field(10; "Run Count"; Integer)
        {
            Caption = 'Run count';
            DataClassification = SystemMetadata;
        }
        field(11; "Last Result"; BigInteger)
        {
            Caption = 'Last result';
            DataClassification = SystemMetadata;
        }
        field(12; "Last Error"; Text[250])
        {
            Caption = 'Last error';
            DataClassification = SystemMetadata;
        }
        field(13; "Active Session ID"; Integer)
        {
            Caption = 'Active NST session ID';
            DataClassification = SystemMetadata;
        }
        field(14; Phase; Text[100])
        {
            Caption = 'Current phase';
            DataClassification = SystemMetadata;
        }
        field(15; "Progress %"; Decimal)
        {
            Caption = 'Progress';
            DataClassification = SystemMetadata;
            ExtendedDatatype = Ratio;
            MinValue = 0;
            MaxValue = 100;
        }
        field(16; "Processed Rows"; Integer)
        {
            Caption = 'Processed rows';
            DataClassification = SystemMetadata;
        }
        field(17; "Total Rows"; Integer)
        {
            Caption = 'Total rows';
            DataClassification = SystemMetadata;
        }
        field(18; "Run Until"; DateTime)
        {
            Caption = 'Run until';
            DataClassification = SystemMetadata;
        }
        field(19; "Pass Task ID"; Guid)
        {
            Caption = 'Pass task ID';
            DataClassification = SystemMetadata;
        }
        field(20; "Workload Session ID"; Integer)
        {
            Caption = 'Workload NST session ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
