#pragma warning disable AA0247
table 14927 "VAT Document Entry Buffer"
{
    Caption = 'VAT Document Entry Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = SystemMetadata;
            TableRelation = if ("Entry Type" = const(Sale)) Customer
            else
            if ("Entry Type" = const(Purchase)) Vendor;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Posting Date" < "Document Date" then
                    FieldError("Posting Date");
            end;
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(8; "CV Name"; Text[100])
        {
            Caption = 'CV Name';
            DataClassification = SystemMetadata;
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(15; "Original Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Original Amt. (LCY)';
            DataClassification = SystemMetadata;
        }
        field(16; "Remaining Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Amt. (LCY)';
            DataClassification = SystemMetadata;
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(18; "Sales/Purchase (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales/Purchase (LCY)';
            DataClassification = SystemMetadata;
        }
        field(19; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Profit (LCY)';
            DataClassification = SystemMetadata;
        }
        field(20; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Inv. Discount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(21; "Bill-to/Pay-to CV No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to CV No.';
            DataClassification = SystemMetadata;
            TableRelation = Customer;
        }
        field(22; "CV Posting Group"; Code[20])
        {
            Caption = 'CV Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Customer Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = SystemMetadata;
            TableRelation = "Salesperson/Purchaser";
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = SystemMetadata;
            TableRelation = "Source Code";
        }
        field(33; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
            DataClassification = SystemMetadata;
        }
        field(34; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            DataClassification = SystemMetadata;
        }
        field(35; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(36; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = SystemMetadata;
        }
        field(37; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = SystemMetadata;
        }
        field(38; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            DataClassification = SystemMetadata;
        }
        field(39; "Original Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        field(40; "Pmt. Disc. Given (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Disc. Given (LCY)';
            DataClassification = SystemMetadata;
            AutoFormatExpression = '';
        }
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = SystemMetadata;
        }
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Cust. Ledger Entry";
        }
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
            DataClassification = SystemMetadata;
        }
        field(46; "Closed by Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
            DataClassification = SystemMetadata;
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            DataClassification = SystemMetadata;
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = SystemMetadata;
            TableRelation = "Reason Code";
        }
        field(51; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = SystemMetadata;
        }
        field(52; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = SystemMetadata;
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        field(54; "Closed by Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Closed by Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(58; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = SystemMetadata;
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(67; "Closed by Currency Code"; Code[10])
        {
            Caption = 'Closed by Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(68; "Closed by Currency Amount"; Decimal)
        {
            AutoFormatExpression = "Closed by Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(70; "Rounding Currency"; Code[10])
        {
            Caption = 'Rounding Currency';
            DataClassification = SystemMetadata;
        }
        field(71; "Rounding Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Rounding Amount';
            DataClassification = SystemMetadata;
        }
        field(72; "Rounding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Rounding Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(73; "Adjusted Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Adjusted Currency Factor';
            DataClassification = SystemMetadata;
        }
        field(74; "Original Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Original Currency Factor';
            DataClassification = SystemMetadata;
        }
        field(75; "Original Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Original Amount';
            DataClassification = SystemMetadata;
        }
        field(76; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(77; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        field(78; "Pmt. Disc. Tolerance Date"; Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';
            DataClassification = SystemMetadata;
        }
        field(79; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Max. Payment Tolerance';
            DataClassification = SystemMetadata;
        }
        field(80; "Last Issued Reminder Level"; Integer)
        {
            Caption = 'Last Issued Reminder Level';
            DataClassification = SystemMetadata;
        }
        field(81; "Accepted Payment Tolerance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Accepted Payment Tolerance';
            DataClassification = SystemMetadata;
        }
        field(82; "Accepted Pmt. Disc. Tolerance"; Boolean)
        {
            AutoFormatType = 0;
            Caption = 'Accepted Pmt. Disc. Tolerance';
            DataClassification = SystemMetadata;
        }
        field(83; "Pmt. Tolerance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Pmt. Tolerance (LCY)';
            DataClassification = SystemMetadata;
        }
        field(84; "Amount to Apply"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Apply';
            DataClassification = SystemMetadata;
        }
        field(85; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = SystemMetadata;
            TableRelation = "IC Partner";
        }
        field(86; "Applying Entry"; Boolean)
        {
            Caption = 'Applying Entry';
            DataClassification = SystemMetadata;
        }
        field(87; Reversed; Boolean)
        {
            BlankZero = true;
            Caption = 'Reversed';
            DataClassification = SystemMetadata;
        }
        field(88; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Cust. Ledger Entry";
        }
        field(89; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Cust. Ledger Entry";
        }
        field(90; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(12401; "Prepmt. Diff. Appln. Entry No."; Integer)
        {
            Caption = 'Prepmt. Diff. Appln. Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12402; "Prepmt. Diff. Vend. Entry No."; Integer)
        {
            Caption = 'Prepmt. Diff. Vend. Entry No.';
            DataClassification = SystemMetadata;
        }
        field(12425; "Prepayment Document No."; Code[20])
        {
            Caption = 'Prepayment Document No.';
            DataClassification = SystemMetadata;
        }
        field(12426; "Prepayment Status"; Option)
        {
            Caption = 'Prepayment Status';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Set,Reset';
            OptionMembers = " ",Set,Reset;
        }
        field(12430; "Vendor VAT Invoice No."; Code[30])
        {
            Caption = 'Vendor VAT Invoice No.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                SetChangedVATInvoice();
            end;
        }
        field(12431; "Vendor VAT Invoice Date"; Date)
        {
            Caption = 'Vendor VAT Invoice Date';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                SetChangedVATInvoice();
            end;
        }
        field(12432; "Vendor VAT Invoice Rcvd Date"; Date)
        {
            Caption = 'Vendor VAT Invoice Rcvd Date';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                SetChangedVATInvoice();
            end;
        }
        field(12470; "Vendor Receipts No."; Code[20])
        {
            Caption = 'Vendor Receipts No.';
            DataClassification = SystemMetadata;
        }
        field(12471; "Vendor Receipts Date"; Date)
        {
            Caption = 'Vendor Receipts Date';
            DataClassification = SystemMetadata;
        }
        field(12485; "VAT Adjusted"; Boolean)
        {
            Caption = 'VAT Adjusted';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12490; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            DataClassification = SystemMetadata;
        }
        field(14925; "Realized VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Entry".Amount where("CV Ledg. Entry No." = field("Entry No."),
                                                        Type = field("Entry Type"),
                                                        "Posting Date" = field("Date Filter"),
                                                        "VAT Settlement Type" = field("Type Filter"),
                                                        "Manual VAT Settlement" = const(true),
                                                        "VAT Bus. Posting Group" = field("VAT Bus. Posting Group Filter"),
                                                        "VAT Prod. Posting Group" = field("VAT Prod. Posting Group Filter")));
            Caption = 'Realized VAT Amount';
            FieldClass = FlowField;
        }
        field(14926; "Unrealized VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Entry"."Unrealized Amount" where(Type = field("Entry Type"),
                                                                     "CV Ledg. Entry No." = field("Entry No."),
                                                                     "Posting Date" = field("Date Filter"),
                                                                     "VAT Settlement Type" = field("Type Filter"),
                                                                     "Manual VAT Settlement" = const(true),
                                                                     "VAT Bus. Posting Group" = field("VAT Bus. Posting Group Filter"),
                                                                     "VAT Prod. Posting Group" = field("VAT Prod. Posting Group Filter")));
            Caption = 'Unrealized VAT Amount';
            FieldClass = FlowField;
        }
        field(14927; "Realized VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Entry".Base where("CV Ledg. Entry No." = field("Entry No."),
                                                      Type = field("Entry Type"),
                                                      "Posting Date" = field("Date Filter"),
                                                      "VAT Settlement Type" = field("Type Filter"),
                                                      "Manual VAT Settlement" = const(true),
                                                      "VAT Bus. Posting Group" = field("VAT Bus. Posting Group Filter"),
                                                      "VAT Prod. Posting Group" = field("VAT Prod. Posting Group Filter")));
            Caption = 'Realized VAT Base';
            FieldClass = FlowField;
        }
        field(14928; "Unrealized VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Entry"."Unrealized Base" where(Type = field("Entry Type"),
                                                                   "CV Ledg. Entry No." = field("Entry No."),
                                                                   "Posting Date" = field("Date Filter"),
                                                                   "VAT Settlement Type" = field("Type Filter"),
                                                                   "Manual VAT Settlement" = const(true),
                                                                   "VAT Bus. Posting Group" = field("VAT Bus. Posting Group Filter"),
                                                                   "VAT Prod. Posting Group" = field("VAT Prod. Posting Group Filter")));
            Caption = 'Unrealized VAT Base';
            FieldClass = FlowField;
        }
        field(14929; "VAT Amount To Allocate"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("VAT Allocation Line".Amount where("CV Ledger Entry No." = field("Entry No."),
                                                                  "VAT Settlement Type" = field("Type Filter"),
                                                                  "VAT Bus. Posting Group" = field("VAT Bus. Posting Group Filter"),
                                                                  "VAT Prod. Posting Group" = field("VAT Prod. Posting Group Filter")));
            Caption = 'VAT Amount To Allocate';
            FieldClass = FlowField;
        }
        field(14930; "Entry Type"; Enum "General Posting Type")
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
        }
        field(14931; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        field(14932; "Allocated VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Allocated VAT Amount';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                VATSettlementMgt.UpdateDocVATAlloc("Allocated VAT Amount", "Entry No.", "Posting Date");
            end;
        }
        field(14933; "Type Filter"; Option)
        {
            Caption = 'Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,by Act,Future Expenses';
            OptionMembers = " ","by Act","Future Expenses";
        }
        field(14934; "Changed Vendor VAT Invoice"; Boolean)
        {
            Caption = 'Changed Vendor VAT Invoice';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(14935; "VAT Bus. Posting Group Filter"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "VAT Business Posting Group";
        }
        field(14936; "VAT Prod. Posting Group Filter"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "VAT Product Posting Group";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        DimMgt: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure GetRemainingVATAmount(Type: Option Full,Base,Amount): Decimal
    begin
        case Type of
            Type::Full:
                exit(GetRemainingVATAmount(1) + GetRemainingVATAmount(2));
            Type::Base:
                begin
                    CalcFields("Unrealized VAT Base", "Realized VAT Base");
                    exit("Unrealized VAT Base" - "Realized VAT Base");
                end;
            Type::Amount:
                begin
                    CalcFields("Unrealized VAT Amount", "Realized VAT Amount");
                    exit("Unrealized VAT Amount" - "Realized VAT Amount");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowCVEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntries: Page "Customer Ledger Entries";
        VendLedgEntries: Page "Vendor Ledger Entries";
    begin
        case "Entry Type" of
            "Entry Type"::Purchase:
                begin
                    VendLedgEntry.SetRange("Entry No.", "Entry No.");
                    VendLedgEntries.SetTableView(VendLedgEntry);
                    VendLedgEntries.RunModal();
                end;
            "Entry Type"::Sale:
                begin
                    CustLedgEntry.SetRange("Entry No.", "Entry No.");
                    CustLedgEntries.SetTableView(CustLedgEntry);
                    CustLedgEntries.RunModal();
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetChangedVATInvoice()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        TestField("Entry Type", "Entry Type"::Purchase);
        VendLedgEntry.Get("Entry No.");
        "Changed Vendor VAT Invoice" :=
          ("Vendor VAT Invoice No." <> VendLedgEntry."Vendor VAT Invoice No.") or
          ("Vendor VAT Invoice Date" <> VendLedgEntry."Vendor VAT Invoice Date") or
          ("Vendor VAT Invoice Rcvd Date" <> VendLedgEntry."Vendor VAT Invoice Rcvd Date");
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Entry No."));
    end;
}

