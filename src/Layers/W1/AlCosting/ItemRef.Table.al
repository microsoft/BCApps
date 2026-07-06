table 103412 "Item Ref."
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataCaptionFields = "No.", Description;
    Permissions = TableData "Reservation Entry" = d;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "No. 2"; Code[20])
        {
        }
        field(3; Description; Text[30])
        {
        }
        field(4; "Search Description"; Code[30])
        {
        }
        field(5; "Description 2"; Text[30])
        {
        }
        field(6; "Assembly BOM"; Boolean)
        {
            Editable = false;
        }
        field(7; Class; Code[10])
        {
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(9; "Price Unit Conversion"; Integer)
        {
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            TableRelation = "Inventory Posting Group";
        }
        field(12; "Shelf/Bin No."; Code[10])
        {
        }
        field(13; "Sales Qty. Disc. Code"; Code[20])
        {
            TableRelation = Item;
            ValidateTableRelation = false;
        }
        field(14; "Item/Cust. Disc. Gr."; Code[20])
        {
            TableRelation = "Item Discount Group";
        }
        field(15; "Allow Invoice Disc."; Boolean)
        {
            InitValue = true;
        }
        field(16; "Statistics Group"; Integer)
        {
        }
        field(17; "Commission Group"; Integer)
        {
        }
        field(18; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            MinValue = 0;
        }
        field(19; "Price/Profit Calculation"; Option)
        {
            OptionMembers = "Profit=Price-Cost","Price=Cost+Profit","No Relationship";
        }
        field(20; "Profit %"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MaxValue = 99.99999;
            AutoFormatType = 0;
        }
        field(21; "Costing Method"; Option)
        {
            OptionMembers = FIFO,LIFO,Specific,"Average",Standard;
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
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
        field(26; "Average Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Enabled = false;
            MinValue = 0;
        }
        field(27; "Minimum Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            MinValue = 0;
        }
        field(28; "Indirect Cost %"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
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
        field(37; "Alternative Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(38; "Unit List Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            MinValue = 0;
        }
        field(39; "Duty Due %"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(40; "Duty Code"; Code[10])
        {
        }
        field(41; "Gross Weight"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(42; "Net Weight"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(43; "Units per Parcel"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(44; "Unit Volume"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(45; Durability; Code[10])
        {
        }
        field(46; "Freight Type"; Code[10])
        {
        }
        field(47; "Tariff No."; Code[20])
        {
            TableRelation = "Tariff Number";
        }
        field(48; "Duty Unit Conversion"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(49; "Country Purchased Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(50; "Budget Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(51; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(52; "Budget Profit"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(53; Comment; Boolean)
        {
            Editable = false;
        }
        field(54; Blocked; Boolean)
        {
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
            CaptionClass = '1,3,1';
        }
        field(66; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
        }
        field(67; "Location Filter"; Code[10])
        {
            FieldClass = FlowFilter;
            TableRelation = Location;
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
            Editable = false;
            AutoFormatType = 0;
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
        field(87; "Price Includes VAT"; Boolean)
        {
        }
        field(89; "Drop Shipment Filter"; Boolean)
        {
        }
        field(90; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            TableRelation = "VAT Business Posting Group";
        }
        field(91; "Gen. Prod. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Product Posting Group";
        }
        field(92; Picture; BLOB)
        {
            SubType = Bitmap;
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
        field(95; "Country of Origin Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(96; "Automatic Ext. Texts"; Boolean)
        {
        }
        field(97; "No. Series"; Code[20])
        {
            Editable = false;
            TableRelation = "No. Series";
        }
        field(98; "Tax Group Code"; Code[10])
        {
            TableRelation = "Tax Group";
        }
        field(99; "VAT Prod. Posting Group"; Code[20])
        {
            TableRelation = "VAT Product Posting Group";
        }
        field(100; Reserve; Option)
        {
            InitValue = Optional;
            OptionMembers = Never,Optional,Always;
        }
        field(101; "Reserved Qty. on Inventory"; Decimal)
        {
            DecimalPlaces = 0 : 5;
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
        field(104; "Add.-Curr. Average Cost"; Decimal)
        {
            AutoFormatType = 2;
            Enabled = false;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(105; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
        }
        field(106; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
        }
        field(5400; "Low-Level Code"; Integer)
        {
            Editable = false;
        }
        field(5401; "Lot Size"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5402; "Serial Nos."; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(5403; "Last Unit Cost Calc. Date"; Date)
        {
            Editable = false;
        }
        field(5404; "Material Cost per Unit"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5405; "Labor Cost per Unit"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(5406; "Indirect Cost per Unit"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            DecimalPlaces = 2 : 5;
        }
        field(5407; "Scrap %"; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 2;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5408; "Requisition Method Code"; Code[10])
        {
        }
        field(5409; "Inventory Value Zero"; Boolean)
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
        field(5413; "Safety Stock Quantity"; Decimal)
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
            OptionMembers = Purchase,"Prod. Order";
        }
        field(5420; "Scheduled Receipt (Qty.)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5421; "Scheduled Need (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5422; "Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(5423; "Bin Filter"; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(5424; "Variant Filter"; Code[10])
        {
            FieldClass = FlowFilter;
            TableRelation = "Item Variant".Code where("Item No." = field("No."));
        }
        field(5425; "Sales Unit of Measure"; Code[10])
        {
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5426; "Purch. Unit of Measure"; Code[10])
        {
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5428; "Reorder Cycle"; DateFormula)
        {
        }
        field(5429; "Reserved Qty. on Prod. Order"; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5430; "Res. Qty. on Prod. Order Comp."; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5700; "Stockkeeping Unit Exists"; Boolean)
        {
            Editable = false;
        }
        field(5701; "Manufacturer Code"; Code[10])
        {
            TableRelation = Manufacturer;
        }
        field(5702; "Item Category Code"; Code[20])
        {
            TableRelation = "Item Category".Code;
        }
        field(5703; "Created From Nonstock Item"; Boolean)
        {
            Editable = false;
        }
        field(5705; "Always Show Substitute"; Boolean)
        {
        }
        field(5706; "Substitutes Exist"; Boolean)
        {
            Editable = false;
        }
        field(5707; "Qty. in Transit"; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5708; "Trans. Ord. Receipt (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5709; "Trans. Ord. Shipment (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5770; "Qty. Available to pick"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5771; "Qty. Received not available"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5772; "Defective Quantity"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5773; "Reserved Inventory"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5774; "Qty. Assigned"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5775; "Qty. Assigned to pick"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5776; "Qty. Assigned to ship"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(5900; "Service Item Group"; Code[10])
        {
        }
        field(5901; "Qty. on Service Order"; Decimal)
        {
            Editable = false;
            AutoFormatType = 0;
        }
        field(6500; "Item Tracking Code"; Code[10])
        {
            TableRelation = "Item Tracking Code";
        }
        field(6501; "Lot Nos."; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(6502; "Expiration Calculation"; DateFormula)
        {
        }
        field(6503; "Lot No. Filter"; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(6504; "Serial No. Filter"; Code[20])
        {
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(6506; "Item Tracking Inventory"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(6509; "Item Tracking Expired Inv."; Decimal)
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
        field(99000750; "Routing No."; Code[20])
        {
            TableRelation = "Routing Header";
        }
        field(99000751; "Production BOM No."; Code[20])
        {
            TableRelation = "Production BOM Header";
        }
        field(99000752; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000753; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000754; "Single-Level Sub. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000755; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000756; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000757; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
        field(99000758; "Rolled Up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000759; "Rolled Up Mat. Overhead Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000760; "Rolled Up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 2;
            Editable = false;
            AutoFormatExpression = '';
        }
        field(99000761; "Planning Issues (Qty.)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000762; "Planning Receipt (Qty.)"; Decimal)
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
        field(99000768; "Planning Release (Qty.)"; Decimal)
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
        field(99000773; "Tracking Policy"; Option)
        {
            OptionMembers = "None","Tracking Only","Tracking & Action Msg.";
        }
        field(99000774; "Prod. Forecast Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(99000775; "Production Forecast Name"; Code[10])
        {
            FieldClass = FlowFilter;
            TableRelation = "Production Forecast Name";
        }
        field(99000776; "Component Forecast"; Boolean)
        {
        }
        field(99000777; "Qty. on Prod. Order"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(99000778; "Qty. on Component Lines"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
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

    local procedure GetAdditionalReportingCurrencyCode(): Text[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;
}
