namespace System.Integration;

table 1799 "Data Migration Status"
{
    Caption = 'Data Migration Status';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Migration Type"; Text[250])
        {
            Caption = 'Migration Type';
        }
        field(2; "Destination Table ID"; Integer)
        {
            Caption = 'Destination Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Total Number"; Integer)
        {
            Caption = 'Total Number';
        }
        field(4; "Migrated Number"; Integer)
        {
            Caption = 'Migrated Number';
        }
        field(5; "Progress Percent"; Decimal)
        {
            Caption = 'Progress Percent';
            DataClassification = SystemMetadata;
            ExtendedDatatype = Ratio;
        }
        field(6; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Pending,In Progress,Completed,Completed with Errors,Stopped,Failed';
            OptionMembers = Pending,"In Progress",Completed,"Completed with Errors",Stopped,Failed;
        }
        field(7; "Source Staging Table ID"; Integer)
        {
            Caption = 'Source Staging Table ID';
            DataClassification = SystemMetadata;
        }
        field(8; "Migration Codeunit To Run"; Integer)
        {
            Caption = 'Migration Codeunit To Run';
            DataClassification = SystemMetadata;
        }
        field(9; "Error Count"; Integer)
        {
            CalcFormula = count("Data Migration Error" where("Migration Type" = field("Migration Type"),
                                                              "Destination Table ID" = field("Destination Table ID")));
            Caption = 'Error Count';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Migration Type", "Destination Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    var
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Total Number" <> 0) and ("Migrated Number" <= "Total Number") then
            "Progress Percent" := "Migrated Number" / "Total Number" * 10000; // 10000 = 100%

        if Status in [Status::Completed,
                      Status::Failed,
                      Status::Stopped]
        then
            DataMigrationMgt.CheckIfMigrationIsCompleted(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var DataMigrationStatus: Record "Data Migration Status"; var IsHandled: Boolean)
    begin
    end;
}

