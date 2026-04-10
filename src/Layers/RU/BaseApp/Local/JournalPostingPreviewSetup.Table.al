#pragma warning disable AA0247
table 14929 "Journal Posting Preview Setup"
{
    Caption = 'Journal Posting Preview Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(3; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(4; "Enable Posting Preview"; Boolean)
        {
            Caption = 'Enable Posting Preview';
        }
        field(5; "Journal Type"; Option)
        {
            Caption = 'Journal Type';
            OptionCaption = 'General Journal,FA Journal';
            OptionMembers = "General Journal","FA Journal";
        }
    }

    keys
    {
        key(Key1; "User ID", "Journal Type", "Journal Template Name", "Journal Batch Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Initialize(UserID: Code[50])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        FAJnlBatch: Record "FA Journal Batch";
        JnlPostPreviewSetup: Record "Journal Posting Preview Setup";
    begin
        JnlPostPreviewSetup.Reset();
        JnlPostPreviewSetup.SetRange("User ID", UserID);
        if JnlPostPreviewSetup.FindSet(true, false) then
            repeat
                case JnlPostPreviewSetup."Journal Type" of
                    JnlPostPreviewSetup."Journal Type"::"General Journal":
                        if not GenJnlBatch.Get(JnlPostPreviewSetup."Journal Template Name", JnlPostPreviewSetup."Journal Batch Name") then
                            JnlPostPreviewSetup.Delete();
                    JnlPostPreviewSetup."Journal Type"::"FA Journal":
                        if not FAJnlBatch.Get(JnlPostPreviewSetup."Journal Template Name", JnlPostPreviewSetup."Journal Batch Name") then
                            JnlPostPreviewSetup.Delete();
                end;
            until JnlPostPreviewSetup.Next() = 0;

        GenJnlBatch.Reset();
        if GenJnlBatch.FindSet() then
            repeat
                JnlPostPreviewSetup.Init();
                JnlPostPreviewSetup."User ID" := UserID;
                JnlPostPreviewSetup."Journal Type" := "Journal Type"::"General Journal";
                JnlPostPreviewSetup."Journal Template Name" := GenJnlBatch."Journal Template Name";
                JnlPostPreviewSetup."Journal Batch Name" := GenJnlBatch.Name;
                if JnlPostPreviewSetup.Insert() then;
            until GenJnlBatch.Next() = 0;

        FAJnlBatch.Reset();
        if FAJnlBatch.FindSet() then
            repeat
                JnlPostPreviewSetup.Init();
                JnlPostPreviewSetup."User ID" := UserID;
                JnlPostPreviewSetup."Journal Type" := "Journal Type"::"FA Journal";
                JnlPostPreviewSetup."Journal Template Name" := FAJnlBatch."Journal Template Name";
                JnlPostPreviewSetup."Journal Batch Name" := FAJnlBatch.Name;
                if JnlPostPreviewSetup.Insert() then;
            until FAJnlBatch.Next() = 0;
    end;
}

