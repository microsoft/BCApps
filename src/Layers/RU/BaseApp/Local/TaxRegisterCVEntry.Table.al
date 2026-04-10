#pragma warning disable AA0247
table 17210 "Tax Register CV Entry"
{
    Caption = 'Tax Register CV Entry';
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
        field(3; "C/V No."; Code[20])
        {
            Caption = 'C/V No.';
            TableRelation = if ("Object Type" = const(Vendor)) Vendor
            else
            if ("Object Type" = const(Customer)) Customer;
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
        field(17; "Register Type"; Option)
        {
            Caption = 'Register Type';
            OptionCaption = ' ,Credit Balance,Debit Balance';
            OptionMembers = " ","Credit Balance","Debit Balance";
        }
        field(38; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(50; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(111; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = ' ,Vendor,Customer';
            OptionMembers = " ",Vendor,Customer;
        }
        field(179; "CV Debit Balance Amnt 2-4"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'CV Debit Balance Amnt 2-4';
        }
        field(180; "CV Credit Balance Amnt 1"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'CV Credit Balance Amnt 1';
        }
        field(181; "CV Credit Balance Amnt 2"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'CV Credit Balance Amnt 2';
        }
        field(182; "CV Debit Balance Amnt 1"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'CV Debit Balance Amnt 1';
        }
        field(183; "CV Debit Balance Amnt 2"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'CV Debit Balance Amnt 2';
        }
        field(184; "CV Debit Balance Amnt 3"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'CV Debit Balance Amnt 3';
        }
        field(185; "CV Debit Balance Amnt 4"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'CV Debit Balance Amnt 4';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Ending Date", "Object Type")
        {
        }
        key(Key3; "Section Code", "Starting Date", "Object Type")
        {
        }
        key(Key4; "Section Code", "Register Type", "Ending Date")
        {
        }
    }

    fieldgroups
    {
    }

    var

    [Scope('OnPrem')]
    procedure ObjectName(): Text[100]
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        case "Object Type" of
            "Object Type"::Customer:
                if Cust.Get("C/V No.") then
                    exit(Cust.Name);
            "Object Type"::Vendor:
                if Vend.Get("C/V No.") then
                    exit(Vend.Name);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFieldFilter(FieldNumber: Integer) FieldInList: Boolean
    begin
        FieldInList :=
          FieldNumber in [
                          FieldNo("CV Credit Balance Amnt 1"),
                          FieldNo("CV Credit Balance Amnt 2"),
                          FieldNo("CV Debit Balance Amnt 1"),
                          FieldNo("CV Debit Balance Amnt 2-4"),
                          FieldNo("CV Debit Balance Amnt 2"),
                          FieldNo("CV Debit Balance Amnt 3"),
                          FieldNo("CV Debit Balance Amnt 4")
                          ];
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

    [Scope('OnPrem')]
    procedure DrillDownCVLedgerAmount(FilterDueDate: Text[30]; PositiveEntry: Boolean; OnlyOpen: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        TaxCustomerLedgerEntries: Page "Tax Customer Ledger Entries";
        TaxVendorLedgerEntries: Page "Tax Vendor Ledger Entries";
    begin
        case "Object Type" of
            "Object Type"::Vendor:
                begin
                    Clear(TaxVendorLedgerEntries);
                    if OnlyOpen then begin
                        VendLedgEntry.Reset();
                        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
                        VendLedgEntry.SetRange("Vendor No.", "C/V No.");
                        VendLedgEntry.SetRange(Positive, PositiveEntry);
                        VendLedgEntry.SetFilter("Due Date", FilterDueDate);
                        VendLedgEntry.SetFilter("Date Filter", GetFilter("Date Filter"));
                        VendLedgEntry.SetFilter("Remaining Amt. (LCY)", '<>0');
                        TaxVendorLedgerEntries.SetTableView(VendLedgEntry);
                    end else
                        TaxVendorLedgerEntries.BuildTmpVendLedgerEntry(
                          "C/V No.", CalcDate('<-CY>', GetRangeMax("Date Filter")), GetRangeMax("Date Filter"), FilterDueDate, PositiveEntry);
                    TaxVendorLedgerEntries.RunModal();
                end;
            "Object Type"::Customer:
                begin
                    Clear(TaxCustomerLedgerEntries);
                    if OnlyOpen then begin
                        CustLedgEntry.Reset();
                        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
                        CustLedgEntry.SetRange("Customer No.", "C/V No.");
                        CustLedgEntry.SetRange(Positive, PositiveEntry);
                        CustLedgEntry.SetFilter("Due Date", FilterDueDate);
                        CustLedgEntry.SetFilter("Date Filter", GetFilter("Date Filter"));
                        CustLedgEntry.SetFilter("Remaining Amt. (LCY)", '<>0');
                        TaxCustomerLedgerEntries.SetTableView(CustLedgEntry);
                    end else
                        TaxCustomerLedgerEntries.BuildTmpCustLedgerEntry(
                          "C/V No.", CalcDate('<-CY>', GetRangeMax("Date Filter")), GetRangeMax("Date Filter"), FilterDueDate, PositiveEntry);
                    TaxCustomerLedgerEntries.RunModal();
                end;
        end;
    end;
}

