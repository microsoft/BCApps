namespace System.Threading;

table 9066 "Job Queue Notification Setup"
{
    Caption = 'Job Queue Notification Setup';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(2; NotifyUserInitiatingTask; Boolean)
        {
            InitValue = true;
        }
        field(3; NotifyJobQueueAdmin; Boolean)
        {
            InitValue = true;
        }
        field(4; InProductNotification; Boolean)
        {
            InitValue = true;
        }
        field(5; PowerAutomateFlowNotification; Boolean)
        {
            InitValue = false;
        }
        field(6; NotifyWhenJobFailed; Boolean)
        {
            InitValue = true;
        }
        field(7; NotifyAfterThreshold; Boolean)
        {
            InitValue = false;
        }
        field(8; Threshold1; Decimal)
        {
            InitValue = 3;
        }
        field(9; Threshold2; Decimal)
        {
            InitValue = 5;
        }

    }

    trigger OnInsert()
    begin
        if Rec.Count > 1 then
            Error(OnlyOneRecordAllowedErr);
    end;

    var
        OnlyOneRecordAllowedErr: Label 'Only one record is allowed in Job Queue Notification Setup table.';
}

