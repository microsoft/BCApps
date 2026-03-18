table 103334 "BW Warehouse Request Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Type"; Integer)
        {
            Editable = false;
        }
        field(2; "Source Subtype"; Option)
        {
            Editable = false;
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(3; "Source No."; Code[20])
        {
            Editable = false;
#pragma warning disable AL0603
            TableRelation = if ("Source Type" = const(37)) "Sales Header"."No." where("Document Type" = FIELD("Source Subtype"))
            else
            if ("Source Type" = const(39)) "Purchase Header"."No." where("Document Type" = FIELD("Source Subtype"))
            else
            if ("Source Type" = const(5741)) "Transfer Header"."No.";
#pragma warning restore AL0603
        }
        field(4; "Source Document"; Option)
        {
            Editable = false;
            OptionMembers = ,"Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer";
        }
        field(5; "Document Status"; Option)
        {
            Editable = false;
            OptionMembers = Open,Released;
        }
        field(6; "Location Code"; Code[10])
        {
            Editable = false;
            TableRelation = Location;
        }
        field(7; "Shipment Method Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Shipment Method";
        }
        field(8; "Shipping Agent Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Shipping Agent";
        }
        field(10; "Shipping Advice"; Option)
        {
            Editable = false;
            OptionMembers = Partial,Complete;
        }
        field(19; Type; Option)
        {
            Editable = false;
            OptionMembers = Inbound,Outbound;
        }
        field(41; "Completely Handled"; Boolean)
        {
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
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", Type, "Location Code", "Source Type", "Source Subtype", "Source No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

