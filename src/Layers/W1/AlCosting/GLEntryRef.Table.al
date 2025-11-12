table 103408 "G/L Entry Ref."
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "General Ledger Entries";
    LookupPageID = "General Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
        field(3; "G/L Account No."; Code[20])
        {
            TableRelation = "G/L Account";
        }
        field(4; "Posting Date"; Date)
        {
            ClosingDates = true;
        }
        field(5; "Document Type"; Option)
        {
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        }
        field(6; "Document No."; Code[20])
        {
        }
        field(7; Description; Text[50])
        {
        }
        field(10; "Bal. Account No."; Code[20])
        {
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
        field(17; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
        }
        field(27; "User ID"; Code[20])
        {
        }
        field(28; "Source Code"; Code[10])
        {
            TableRelation = "Source Code";
        }
        field(29; "System-Created Entry"; Boolean)
        {
        }
        field(30; "Prior-Year Entry"; Boolean)
        {
        }
        field(41; "Job No."; Code[20])
        {
            TableRelation = Job;
        }
        field(42; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(43; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(45; "Business Unit Code"; Code[20])
        {
            TableRelation = "Business Unit";
        }
        field(46; "Journal Batch Name"; Code[10])
        {
            TableRelation = "Gen. Journal Batch";
        }
        field(47; "Reason Code"; Code[10])
        {
            TableRelation = "Reason Code";
        }
        field(48; "Gen. Posting Type"; Option)
        {
            OptionMembers = " ",Purchase,Sale,Settlement;
        }
        field(49; "Gen. Bus. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Business Posting Group";
        }
        field(50; "Gen. Prod. Posting Group"; Code[20])
        {
            TableRelation = "Gen. Product Posting Group";
        }
        field(51; "Bal. Account Type"; Option)
        {
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(52; "Transaction No."; Integer)
        {
        }
        field(53; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
        }
        field(54; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
        }
        field(55; "Document Date"; Date)
        {
            ClosingDates = true;
        }
        field(56; "External Document No."; Code[20])
        {
        }
        field(57; "Source Type"; Option)
        {
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";
        }
        field(58; "Source No."; Code[20])
        {
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account";
        }
        field(59; "No. Series"; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(60; "Tax Area Code"; Code[20])
        {
            TableRelation = "Tax Area";
        }
        field(61; "Tax Liable"; Boolean)
        {
        }
        field(62; "Tax Group Code"; Code[10])
        {
            TableRelation = "Tax Group";
        }
        field(63; "Use Tax"; Boolean)
        {
        }
        field(64; "VAT Bus. Posting Group"; Code[20])
        {
            TableRelation = "VAT Business Posting Group";
        }
        field(65; "VAT Prod. Posting Group"; Code[20])
        {
            TableRelation = "VAT Product Posting Group";
        }
        field(68; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(69; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(70; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(5400; "Prod. Order No."; Code[20])
        {
        }
        field(5600; "FA Entry Type"; Option)
        {
            OptionMembers = " ","Fixed Asset",Maintenance;
        }
        field(5601; "FA Entry No."; Integer)
        {
            BlankZero = true;
            TableRelation = if ("FA Entry Type" = const("Fixed Asset")) "FA Ledger Entry"
            else
            if ("FA Entry Type" = const(Maintenance)) "Maintenance Ledger Entry";
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

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;
}
