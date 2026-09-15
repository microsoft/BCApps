table 103406 "Item Ledger Entry Ref."
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "Item Ledger Entries";
    LookupPageID = "Item Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
        field(2; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(3; "Posting Date"; Date)
        {
        }
        field(4; "Entry Type"; Option)
        {
            OptionMembers = Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        }
        field(5; "Source No."; Code[20])
        {
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(6; "Document No."; Code[20])
        {
        }
        field(7; Description; Text[50])
        {
        }
        field(8; "Location Code"; Code[10])
        {
            TableRelation = Location;
        }
        field(12; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(13; "Remaining Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(14; "Invoiced Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(28; "Applies-to Entry"; Integer)
        {
        }
        field(29; Open; Boolean)
        {
        }
        field(33; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(36; Positive; Boolean)
        {
        }
        field(41; "Source Type"; Option)
        {
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(47; "Drop Shipment"; Boolean)
        {
        }
        field(50; "Transaction Type"; Code[10])
        {
            TableRelation = "Transaction Type";
        }
        field(51; "Transport Method"; Code[10])
        {
            TableRelation = "Transport Method";
        }
        field(52; "Country Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            TableRelation = "Entry/Exit Point";
        }
        field(60; "Document Date"; Date)
        {
        }
        field(61; "External Document No."; Code[20])
        {
        }
        field(62; "Area"; Code[10])
        {
            TableRelation = Area;
        }
        field(63; "Transaction Specification"; Code[10])
        {
            TableRelation = "Transaction Specification";
        }
        field(64; "No. Series"; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(70; "Reserved Quantity"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Reservation Status" = const(Reservation),
                                                                           "Source Type" = const(32),
                                                                           "Source Subtype" = const("0"),
                                                                           "Source ID" = const(''),
                                                                           "Source Batch Name" = const(''),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Source Ref. No." = FIELD("Entry No.")));
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 0;
        }
        field(5401; "Prod. Order No."; Code[20])
        {
        }
        field(5402; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = FIELD("Item No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            TableRelation = Bin.Code where("Location Code" = FIELD("Location Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            TableRelation = "Item Unit of Measure".Code where("Item No." = FIELD("Item No."));
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
        }
        field(5700; "Cross-Reference No."; Code[20])
        {
        }
        field(5701; "Originally Ordered No."; Code[20])
        {
            TableRelation = Item;
        }
        field(5702; "Originally Ordered Var. Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = FIELD("Originally Ordered No."));
        }
        field(5703; "Out-of-Stock Substitution"; Boolean)
        {
        }
        field(5704; "Item Category Code"; Code[20])
        {
            TableRelation = "Item Category";
        }
        field(5705; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5706; "Purchasing Code"; Code[10])
        {
            TableRelation = Purchasing;
        }
        field(5740; "Transfer Order No."; Code[20])
        {
            Editable = false;
        }
        field(5800; "Completely Invoiced"; Boolean)
        {
        }
        field(5801; "Last Invoice Date"; Date)
        {
        }
        field(5802; "Applied Entry to Adjust"; Boolean)
        {
        }
        field(5803; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Cost Amount (Expected)" where("Item Ledger Entry No." = FIELD("Entry No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5804; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry No." = FIELD("Entry No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5805; "Cost Amount (Expected) (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            CalcFormula = sum("Value Entry"."Cost Amount (Expected) (ACY)" where("Item Ledger Entry No." = FIELD("Entry No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5806; "Cost Amount (Actual) (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            CalcFormula = sum("Value Entry"."Cost Amount (Actual) (ACY)" where("Item Ledger Entry No." = FIELD("Entry No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5816; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Item Ledger Entry No." = FIELD("Entry No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(5832; "Prod. Order Line No."; Integer)
        {
        }
        field(5833; "Prod. Order Comp. Line No."; Integer)
        {
        }
        field(5900; "Service Order No."; Code[20])
        {
        }
        field(6500; "Serial No."; Code[50])
        {
        }
        field(6501; "Lot No."; Code[50])
        {
        }
        field(6502; "Warranty Date"; Date)
        {
        }
        field(6503; "Expiration Date"; Date)
        {
        }
        field(6602; "Return Reason Code"; Code[10])
        {
            TableRelation = "Return Reason";
        }
        field(103001; "Use Case No."; Integer)
        {
        }
        field(103002; "Test Case No."; Integer)
        {
            TableRelation = "Test Case"."Test Case No." where("Use Case No." = FIELD("Use Case No."));
        }
        field(103003; "Iteration No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    [Scope('OnPrem')]
    procedure ShowReservationEntries(Modal: Boolean)
    begin
    end;
}
