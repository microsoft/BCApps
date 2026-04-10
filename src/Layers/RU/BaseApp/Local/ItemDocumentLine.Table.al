#if not CLEANSCHEMA28
#pragma warning disable AA0247
table 12453 "Item Document Line"
{
    Caption = 'Item Document Line';
    ObsoleteState = Removed;
    ObsoleteReason = 'Replaced by Inventory Documents feature.';
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Receipt,Shipment';
            OptionMembers = Receipt,Shipment;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
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
        field(13; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(16; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Amount';
        }
        field(17; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
        }
        field(18; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
        }
        field(23; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
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
            AutoFormatType = 0;
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(38; "Gross Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(39; "Net Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(40; "Units per Parcel"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(41; "Unit Volume"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(42; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(57; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(58; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(65; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(72; "Unit Cost (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalCurrencyCode();
            Caption = 'Unit Cost (ACY)';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5413; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5470; "Reserved Quantity Inbnd."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                  "Source Ref. No." = field("Line No."),
                                                                  "Source Type" = const(12453),
                                                                  "Source Subtype" = filter("0" | "3"),
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity Inbnd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5471; "Reserved Quantity Outbnd."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = - sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                   "Source Ref. No." = field("Line No."),
                                                                   "Source Type" = const(12453),
                                                                   "Source Subtype" = filter("1" | "2"),
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity Outbnd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5472; "Reserved Qty. Inbnd. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Source Type" = const(12453),
                                                                           "Source Subtype" = filter("0" | "3"),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. Inbnd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5473; "Reserved Qty. Outbnd. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                            "Source Ref. No." = field("Line No."),
                                                                            "Source Type" = const(12453),
                                                                            "Source Subtype" = filter("1" | "2"),
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. Outbnd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5600; "FA Writeoff No."; Code[20])
        {
            Caption = 'FA Writeoff No.';
            TableRelation = "FA Document Header"."No." where("Document Type" = const(Writeoff));
        }
        field(5601; "FA Writeoff Line No."; Integer)
        {
            Caption = 'FA Writeoff Line No.';
            TableRelation = "FA Document Line"."Line No." where("Document Type" = const(Writeoff),
                                                                 "Document No." = field("FA Writeoff No."));
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5706; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5801; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            TableRelation = "Item Charge";
        }
        field(5807; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            MinValue = 0;
        }
        field(5811; "Applied Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Applied Amount';
            Editable = false;
        }
        field(5812; "Update Standard Cost"; Boolean)
        {
            Caption = 'Update Standard Cost';
        }
        field(5813; "Amount (ACY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalCurrencyCode();
            Caption = 'Amount (ACY)';
        }
        field(5819; "Applies-to Value Entry"; Integer)
        {
            Caption = 'Applies-to Value Entry';
        }
        field(12450; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";
        }
        field(12451; "FA Entry No."; Integer)
        {
            Caption = 'FA Entry No.';
            TableRelation = "FA Ledger Entry" where("Entry No." = field("FA Entry No."));
        }
        field(12452; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "FA Depreciation Book"."Depreciation Book Code" where("FA No." = field("FA No."));
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";

    local procedure GetAdditionalCurrencyCode(): Text[10]
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;
}
#endif