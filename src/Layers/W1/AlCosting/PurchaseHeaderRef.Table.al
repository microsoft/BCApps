table 103411 "Purchase Header Ref."
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataCaptionFields = "No.", "Buy-from Vendor Name";
    LookupPageID = "Purchase List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order";
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            TableRelation = Vendor;
        }
        field(3; "No."; Code[20])
        {
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(5; "Pay-to Name"; Text[30])
        {
        }
        field(6; "Pay-to Name 2"; Text[30])
        {
        }
        field(7; "Pay-to Address"; Text[30])
        {
        }
        field(8; "Pay-to Address 2"; Text[30])
        {
        }
        field(9; "Pay-to City"; Text[30])
        {
        }
        field(10; "Pay-to Contact"; Text[30])
        {
        }
        field(11; "Your Reference"; Text[30])
        {
        }
        field(12; "Ship-to Code"; Code[10])
        {
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        field(13; "Ship-to Name"; Text[30])
        {
        }
        field(14; "Ship-to Name 2"; Text[30])
        {
        }
        field(15; "Ship-to Address"; Text[30])
        {
        }
        field(16; "Ship-to Address 2"; Text[30])
        {
        }
        field(17; "Ship-to City"; Text[30])
        {
        }
        field(18; "Ship-to Contact"; Text[30])
        {
        }
        field(19; "Order Date"; Date)
        {
        }
        field(20; "Posting Date"; Date)
        {
        }
        field(21; "Expected Receipt Date"; Date)
        {
        }
        field(22; "Posting Description"; Text[50])
        {
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            TableRelation = "Payment Terms";
        }
        field(24; "Due Date"; Date)
        {
        }
        field(25; "Payment Discount %"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            TableRelation = "Shipment Method";
        }
        field(28; "Location Code"; Code[10])
        {
            TableRelation = Location;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
        }
        field(31; "Vendor Posting Group"; Code[20])
        {
            Editable = false;
            TableRelation = "Vendor Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
        }
        field(41; "Language Code"; Code[10])
        {
            TableRelation = Language;
        }
        field(43; "Purchaser Code"; Code[20])
        {
            TableRelation = "Salesperson/Purchaser";
        }
        field(45; "Order Class"; Code[10])
        {
        }
        field(46; Comment; Boolean)
        {
#pragma warning disable AL0603
            CalcFormula = exist("Purch. Comment Line" where("Document Type" = field("Document Type"),
                                                             "No." = field("No.")));
#pragma warning restore AL0603
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Editable = false;
        }
        field(51; "On Hold"; Code[3])
        {
        }
        field(52; "Applies-to Doc. Type"; Option)
        {
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
        }
        field(55; "Bal. Account No."; Code[20])
        {
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(56; "Job No."; Code[20])
        {
            TableRelation = Job;
        }
        field(57; Receive; Boolean)
        {
        }
        field(58; Invoice; Boolean)
        {
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
#pragma warning disable AL0603
            CalcFormula = sum("Purchase Line".Amount where("Document Type" = field("Document Type"),
                                                            "Document No." = field("No.")));
#pragma warning restore AL0603
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
#pragma warning disable AL0603
            CalcFormula = sum("Purchase Line"."Amount Including VAT" where("Document Type" = field("Document Type"),
                                                                            "Document No." = field("No.")));
#pragma warning restore AL0603
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Receiving No."; Code[20])
        {
        }
        field(63; "Posting No."; Code[20])
        {
        }
        field(64; "Last Receiving No."; Code[20])
        {
            Editable = false;
            TableRelation = "Purch. Rcpt. Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Editable = false;
            TableRelation = "Purch. Inv. Header";
        }
        field(66; "Vendor Order No."; Code[20])
        {
        }
        field(67; "Vendor Shipment No."; Code[20])
        {
        }
        field(68; "Vendor Invoice No."; Code[20])
        {
        }
        field(69; "Vendor Cr. Memo No."; Code[20])
        {
        }
        field(70; "VAT Registration No."; Text[20])
        {
        }
        field(72; "Sell-to Customer No."; Code[20])
        {
            TableRelation = Customer;
        }
        field(73; "Reason Code"; Code[10])
        {
            TableRelation = "Reason Code";
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Business Posting Group";
        }
        field(76; "Transaction Type"; Code[10])
        {
            TableRelation = "Transaction Type";
        }
        field(77; "Transport Method"; Code[10])
        {
            TableRelation = "Transport Method";
        }
        field(78; "VAT Country Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(79; "Buy-from Vendor Name"; Text[30])
        {
        }
        field(80; "Buy-from Vendor Name 2"; Text[30])
        {
        }
        field(81; "Buy-from Address"; Text[30])
        {
        }
        field(82; "Buy-from Address 2"; Text[30])
        {
        }
        field(83; "Buy-from City"; Text[30])
        {
        }
        field(84; "Buy-from Contact"; Text[30])
        {
        }
        field(85; "Pay-to Post Code"; Code[20])
        {
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Pay-to County"; Text[30])
        {
        }
        field(87; "Pay-to Country Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(88; "Buy-from Post Code"; Code[20])
        {
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(89; "Buy-from County"; Text[30])
        {
        }
        field(90; "Buy-from Country Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(92; "Ship-to County"; Text[30])
        {
        }
        field(93; "Ship-to Country Code"; Code[10])
        {
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; Option)
        {
            OptionMembers = "G/L Account","Bank Account";
        }
        field(95; "Order Address Code"; Code[10])
        {
            TableRelation = "Order Address".Code where("Vendor No." = field("Buy-from Vendor No."));
        }
        field(97; "Entry Point"; Code[10])
        {
            TableRelation = "Entry/Exit Point";
        }
        field(98; Correction; Boolean)
        {
        }
        field(99; "Document Date"; Date)
        {
        }
        field(101; "Area"; Code[10])
        {
            TableRelation = Area;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            TableRelation = "Transaction Specification";
        }
        field(104; "Payment Method Code"; Code[10])
        {
            TableRelation = "Payment Method";
        }
        field(107; "No. Series"; Code[20])
        {
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Posting No. Series"; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(109; "Receiving No. Series"; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(114; "Tax Area Code"; Code[20])
        {
            TableRelation = "Tax Area";
        }
        field(115; "Tax Liable"; Boolean)
        {
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            TableRelation = "VAT Business Posting Group";
        }
        field(117; Reserve; Option)
        {
            OptionMembers = Never,Optional,Always;
        }
        field(118; "Applies-to ID"; Code[20])
        {
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            TableRelation = "Responsibility Center".Code;
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
    }

    keys
    {
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Document Type", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

}
