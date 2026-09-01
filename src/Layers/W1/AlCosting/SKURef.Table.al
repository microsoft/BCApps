table 103413 "SKU Ref."
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Location Code"; Code[10])
        {
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(4; Description; Text[30])
        {
            Editable = false;
        }
        field(5; "Description 2"; Text[30])
        {
            Editable = false;
        }
        field(6; "Assembly BOM"; Boolean)
        {
            Editable = false;
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            TableRelation = "Inventory Posting Group";
        }
        field(12; "Shelf/Bin No."; Code[10])
        {
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Editable = false;
            MinValue = 0;
        }
        field(24; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            MinValue = 0;
        }
        field(25; "Last Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            MinValue = 0;
        }
        field(31; "Vendor No."; Code[20])
        {
            TableRelation = Vendor;
            ValidateTableRelation = false;
        }
        field(32; "Vendor Item No."; Text[20])
        {
        }
        field(33; "Lead Time Calculation"; DateFormula)
        {
        }
        field(34; "Reorder Point"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(35; "Maximum Inventory"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(36; "Reorder Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(53; Comment; Boolean)
        {
            Editable = false;
        }
        field(62; "Last Date Modified"; Date)
        {
            Editable = false;
        }
        field(64; "Date Filter"; Date)
        {
        }
        field(65; "Global Dimension 1 Filter"; Code[20])
        {
        }
        field(66; "Global Dimension 2 Filter"; Code[20])
        {
        }
        field(68; Inventory; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(69; "Net Invoiced Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(70; "Net Change"; Decimal)
        {
            AutoFormatType = 0;
            Editable = false;
        }
        field(71; "Purchases (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(72; "Sales (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(73; "Positive Adjmt. (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(74; "Negative Adjmt. (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(77; "Purchases (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(78; "Sales (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(79; "Positive Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(80; "Negative Adjmt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(83; "COGS (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(84; "Qty. on Purch. Order"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(85; "Qty. on Sales Order"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(89; "Drop Shipment Filter"; Boolean)
        {
        }
        field(93; "Transferred (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(94; "Transferred (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(100; Reserve; Option)
        {
            InitValue = Optional;
            OptionMembers = Never,Optional,Always;
        }
        field(101; "Reserved Qty. on Inventory"; Decimal)
        {
            Editable = false;
            AutoFormatType = 0;
        }
        field(102; "Reserved Qty. on Purch. Orders"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(103; "Reserved Qty. on Sales Orders"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5401; "Lot Size"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5407; "Scrap %"; Decimal)
        {
            DecimalPlaces = 0 : 2;
            MaxValue = 100;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5408; "Requisition Method Code"; Code[10])
        {
        }
        field(5410; "Discrete Order Quantity"; Integer)
        {
            MinValue = 0;
        }
        field(5411; "Minimum Order Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5412; "Maximum Order Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5413; "Inventory Buffer Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5414; "Order Multiple"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5415; "Safety Lead Time"; DateFormula)
        {
        }
        field(5417; "Flushing Method"; Option)
        {
            OptionMembers = Manual,Forward,Backward;
        }
        field(5419; "Requisition System"; Option)
        {
            OptionMembers = Purchase,"Prod. Order",Transfer;
        }
        field(5420; "Scheduled Receipt (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5421; "Scheduled Need (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5422; "Rounding Precision"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(5423; "Bin Filter"; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5428; "Reorder Cycle"; DateFormula)
        {
        }
        field(5429; "Reserved Qty. on Prod. Order"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5430; "Res. Qty. on Prod. Order Comp."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5700; "Transfer-from Code"; Code[10])
        {
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(5701; "Qty. in Transit"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5702; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5703; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(103001; "Use Case No."; Integer)
        {
        }
        field(103002; "Test Case No."; Integer)
        {
            TableRelation = "Test Case"."Test Case No." where("Use Case No." = field("Use Case No."));
        }
        field(103003; "Iteration No."; Integer)
        {
        }
        field(103004; "Average Cost (LCY)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(103005; "Average Cost (ACY)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(99000761; "MRP Issues (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000762; "MRP Receipt (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000763; "Reserved MRP Issues (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000764; "Reserved MRP Receipt (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000765; "Planned Order Receipt (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(99000766; "FP Order Receipt (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(99000767; "Rel. Order Receipt (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(99000768; "MRP Release (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000769; "Planned Order Release (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(99000770; "Purch. Req. Receipt (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000771; "Purch. Req. Release (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000772; "Reserved Qty. on Req. Line"; Decimal)
        {
            AutoFormatType = 0;
        }
    }

    keys
    {
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Location Code", "Item No.", "Variant Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;
}
