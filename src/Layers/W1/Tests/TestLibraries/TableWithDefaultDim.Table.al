table 134482 "Table With Default Dim"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(29; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        // to test that modification of global dim codes does not run OnModify trigger
        Error(OnModifyErr);
    end;

    trigger OnRename()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.RenameDefaultDim(DATABASE::"Table With Default Dim", xRec."No.", "No.");
    end;

    var
        OnModifyErr: Label 'TAB134482.OnModify should not be called.';
}

