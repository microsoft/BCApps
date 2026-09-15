#pragma warning disable AA0247
table 17212 "Tax Register Item Entry"
{
    Caption = 'Tax Register Item Entry';
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
            TableRelation = "Tax Register Section";
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
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
        field(11; "Costing Method"; Option)
        {
            Caption = 'Costing Method';
            OptionCaption = ' ,FIFO,LIFO,Average,FIFO+LIFO';
            OptionMembers = " ",FIFO,LIFO,"Average","FIFO+LIFO";
        }
        field(12; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = ' ,Incoming,Spending';
            OptionMembers = " ",Incoming,Spending;
        }
        field(13; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(14; "Qty. (Document)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. (Document)';
        }
        field(15; "Amount (Document)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount (Document)';
            Editable = false;
        }
        field(16; "Entry Secondary Batch"; Boolean)
        {
            Caption = 'Entry Secondary Batch';
        }
        field(20; "Qty. (Batch)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. (Batch)';
        }
        field(21; "Amount (Batch)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Amount (Batch)';
        }
        field(22; "Credit Qty."; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Credit Qty.';
            Editable = false;
        }
        field(23; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount';
            Editable = false;
        }
        field(24; "Debit Qty."; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Debit Qty.';
            Editable = false;
        }
        field(25; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount';
            Editable = false;
        }
        field(26; "Outstand. Quantity"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = sum("Item Application Entry".Quantity where("Batch Item Ledger Entry No." = field("Appl. Entry No."),
                                                                       "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Outstand. Quantity';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Original Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Original Amount';
            Editable = false;
        }
        field(28; "Appl. Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Appl. Entry No.';
            TableRelation = "Item Ledger Entry"."Entry No.";
        }
        field(29; "Batch Date"; Date)
        {
            Caption = 'Batch Date';
        }
        field(30; "Batch Qty."; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Batch Qty.';
        }
        field(31; "Batch Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Batch Amount';
            Editable = false;
        }
        field(32; "Debit Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Unit Cost';
        }
        field(38; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(100; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item Ledger Entry No." = field("Ledger Entry No.")));
            Caption = 'Cost Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(101; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = "Item Ledger Entry"."Entry No.";
        }
        field(102; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund,,,,,Receipt,Shipment,Return Rcpt.,Return Shpt.,,,,,,,Positive Adj.,Negative Adj.';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund,,,,,Receipt,Shipment,"Return Rcpt.","Return Shpt.",,,,,,,"Positive Adj.","Negative Adj.";
        }
        field(103; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(105; "Ledger Entry Type"; Enum "Item Ledger Entry Type")
        {
            CalcFormula = lookup("Item Ledger Entry"."Entry Type" where("Entry No." = field("Ledger Entry No.")));
            Caption = 'Ledger Entry Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(106; Description; Text[70])
        {
            Caption = 'Description';
        }
        field(107; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(121; "Dimension 1 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 1);
            Caption = 'Dimension 1 Value Code';
        }
        field(122; "Dimension 2 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 2);
            Caption = 'Dimension 2 Value Code';
        }
        field(123; "Dimension 3 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 3);
            Caption = 'Dimension 3 Value Code';
        }
        field(124; "Dimension 4 Value Code"; Code[20])
        {
            CaptionClass = TaxRegMgt.GetDimCaptionClass("Section Code", 4);
            Caption = 'Dimension 4 Value Code';
        }
        field(131; "Item Ledger Source Type"; Enum "Analysis Source Type")
        {
            CalcFormula = lookup("Item Ledger Entry"."Source Type" where("Entry No." = field("Ledger Entry No.")));
            Caption = 'Item Ledger Source Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(132; "Sales/Purch. Account No."; Code[20])
        {
            Caption = 'Sales/Purch. Account No.';
            TableRelation = if ("Item Ledger Source Type" = filter(Customer | Vendor)) "G/L Account"."No.";
        }
        field(133; "Inventory Account No."; Code[20])
        {
            Caption = 'Inventory Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(134; "Direct Cost Account No."; Code[20])
        {
            Caption = 'Direct Cost Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(135; "Sales/Purch. Posting Code"; Code[20])
        {
            Caption = 'Sales/Purch. Posting Code';
            TableRelation = if ("Item Ledger Source Type" = filter(Vendor)) "Vendor Posting Group".Code
            else
            if ("Item Ledger Source Type" = filter(Customer)) "Customer Posting Group".Code;
        }
        field(136; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(137; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(138; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(139; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(186; "Debit Account No."; Code[20])
        {
            Caption = 'Debit Account No.';
            TableRelation = "G/L Account"."No.";
        }
        field(187; "Credit Account No."; Code[20])
        {
            Caption = 'Credit Account No.';
            TableRelation = "G/L Account"."No.";
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
        key(Key4; "Section Code", "Entry Type", "Posting Date")
        {
        }
        key(Key5; "Section Code", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        TaxRegMgt: Codeunit "Tax Register Mgt.";

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
    procedure SetFieldFilter(FieldNumber: Integer) FieldInList: Boolean
    begin
        FieldInList :=
          FieldNumber in [
                          FieldNo("Original Amount"),
                          FieldNo("Amount (Batch)"),
                          FieldNo("Credit Amount"),
                          FieldNo("Debit Amount")
                          ];
    end;

    [Scope('OnPrem')]
    procedure SetTemplateFilter(TaxRegTemplate: Record "Tax Register Template")
    begin
        case TaxRegTemplate."Sum Field No." of
            FieldNo("Credit Amount"):
                SetFilter("Credit Qty.", '<>0');
            FieldNo("Debit Amount"):
                SetFilter("Debit Qty.", '<>0');
        end;
    end;

    [Scope('OnPrem')]
    procedure FormTitle(): Text[250]
    var
        TaxRegName: Record "Tax Register";
    begin
        FilterGroup(2);
        TaxRegName.SetRange("Section Code", "Section Code");
        TaxRegName.SetFilter("Register ID", DelChr(GetFilter("Where Used Register IDs"), '=', '~'));
        FilterGroup(0);
        if TaxRegName.Find('-') then
            if TaxRegName.Next() = 0 then
                exit(TaxRegName.Description);
    end;
}

