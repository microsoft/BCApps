#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 101902 "Code Sort"
#pragma warning restore AS0103, PTE0004
{
    Caption = 'Code Sort';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Name (Index)"; Text[100])
        {
            Caption = 'Name (Index)';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
        }
        key(Key2; "Name (Index)")
        {
        }
    }

    fieldgroups
    {
    }

    var
        SortMgt: Codeunit "Sorting Management";

    procedure InsertRecord(String: Text[250])
    begin
        Init();
        "No." := "No." + 1;
        Name := String;
        SortMgt.MakeSortKey(Name, "Name (Index)", MaxStrLen("Name (Index)"));
        Insert();
    end;
}

