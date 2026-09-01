#pragma warning disable AA0247
table 17317 "Tax Calc. Item Entry"
{
    Caption = 'Tax Calc. Item Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            TableRelation = "Tax Calc. Section";
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            Editable = false;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            Editable = false;
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(7; Description; Text[70])
        {
            Caption = 'Description';
        }
        field(15; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
        }
        field(21; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = "Item Ledger Entry"."Entry No.";
        }
        field(22; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,Receipt,Shipment,Return Rcpt.,Return Shpt.,,,,,,,Positive Adj.,Negative Adj.';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,Receipt,Shipment,"Return Rcpt.","Return Shpt.",,,,,,,"Positive Adj.","Negative Adj.";
        }
        field(23; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(24; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(25; "Ledger Entry Type"; Enum "Item Ledger Entry Type")
        {
            CalcFormula = lookup("Item Ledger Entry"."Entry Type" where("Entry No." = field("Ledger Entry No.")));
            Caption = 'Ledger Entry Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 1);
            Caption = 'Dimension 1 Value Code';
        }
        field(31; "Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 2);
            Caption = 'Dimension 2 Value Code';
        }
        field(32; "Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 3);
            Caption = 'Dimension 3 Value Code';
        }
        field(33; "Dimension 4 Value Code"; Code[20])
        {
            CaptionClass = TaxCalcMgt.GetDimCaptionClass("Section Code", 4);
            Caption = 'Dimension 4 Value Code';
        }
        field(35; "Item Ledger Source Type"; Enum "Analysis Source Type")
        {
            CalcFormula = lookup("Item Ledger Entry"."Source Type" where("Entry No." = field("Ledger Entry No.")));
            Caption = 'Item Ledger Source Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(36; "Sales/Purch. Account No."; Code[20])
        {
            Caption = 'Sales/Purch. Account No.';
            TableRelation = if ("Item Ledger Source Type" = filter(Customer | Vendor)) "G/L Account"."No.";
        }
        field(37; "Inventory Account No."; Code[20])
        {
            Caption = 'Inventory Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(38; "Direct Cost Account No."; Code[20])
        {
            Caption = 'Direct Cost Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(39; "Sales/Purch. Posting Code"; Code[20])
        {
            Caption = 'Sales/Purch. Posting Code';
            TableRelation = if ("Item Ledger Source Type" = filter(Vendor)) "Vendor Posting Group".Code
            else
            if ("Item Ledger Source Type" = filter(Customer)) "Customer Posting Group".Code;
        }
        field(40; "Debit Account No."; Code[20])
        {
            Caption = 'Debit Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(41; "Credit Account No."; Code[20])
        {
            Caption = 'Credit Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(42; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(43; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(44; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(45; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(51; Quantity; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Quantity';
        }
        field(52; "Amount (Tax)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount (Tax)';
        }
        field(53; "Credit Quantity"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Credit Quantity';
            Editable = false;
        }
        field(54; "Credit Amount (Tax)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (Tax)';
            Editable = false;
        }
        field(55; "Debit Quantity"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Debit Quantity';
            Editable = false;
        }
        field(56; "Debit Amount (Tax)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (Tax)';
            Editable = false;
        }
        field(57; "Outstand. Quantity"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = sum("Item Application Entry".Quantity where("Batch Item Ledger Entry No." = field("Appl. Entry No."),
                                                                       "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Outstand. Quantity';
            Editable = false;
            FieldClass = FlowField;
        }
        field(58; "Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (Actual)';
            Editable = false;
        }
        field(59; "Appl. Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Appl. Entry No.';
            TableRelation = "Item Ledger Entry"."Entry No.";
        }
        field(60; "Credit Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (Actual)';
            Editable = false;
        }
        field(61; "Debit Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (Actual)';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Ending Date")
        {
        }
        key(Key3; "Section Code", "Starting Date")
        {
        }
        key(Key4; "Section Code", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";

    [Scope('OnPrem')]
    procedure ObjectName(): Text[100]
    var
        Item: Record Item;
    begin
        if Item.Get("Item No.") then
            exit(Item.Description);
    end;

    [Scope('OnPrem')]
    procedure Navigating()
    var
        Navigate: Page Navigate;
    begin
        Clear(Navigate);
        Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
        Navigate.Run();
    end;

    [Scope('OnPrem')]
    procedure DebitAccountName(): Text[100]
    var
        GLAcc: Record "G/L Account";
    begin
        if GLAcc.Get("Debit Account No.") then
            exit(GLAcc.Name);
    end;

    [Scope('OnPrem')]
    procedure CreditAccountName(): Text[100]
    var
        GLAcc: Record "G/L Account";
    begin
        if GLAcc.Get("Credit Account No.") then
            exit(GLAcc.Name);
    end;

    [Scope('OnPrem')]
    procedure UOMName(): Text[100]
    var
        Item: Record Item;
        UOM: Record "Unit of Measure";
    begin
        if Item.Get("Item No.") then
            if UOM.Get(Item."Base Unit of Measure") then
                exit(UOM.Description);
    end;

    [Scope('OnPrem')]
    procedure SetFieldFilter(FieldNumber: Integer; TypeField: Option SumFields,CalcFields) FieldInList: Boolean
    begin
        case TypeField of
            TypeField::SumFields:
                FieldInList :=
                  FieldNumber in [
                                  FieldNo("Amount (Actual)"),
                                  FieldNo("Credit Amount (Actual)"),
                                  FieldNo("Debit Amount (Actual)"),
                                  FieldNo("Amount (Tax)"),
                                  FieldNo("Credit Amount (Tax)"),
                                  FieldNo("Debit Amount (Tax)")
                                  ];
            TypeField::CalcFields:
                FieldInList := FieldNumber = -1;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetTaxCalcFilter(TaxCalcLine: Record "Tax Calc. Line")
    begin
        case TaxCalcLine."Sum Field No." of
            FieldNo("Credit Amount (Actual)"),
          FieldNo("Credit Amount (Tax)"):
                SetFilter("Credit Quantity", '<>0');
            FieldNo("Debit Amount (Actual)"),
          FieldNo("Debit Amount (Tax)"):
                SetFilter("Debit Quantity", '<>0');
        end;
    end;

    [Scope('OnPrem')]
    procedure FormTitle(): Text[250]
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        FilterGroup(2);
        TaxCalcHeader.SetRange("Section Code", "Section Code");
        TaxCalcHeader.SetFilter("Register ID", DelChr(GetFilter("Where Used Register IDs"), '=', '~'));
        FilterGroup(0);
        if TaxCalcHeader.FindSet() then
            if TaxCalcHeader.Next() = 0 then
                exit(TaxCalcHeader.Description);
    end;
}

