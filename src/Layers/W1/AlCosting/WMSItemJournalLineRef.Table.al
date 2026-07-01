table 103315 "WMS Item Journal Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Item Journal Line Ref';
    DrillDownPageID = "Item Journal Lines";
    LookupPageID = "Item Journal Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Purchase,Sale,Positive Adjmt.,Negative Adjmt.,Transfer,Consumption,Output';
            OptionMembers = Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(10; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            Editable = false;
            TableRelation = "Inventory Posting Group";
        }
        field(11; "Source Posting Group"; Code[20])
        {
            Caption = 'Source Posting Group';
            Editable = false;
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(16; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Amount';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(17; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(18; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(22; "Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Discount Amount';
            Editable = false;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(23; "Salespers./Purch. Code"; Code[10])
        {
            Caption = 'Salespers./Purch. Code';
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(29; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';
        }
        field(32; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            Editable = false;
        }
        field(34; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(35; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(37; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(39; "Source Type"; Option)
        {
            Caption = 'Source Type';
            Editable = false;
            OptionCaption = ' ,Customer,Vendor,Item';
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(41; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(43; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(44; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(45; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(46; "Drop Shipment"; Boolean)
        {
            Caption = 'Drop Shipment';
            Editable = false;
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(49; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
            TableRelation = "Country/Region";
        }
        field(50; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code';
            TableRelation = Location;
        }
        field(51; "New Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1,';
            Caption = 'New Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(52; "New Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2,';
            Caption = 'New Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(53; "Qty. (Calculated)"; Decimal)
        {
            Caption = 'Qty. (Calculated)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(54; "Qty. (Phys. Inventory)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Caption = 'Phys. Inventory';
            Editable = false;
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(62; "External Document No."; Code[20])
        {
            Caption = 'External Document No.';
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(65; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(68; "Reserved Quantity"; Decimal)
        {
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(72; "Unit Cost (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unit Cost (ACY)';
            Editable = false;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(73; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(5401; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(5403; "Bin Code"; Code[20])
        {
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
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
            Caption = 'Unit of Measure Code';
        }
        field(5408; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
            Editable = false;
        }
        field(5413; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5415; "Invoiced Qty. (Base)"; Decimal)
        {
            Caption = 'Invoiced Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5468; "Reserved Qty. (Base)"; Decimal)
        {
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(5700; "Cross-Reference No."; Code[20])
        {
            Caption = 'Cross-Reference No.';
        }
        field(5701; "Originally Ordered No."; Code[20])
        {
            Caption = 'Originally Ordered No.';
        }
        field(5702; "Originally Ordered Var. Code"; Code[10])
        {
            Caption = 'Originally Ordered Var. Code';
        }
        field(5703; "Out-of-Stock Substitution"; Boolean)
        {
            Caption = 'Out-of-Stock Substitution';
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5705; Nonstock; Boolean)
        {
            Caption = 'Catalog';
        }
        field(5706; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5740; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            Editable = false;
        }
        field(5791; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
        }
        field(5793; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(5800; "Value Entry Type"; Option)
        {
            Caption = 'Value Entry Type';
            OptionCaption = 'Direct Cost,Revaluation,Rounding,Indirect Cost,Variance';
            OptionMembers = "Direct Cost",Revaluation,Rounding,"Indirect Cost",Variance;
        }
        field(5801; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            TableRelation = "Item Charge";
        }
        field(5802; "Inventory Value (Calculated)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Calculated)';
            Editable = false;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(5803; "Inventory Value (Revalued)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inventory Value (Revalued)';
            MinValue = 0;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(5804; "Variance Type"; Option)
        {
            Caption = 'Variance Type';
            OptionCaption = ' ,Purchase,Material,Capacity,Capacity Overhead,Manufacturing Overhead';
            OptionMembers = " ",Purchase,Material,Capacity,"Capacity Overhead","Manufacturing Overhead";
        }
        field(5805; "Inventory Value Per"; Option)
        {
            Caption = 'Inventory Value Per';
            Editable = false;
            OptionCaption = ' ,Item,Location,Variant,Location and Variant';
            OptionMembers = " ",Item,Location,Variant,"Location and Variant";
        }
        field(5806; "Partial Revaluation"; Boolean)
        {
            Caption = 'Partial Revaluation';
            Editable = false;
        }
        field(5807; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            MinValue = 0;
        }
        field(5808; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
        }
        field(5809; "Unit Cost (Calculated)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Calculated)';
            Editable = false;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(5810; "Unit Cost (Revalued)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (Revalued)';
            MinValue = 0;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(5811; "Applied Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            Editable = false;
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(5812; "Update Standard Cost"; Boolean)
        {
            Caption = 'Update Standard Cost';
        }
        field(5813; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
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
            Caption = 'Type';
            OptionCaption = 'Work Center,Machine Center, ';
            OptionMembers = "Work Center","Machine Center"," ";
        }
        field(5831; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5838; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
        }
        field(5839; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            Editable = false;
        }
        field(5841; "Setup Time"; Decimal)
        {
            Caption = 'Setup Time';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5842; "Run Time"; Decimal)
        {
            Caption = 'Run Time';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5843; "Stop Time"; Decimal)
        {
            Caption = 'Stop Time';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5846; "Output Quantity"; Decimal)
        {
            Caption = 'Output Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5847; "Scrap Quantity"; Decimal)
        {
            Caption = 'Scrap Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5849; "Concurrent Capacity"; Decimal)
        {
            Caption = 'Concurrent Capacity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5851; "Setup Time (Base)"; Decimal)
        {
            Caption = 'Setup Time (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5852; "Run Time (Base)"; Decimal)
        {
            Caption = 'Run Time (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5853; "Stop Time (Base)"; Decimal)
        {
            Caption = 'Stop Time (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5856; "Output Quantity (Base)"; Decimal)
        {
            Caption = 'Output Quantity (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5857; "Scrap Quantity (Base)"; Decimal)
        {
            Caption = 'Scrap Quantity (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5858; "Cap. Unit of Measure Code"; Code[10])
        {
            Caption = 'Cap. Unit of Measure Code';
        }
        field(5859; "Qty. per Cap. Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Cap. Unit of Measure';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5873; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
        }
        field(5874; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
        }
        field(5880; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
        }
        field(5882; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            Editable = false;
        }
        field(5883; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
        field(5884; "Prod. Order Comp. Line No."; Integer)
        {
            Caption = 'Prod. Order Comp. Line No.';
        }
        field(5885; Finished; Boolean)
        {
            Caption = 'Finished';
        }
        field(5887; "Unit Cost Calculation"; Option)
        {
            Caption = 'Unit Cost Calculation';
            OptionCaption = 'Time,Units';
            OptionMembers = Time,Units;
        }
        field(5888; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
        }
        field(5895; "Stop Code"; Code[10])
        {
            Caption = 'Stop Code';
        }
        field(5896; "Scrap Code"; Code[10])
        {
            Caption = 'Scrap Code';
        }
        field(5898; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            Editable = false;
        }
        field(5899; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
        }
        field(5900; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            Editable = false;
        }
        field(6500; "Serial No."; Code[50])
        {
        }
        field(6501; "Lot No."; Code[50])
        {
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
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
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
        field(99000755; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(99000756; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Material Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000757; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Capacity Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000758; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Subcontrd. Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000759; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Cap. Ovhd Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000760; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000761; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Material Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000762; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Capacity Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000763; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Subcontracted Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000764; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
        field(99000765; "Rolled-up Cap. Overhead Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rolled-up Cap. Overhead Cost';
            AutoFormatExpression = Rec."Source Currency Code";
        }
    }

    keys
    {
        key(Key1; "Project Code", "Use Case No.", "Test Case No.", "Iteration No.", "Journal Template Name", "Journal Batch Name", "Line No.")
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