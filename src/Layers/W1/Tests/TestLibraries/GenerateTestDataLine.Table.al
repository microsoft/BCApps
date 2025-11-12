table 130150 "Generate Test Data Line"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
        }
        field(2; "Table Name"; Text[30])
        {
        }
        field(3; "Total Records"; Integer)
        {
        }
        field(4; "Added Records"; Integer)
        {

            trigger OnValidate()
            begin
                CalcProgress();
            end;
        }
        field(5; Progress; Decimal)
        {
            ExtendedDatatype = Ratio;
            AutoFormatType = 0;
        }
        field(6; Status; Option)
        {
            OptionMembers = " ",Scheduled,"In Progress",Completed,Incomplete;
        }
        field(7; "Task ID"; Guid)
        {
        }
        field(8; "Session ID"; Integer)
        {
        }
        field(9; "Records To Add"; Integer)
        {
        }
        field(10; "Parent Table ID"; Integer)
        {
        }
        field(11; "Last Error Message"; Text[250])
        {
        }
        field(12; Enabled; Boolean)
        {
        }
        field(13; "Service Instance ID"; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FillData();
    end;

    local procedure CalcProgress()
    begin
        Progress := 10000;
        if ("Records To Add" <> 0) and ("Added Records" <= "Records To Add") then
            Progress := "Added Records" / "Records To Add" * 10000;
    end;

    local procedure FillData()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open("Table ID");
        "Table Name" := RecRef.Name;
        "Total Records" := RecRef.Count();
        RecRef.Close();
    end;

    [Scope('OnPrem')]
    procedure ScheduleJobForTable(StartNotBefore: DateTime)
    begin
        if "Records To Add" = 0 then
            exit;

        "Task ID" :=
          TASKSCHEDULER.CreateTask(
            CODEUNIT::"Generate Test Data Mgt.", CODEUNIT::"Test Data Error Handler",
            true, CompanyName, StartNotBefore, RecordId);

        if IsNullGuid("Task ID") then
            Status := Status::" "
        else
            Status := Status::Scheduled;
        Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateStatus()
    var
        ActiveSession: Record "Active Session";
    begin
        if IsNullGuid("Task ID") then
            Status := Status::" "
        else
            if ("Added Records" = "Records To Add") and ("Records To Add" <> 0) then
                Status := Status::Completed
            else
                if "Session ID" = 0 then
                    Status := Status::Scheduled
                else
                    if ActiveSession.Get("Service Instance ID", "Session ID") then
                        Status := Status::"In Progress"
                    else
                        Status := Status::Incomplete;
    end;
}
