namespace System.Environment.Configuration;

table 9179 "Application Area Buffer"
{
    Caption = 'Application Area Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Application Area"; Text[80])
        {
            Caption = 'Application Area';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; Selected; Boolean)
        {
            Caption = 'Selected';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
    begin
        case true of
            (not Selected) and ("Field No." = ApplicationAreaSetup.FieldNo(Basic)):
                ModifyAll(Selected, false);
            Selected and ("Field No." <> ApplicationAreaSetup.FieldNo(Basic)):
                begin
                    TempApplicationAreaBuffer.Copy(Rec, true);
                    TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Basic));
                    TempApplicationAreaBuffer.Selected := true;
                    TempApplicationAreaBuffer.Modify();
                end;
        end;
    end;
}

