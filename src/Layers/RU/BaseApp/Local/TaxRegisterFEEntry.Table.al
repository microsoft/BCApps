#pragma warning disable AA0247
table 17213 "Tax Register FE Entry"
{
    Caption = 'Tax Register FE Entry';
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
        field(3; "FE No."; Code[20])
        {
            Caption = 'FE No.';
            TableRelation = "Fixed Asset";
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
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
        field(60; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book".Code;
        }
        field(61; "Acquisition Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FE No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const("Acquisition Cost"),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Acquisition Cost';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Valuation Changes"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FE No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = filter("Write-Down" | Appreciation),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Valuation Changes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "No. of Depreciation Months"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = lookup("FA Depreciation Book"."No. of Depreciation Months" where("FA No." = field("FE No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'No. of Depreciation Months';
            DecimalPlaces = 2 : 8;
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Acquisition Date"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Acquisition Date" where("FA No." = field("FE No."),
                                                                                  "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'Acquisition Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(71; "Depreciation Starting Date"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Starting Date" where("FA No." = field("FE No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'Depreciation Starting Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Depreciation Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FE No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field("Date Filter")));
            Caption = 'Depreciation Amount';
            FieldClass = FlowField;
        }
        field(74; "Depreciation Ending Date"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Ending Date" where("FA No." = field("FE No."),
                                                                                          "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'Depreciation Ending Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Book Value Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FE No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "Part of Book Value" = const(true),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Book Value Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(89; "Total Depreciation Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FE No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Total Depreciation Amount';
            DecimalPlaces = 2 : 8;
            FieldClass = FlowField;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Starting Date")
        {
        }
        key(Key3; "Section Code", "Ending Date")
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
        FixedAsset: Record "Fixed Asset";
    begin
        if FixedAsset.Get("FE No.") then
            exit(FixedAsset.Description);
    end;

    [Scope('OnPrem')]
    procedure CalcQtyMonthsUsefulLife(): Integer
    begin
        CalcFields("Depreciation Starting Date");
        if ("Depreciation Starting Date" = 0D) or
           ("Depreciation Starting Date" > "Ending Date")
        then begin
            CalcFields("No. of Depreciation Months");
            exit("No. of Depreciation Months");
        end;
        exit(
          ((Date2DMY("Ending Date" + 1, 3) * 12) + Date2DMY("Ending Date" + 1, 2)) -
          ((Date2DMY("Depreciation Starting Date", 3) * 12) + Date2DMY("Depreciation Starting Date", 2))
          );
    end;

    [Scope('OnPrem')]
    procedure SetFieldFilter(FieldNumber: Integer) FieldInList: Boolean
    begin
        FieldInList :=
          FieldNumber in [
                          FieldNo("Depreciation Amount"),
                          FieldNo("Acquisition Cost"),
                          FieldNo("Valuation Changes")
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
        Rec.FilterGroup(0);
        if TaxRegName.Find('-') then
            if TaxRegName.Next(1) = 0 then
                exit(TaxRegName.Description);
    end;
}

