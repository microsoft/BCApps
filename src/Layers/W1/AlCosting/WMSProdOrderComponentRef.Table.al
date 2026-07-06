table 103321 "WMS Prod. Order Component Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Prod. Order Component Ref';
    DataCaptionFields = Status, "Prod. Order No.";
    DrillDownPageID = "Prod. Order Comp. Line List";
    LookupPageID = "Prod. Order Comp. Line List";
    PasteIsValid = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Option)
        {
            OptionMembers = Simulated,Planned,"Firm Planned",Released,Finished;
        }
        field(2; "Prod. Order No."; Code[20])
        {
#pragma warning disable AL0603
            TableRelation = "Production Order"."No." where(Status = field(Status));
#pragma warning restore AL0603
        }
        field(3; "Prod. Order Line No."; Integer)
        {
#pragma warning disable AL0603
            TableRelation = "Prod. Order Line"."Line No." where(Status = field(Status),
                                                                 "Prod. Order No." = field("Prod. Order No."));
#pragma warning restore AL0603
        }
        field(4; "Line No."; Integer)
        {
        }
        field(11; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(12; Description; Text[30])
        {
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(14; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(19; "Routing Link Code"; Code[10])
        {
            TableRelation = "Routing Link";
        }
        field(21; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(25; "Expected Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(26; "Remaining Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(27; "Act. Consumption (Qty)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(28; "Flushing Method"; Option)
        {
            OptionMembers = Manual,Forward,Backward,"Pick + Forward","Pick + Backward";
        }
        field(30; "Location Code"; Code[10])
        {
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(33; "Bin Code"; Code[20])
        {
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(35; "Supplied-by Line No."; Integer)
        {
#pragma warning disable AL0603
            TableRelation = "Prod. Order Line" where(Status = field(Status),
                                                      "Prod. Order No." = field("Prod. Order No."),
                                                      "Line No." = field("Supplied-by Line No."));
#pragma warning restore AL0603
        }
        field(36; "Planning Level Code"; Integer)
        {
            Editable = false;
        }
        field(52; "Due Date"; Date)
        {
        }
        field(61; "Remaining Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(62; "Quantity (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(63; "Reserved Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(71; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry".Quantity where("Reservation Status" = const(Reservation),
                                                                       "Source Type" = const(5407),
                                                                       "Source Subtype" = field(Status),
                                                                       "Source ID" = field("Prod. Order No."),
                                                                       "Source Batch Name" = const(''),
                                                                       "Source Prod. Order Line" = field("Prod. Order Line No."),
                                                                       "Source Ref. No." = field("Line No.")));
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(73; "Expected Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5750; "Pick Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(7300; "Qty. Picked"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(7301; "Qty. Picked (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(7303; "Pick Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(103200; "Project Code"; Code[10])
        {
        }
        field(103201; "Use Case No."; Integer)
        {
        }
        field(103202; "Test Case No."; Integer)
        {
        }
        field(103204; "Iteration No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Project Code", "Use Case No.", "Test Case No.", Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
