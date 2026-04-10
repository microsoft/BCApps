namespace System.Threading;

table 479 "Job Queue Entry Buffer"
{
    Caption = 'Job Queue Entry Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(7; "Object Type to Run"; Option)
        {
            Caption = 'Object Type to Run';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit';
            OptionMembers = ,,,"Report",,"Codeunit";
            DataClassification = SystemMetadata;
        }
        field(8; "Object ID to Run"; Integer)
        {
            Caption = 'Object ID to Run';
            DataClassification = SystemMetadata;
        }
        field(30; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(33; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            DataClassification = SystemMetadata;
        }
        field(34; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(8001; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            DataClassification = SystemMetadata;
        }
        field(8010; "Start Date/Time"; DateTime)
        {
            Caption = 'Start Date/Time';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Job Queue Entry ID")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.GetBySystemId(Rec."Job Queue Entry ID") then
            if JobQueueEntry.Status = JobQueueEntry.Status::Error then
                JobQueueEntry.Delete();
    end;
}