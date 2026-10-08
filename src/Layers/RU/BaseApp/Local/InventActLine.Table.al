#pragma warning disable AA0247
table 14909 "Invent. Act Line"
{
    Caption = 'Invent. Act Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Act No."; Code[20])
        {
            Caption = 'Act No.';
            TableRelation = "Invent. Act Header";
        }
        field(5; "Contractor Type"; Option)
        {
            Caption = 'Contractor Type';
            Editable = false;
            OptionCaption = 'Customer,Vendor';
            OptionMembers = Customer,Vendor;
        }
        field(6; "Contractor No."; Code[20])
        {
            Caption = 'Contractor No.';
            Editable = false;
            TableRelation = if ("Contractor Type" = const(Customer)) Customer
            else
            if ("Contractor Type" = const(Vendor)) Vendor;
        }
        field(7; "Contractor Name"; Text[250])
        {
            Caption = 'Contractor Name';
            Editable = false;
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if ("Contractor Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Contractor Type" = const(Vendor)) "Vendor Posting Group";
        }
        field(9; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            Editable = false;
            TableRelation = "G/L Account";
        }
        field(10; Category; Option)
        {
            Caption = 'Category';
            Editable = false;
            OptionCaption = 'Debts,Liabilities';
            OptionMembers = Debts,Liabilities;
        }
        field(15; "Total Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Amount';
            Editable = false;
        }
        field(16; "Confirmed Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Confirmed Amount';
            Editable = false;
        }
        field(17; "Not Confirmed Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Not Confirmed Amount';

            trigger OnValidate()
            begin
                UpdateTotal();
            end;
        }
        field(18; "Overdue Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Overdue Amount';

            trigger OnValidate()
            begin
                UpdateTotal();
            end;
        }
    }

    keys
    {
        key(Key1; "Act No.", "Contractor Type", "Contractor No.", "Posting Group", Category)
        {
            Clustered = true;
        }
        key(Key2; "Act No.", "Contractor Type", "Contractor No.", "G/L Account No.", Category)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatus();
    end;

    trigger OnModify()
    begin
        TestStatus();
    end;

    var
        InventActHeader: Record "Invent. Act Header";

    [Scope('OnPrem')]
    procedure TestStatus()
    begin
        InventActHeader.Get("Act No.");
        InventActHeader.TestField(Status, InventActHeader.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure UpdateTotal()
    begin
        "Confirmed Amount" := "Total Amount" - "Not Confirmed Amount" - "Overdue Amount";
    end;

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(
          StrSubstNo('%1=%2, %3=%4, %5=%6, %7=%8, %9=%10',
            "Act No.", "Contractor Type", "Contractor No.", "Posting Group", Category));
    end;

    [Scope('OnPrem')]
    procedure DrillDownAmount()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        InventActHeader: Record "Invent. Act Header";
        CustLedgEntries: Page "Customer Ledger Entries";
        VendLedgEntries: Page "Vendor Ledger Entries";
    begin
        InventActHeader.Get("Act No.");
        if "Contractor Type" = "Contractor Type"::Customer then begin
            CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date", "Currency Code");
            CustLedgEntry.FilterGroup(2);
            CustLedgEntry.SetRange("Customer No.", "Contractor No.");
            CustLedgEntry.SetRange("Posting Date", 0D, InventActHeader."Inventory Date");
            CustLedgEntry.SetRange("Customer Posting Group", "Posting Group");
            if Category = Category::Debts then
                CustLedgEntry.SetRange(Positive, true)
            else
                CustLedgEntry.SetRange(Positive, false);
            CustLedgEntry.FilterGroup(0);
            CustLedgEntry.SetRange("Date Filter", 0D, InventActHeader."Inventory Date");
            Clear(CustLedgEntries);
            CustLedgEntries.SetTableView(CustLedgEntry);
            CustLedgEntries.RunModal();
        end else begin
            VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Currency Code");
            VendLedgEntry.FilterGroup(2);
            VendLedgEntry.SetRange("Vendor No.", "Contractor No.");
            VendLedgEntry.SetRange("Posting Date", 0D, InventActHeader."Inventory Date");
            VendLedgEntry.SetRange("Vendor Posting Group", "Posting Group");
            if Category = Category::Debts then
                VendLedgEntry.SetRange(Positive, true)
            else
                VendLedgEntry.SetRange(Positive, false);
            VendLedgEntry.FilterGroup(0);
            VendLedgEntry.SetRange("Date Filter", 0D, InventActHeader."Inventory Date");
            Clear(VendLedgEntries);
            VendLedgEntries.SetTableView(VendLedgEntry);
            VendLedgEntries.RunModal();
        end;
    end;
}

