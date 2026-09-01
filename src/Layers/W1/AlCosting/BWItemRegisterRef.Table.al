table 103342 "BW Item Register Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    LookupPageID = "Item Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
        }
        field(2; "From Entry No."; Integer)
        {
            TableRelation = "Item Ledger Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            TableRelation = "Item Ledger Entry";
        }
        field(4; "Creation Date"; Date)
        {
        }
        field(5; "Source Code"; Code[10])
        {
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[20])
        {
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            TableRelation = "Item Journal Batch".Name;
        }
        field(10; "From Phys. Inventory Entry No."; Integer)
        {
            TableRelation = "Phys. Inventory Ledger Entry";
        }
        field(11; "To Phys. Inventory Entry No."; Integer)
        {
            TableRelation = "Phys. Inventory Ledger Entry";
        }
        field(5800; "From Value Entry No."; Integer)
        {
            TableRelation = "Value Entry";
        }
        field(5801; "To Value Entry No."; Integer)
        {
            TableRelation = "Value Entry";
        }
        field(5831; "From Capacity Entry No."; Integer)
        {
            TableRelation = "Capacity Ledger Entry";
        }
        field(5832; "To Capacity Entry No."; Integer)
        {
            TableRelation = "Capacity Ledger Entry";
        }
        field(103231; "Use Case No."; Integer)
        {
        }
        field(103232; "Test Case No."; Integer)
        {
        }
        field(103233; "Iteration No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

