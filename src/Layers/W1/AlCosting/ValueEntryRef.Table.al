table 103407 "Value Entry Ref."
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "Value Entries";
    LookupPageID = "Value Entries";
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
        field(4; "Item Ledger Entry Type"; Option)
        {
            OptionMembers = Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ";
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
        field(9; "Inventory Posting Group"; Code[20])
        {
            TableRelation = "Inventory Posting Group";
        }
        field(10; "Source Posting Group"; Code[20])
        {
            TableRelation = if ("Source Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Source Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Source Type" = const(Item)) "Inventory Posting Group";
        }
        field(11; "Item Ledger Entry No."; Integer)
        {
            TableRelation = "Item Ledger Entry";
        }
        field(12; "Valued Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(13; "Item Ledger Entry Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(14; "Invoiced Quantity"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(15; "Cost per Unit"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
        field(17; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(22; "Salespers./Purch. Code"; Code[20])
        {
            TableRelation = "Salesperson/Purchaser";
        }
        field(23; "Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(24; "User ID"; Code[20]) { }
        field(25; "Source Code"; Code[10])
        {
            TableRelation = "Source Code";
        }
        field(28; "Applies-to Entry"; Integer)
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
        field(41; "Source Type"; Option)
        {
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(43; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(45; "Cost Posted to G/L"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(46; "Reason Code"; Code[10])
        {
            TableRelation = "Reason Code";
        }
        field(47; "Drop Shipment"; Boolean)
        {
        }
        field(48; "Journal Batch Name"; Code[10])
        {
            TableRelation = "Item Journal Batch";
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Business Posting Group";
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Product Posting Group";
        }
        field(60; "Document Date"; Date)
        {
        }
        field(61; "External Document No."; Code[20])
        {
        }
        field(68; "Cost Amount (Actual) (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(70; "Cost Posted to G/L (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(72; "Cost per Unit (ACY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(98; "Expected Cost"; Boolean)
        {
        }
        field(99; "Item Charge No."; Code[20])
        {
            TableRelation = "Item Charge";
        }
        field(100; "Valued By Average Cost"; Boolean)
        {
        }
        field(102; "Partial Revaluation"; Boolean)
        {
        }
        field(103; Inventoriable; Boolean)
        {
        }
        field(104; "Valuation Date"; Date)
        {
        }
        field(105; "Entry Type"; Option)
        {
            Editable = false;
            OptionMembers = "Direct Cost",Revaluation,Rounding,"Indirect Cost",Variance;
        }
        field(106; "Variance Type"; Enum "Cost Variance Type")
        {
            Editable = false;
        }
        field(107; "G/L Entry No. (Account)"; Integer)
        {
            TableRelation = "G/L Entry";
        }
        field(108; "G/L Entry No. (Bal. Account)"; Integer)
        {
            TableRelation = "G/L Entry";
        }
        field(109; "G/L Entry No. (Interim Acc.)"; Integer)
        {
            BlankZero = true;
            TableRelation = "G/L Entry";
        }
        field(110; "G/L Entry No. (Int. Bal. Acc.)"; Integer)
        {
            BlankZero = true;
            TableRelation = "G/L Entry";
        }
        field(148; "Purchase Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(149; "Purchase Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(150; "Sales Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(151; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(152; "Cost Amount (Non-Invt.)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(156; "Cost Amount (Expected) (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(157; "Cost Amount (Non-Invt.) (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(158; "Expected Cost Posted to G/L"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(159; "Exp. Cost Posted to G/L (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(5401; "Prod. Order No."; Code[20])
        {
        }
        field(5402; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = FIELD("Item No."));
        }
        field(5818; Adjustment; Boolean)
        {
            Editable = false;
        }
        field(5831; "Capacity Ledger Entry No."; Integer)
        {
            TableRelation = "Capacity Ledger Entry";
        }
        field(5832; Type; Option)
        {
            OptionMembers = "Work Center","Machine Center"," ";
        }
        field(5834; "No."; Code[20])
        {
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center";
        }
        field(5881; "Prod. Order Line No."; Integer)
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

    var

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;
}
