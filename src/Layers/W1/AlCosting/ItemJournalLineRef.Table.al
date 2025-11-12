table 103409 "Item Journal Line Ref."
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            TableRelation = "Item Journal Template";
        }
        field(2; "Line No."; Integer)
        {
        }
        field(3; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(4; "Posting Date"; Date)
        {
        }
        field(5; "Entry Type"; Option)
        {
            OptionMembers = Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer;
        }
        field(6; "Source No."; Code[20])
        {
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(7; "Document No."; Code[20])
        {
        }
        field(8; Description; Text[50])
        {
        }
        field(9; "Location Code"; Code[10])
        {
            TableRelation = Location;
        }
        field(10; "Inventory Posting Group"; Code[20])
        {
            Editable = false;
            TableRelation = "Inventory Posting Group";
        }
        field(11; "Source Posting Group"; Code[20])
        {
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Source Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Source Type" = const(Item)) "Inventory Posting Group";
        }
        field(13; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(16; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(17; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(18; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(22; "Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
            Editable = false;
        }
        field(23; "Salespers./Purch. Code"; Code[20])
        {
            TableRelation = "Salesperson/Purchaser";
        }
        field(26; "Source Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Source Code";
        }
        field(29; "Applies-to Entry"; Integer)
        {
        }
        field(32; "Item Shpt. Entry No."; Integer)
        {
            Editable = false;
        }
        field(34; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
        }
        field(35; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
        }
        field(37; "Indirect Cost %"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(39; "Source Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(41; "Journal Batch Name"; Code[10])
        {
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(42; "Reason Code"; Code[10])
        {
            TableRelation = "Reason Code";
        }
        field(43; "Recurring Method"; Option)
        {
            BlankZero = true;
            OptionMembers = ,"Fixed",Variable;
        }
        field(44; "Expiration Date"; Date)
        {
        }
        field(45; "Recurring Frequency"; DateFormula)
        {
        }
        field(46; "Drop Shipment"; Boolean)
        {
            Editable = false;
        }
        field(47; "Transaction Type"; Code[10])
        {
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            TableRelation = "Transport Method";
        }
        field(49; "Country Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(50; "New Location Code"; Code[10])
        {
            TableRelation = Location;
        }
        field(51; "New Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1,New ';
        }
        field(52; "New Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2,New ';
        }
        field(53; "Qty. (Calculated)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(54; "Qty. (Phys. Inventory)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Editable = false;
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Business Posting Group";
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Product Posting Group";
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            TableRelation = "Entry/Exit Point";
        }
        field(60; "Document Date"; Date)
        {
        }
        field(62; "External Document No."; Code[20])
        {
        }
        field(63; "Area"; Code[10])
        {
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            TableRelation = "Transaction Specification";
        }
        field(65; "Posting No. Series"; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(68; "Reserved Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(72; "Unit Cost (ACY)"; Decimal)
        {
            Editable = false;
            AutoFormatType = 2;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(73; "Source Currency Code"; Code[10])
        {
            Editable = false;
            TableRelation = Currency;
        }
        field(5401; "Prod. Order No."; Code[20])
        {
        }
        field(5402; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(5406; "New Bin Code"; Code[20])
        {
            TableRelation = Bin.Code where("Location Code" = field("New Location Code"));
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
            Editable = false;
        }
        field(5413; "Quantity (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5415; "Invoiced Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5468; "Reserved Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5700; "Cross-Reference No."; Code[20])
        {
        }
        field(5701; "Originally Ordered No."; Code[20])
        {
        }
        field(5702; "Originally Ordered Var. Code"; Code[10])
        {
        }
        field(5703; "Out-of-Stock Substitution"; Boolean)
        {
        }
        field(5704; "Item Category Code"; Code[20])
        {
        }
        field(5705; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5706; "Purchasing Code"; Code[10])
        {
        }
        field(5790; "Actual Delivery Date"; Date)
        {
        }
        field(5791; "Planned Delivery Date"; Date)
        {
        }
        field(5793; "Order Date"; Date)
        {
        }
        field(5800; "Value Entry Type"; Option)
        {
            OptionMembers = "Direct Cost","Add. Direct Cost",Revaluation,Rounding,"Indirect Cost",Variance;
        }
        field(5801; "Item Charge No."; Code[20])
        {
            TableRelation = "Item Charge";
        }
        field(5802; "Inventory Value (Calculated)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
            Editable = false;
        }
        field(5803; "Inventory Value (Revalued)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
            MinValue = 0;
        }
        field(5804; "Variance Type"; Enum "Cost Variance Type")
        {
        }
        field(5805; "Inventory Value Per"; Option)
        {
            Editable = false;
            OptionMembers = " ",Item,Location,Variant,"Location and Variant";
        }
        field(5806; "Partial Revaluation"; Boolean)
        {
        }
        field(5807; "Applies-from Entry"; Integer)
        {
            MinValue = 0;
        }
        field(5808; "Invoice No."; Code[20])
        {
        }
        field(5809; "Unit Cost (Calculated)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Source Currency Code";
            Editable = false;
        }
        field(5810; "Unit Cost (Revalued)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Source Currency Code";
            MinValue = 0;
        }
        field(5811; "Applied Amount"; Decimal)
        {
            Editable = false;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(5812; "Update Standard Cost"; Boolean)
        {
        }
        field(5813; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(5817; Correction; Boolean)
        {
        }
        field(5818; Adjustment; Boolean)
        {
        }
        field(5819; "Applies-to Value Entry"; Integer)
        {
        }
        field(5830; Type; Option)
        {
            OptionMembers = "Work Center","Machine Center"," ";
        }
        field(5831; "No."; Code[20])
        {
        }
        field(5838; "Operation No."; Code[10])
        {
        }
        field(5839; "Work Center No."; Code[20])
        {
            Editable = false;
            TableRelation = "Work Center";
        }
        field(5841; "Setup Time"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5842; "Run Time"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5843; "Stop Time"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5846; "Output Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5847; "Scrap Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5849; "Concurrent Capacity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5851; "Setup Time (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5852; "Run Time (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5853; "Stop Time (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5856; "Output Quantity (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5857; "Scrap Quantity (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5858; "Cap. Unit of Measure Code"; Code[10])
        {
            TableRelation = "Capacity Unit of Measure";
        }
        field(5859; "Qty. per Cap. Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5873; "Starting Time"; Time)
        {
        }
        field(5874; "Ending Time"; Time)
        {
        }
        field(5880; "Prod. Order Line No."; Integer)
        {
        }
        field(5882; "Routing No."; Code[20])
        {
            Editable = false;
        }
        field(5883; "Routing Reference No."; Integer)
        {
        }
        field(5884; "Prod. Order Comp. Line No."; Integer)
        {
            TableRelation = "Prod. Order Component"."Line No." where(Status = const(Released),
                                                                      "Prod. Order No." = field("Prod. Order No."),
                                                                      "Prod. Order Line No." = field("Prod. Order Line No."));
        }
        field(5885; Finished; Boolean)
        {
        }
        field(5887; "Unit Cost Calculation"; Option)
        {
            OptionMembers = Time,Units;
        }
        field(5888; Subcontracting; Boolean)
        {
        }
        field(5895; "Stop Code"; Code[10])
        {
            TableRelation = Stop;
        }
        field(5896; "Scrap Code"; Code[10])
        {
            TableRelation = Scrap;
        }
        field(5898; "Work Center Group Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Work Center Group";
        }
        field(5899; "Work Shift Code"; Code[10])
        {
            TableRelation = "Work Shift";
        }
        field(5900; "Service Order No."; Code[20])
        {
            Editable = false;
        }
        field(6500; "Serial No."; Code[50])
        {
            Editable = false;
        }
        field(6501; "Lot No."; Code[50])
        {
            Editable = false;
        }
        field(6502; "Warranty Date"; Date)
        {
            Editable = false;
        }
        field(6503; "New Serial No."; Code[50])
        {
            Editable = false;
        }
        field(6504; "New Lot No."; Code[50])
        {
            Editable = false;
        }
        field(6600; "Return Reason Code"; Code[10])
        {
            TableRelation = "Return Reason";
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Item,SKU;
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
        field(99000755; "Overhead Rate"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(99000756; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000757; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000758; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000759; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000760; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000761; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000762; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000763; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000764; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000765; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Source Currency Code";
        }
    }

    keys
    {
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Journal Template Name", "Journal Batch Name", "Line No.")
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
