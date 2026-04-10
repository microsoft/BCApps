#pragma warning disable AA0247
table 17211 "Tax Register FA Entry"
{
    Caption = 'Tax Register FA Entry';
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
        field(3; "FA No."; Code[20])
        {
            Caption = 'FA No.';
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
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
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
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = filter("Write-Down" | Appreciation),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Valuation Changes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Depreciation Group"; Code[10])
        {
            Caption = 'Depreciation Group';
            Editable = false;
        }
        field(64; "Depreciation Method"; Enum "FA Depreciation Method")
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Method" where("FA No." = field("FA No."),
                                                                                     "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'Depreciation Method';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "No. of Depreciation Months"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = lookup("FA Depreciation Book"."No. of Depreciation Months" where("FA No." = field("FA No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'No. of Depreciation Months';
            DecimalPlaces = 2 : 8;
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Acquisition Date"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Acquisition Date" where("FA No." = field("FA No."),
                                                                                  "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'Acquisition Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(67; "Belonging to Manufacturing"; Option)
        {
            Caption = 'Belonging to Manufacturing';
            Editable = false;
            OptionCaption = ' ,Production,Nonproduction';
            OptionMembers = " ",Production,Nonproduction;
        }
        field(71; "Depreciation Starting Date"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Starting Date" where("FA No." = field("FA No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'Depreciation Starting Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Depreciation Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field("Date Filter")));
            Caption = 'Depreciation Amount';
            FieldClass = FlowField;
        }
        field(74; "Depreciation Ending Date"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Ending Date" where("FA No." = field("FA No."),
                                                                                          "Depreciation Book Code" = field("Depreciation Book Code")));
            Caption = 'Depreciation Ending Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(82; "Taken Off Books Date"; Date)
        {
            CalcFormula = lookup("FA Ledger Entry"."Posting Date" where("FA No." = field("FA No."),
                                                                         "Depreciation Book Code" = field("Depreciation Book Code"),
                                                                         "FA Posting Type" = const("Proceeds on Disposal"),
                                                                         "FA Posting Date" = field(filter("Date Filter"))));
            Caption = 'Taken Off Books Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "Taken Off Books Reason"; Text[50])
        {
            CalcFormula = lookup("FA Ledger Entry".Description where("FA No." = field("FA No."),
                                                                      "Depreciation Book Code" = field("Depreciation Book Code"),
                                                                      "FA Posting Type" = const("Proceeds on Disposal"),
                                                                      "Posting Date" = field(filter("Date Filter"))));
            Caption = 'Taken Off Books Reason';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Book Value Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "Part of Book Value" = const(true),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Book Value Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = - sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                               "Depreciation Book Code" = field("Depreciation Book Code"),
                                                               "FA Posting Category" = const(" "),
                                                               "FA Posting Type" = const("Proceeds on Disposal"),
                                                               "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Sales Amount';
            FieldClass = FlowField;
        }
        field(86; "Sales Gain/Loss"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = - sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                               "Depreciation Book Code" = field("Depreciation Book Code"),
                                                               "FA Posting Category" = const(" "),
                                                               "FA Posting Type" = const("Gain/Loss"),
                                                               "FA Posting Date" = field(upperlimit("Date Filter")),
                                                               "Depr. Group Elimination" = const(false)));
            Caption = 'Sales Gain/Loss';
            FieldClass = FlowField;
        }
        field(87; "Sales Original Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = - sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                               "Depreciation Book Code" = field("Depreciation Book Code"),
                                                               "FA Posting Category" = const(Disposal),
                                                               "FA Posting Type" = const("Acquisition Cost"),
                                                               "FA Posting Date" = field(upperlimit("Taken Off Books Date"))));
            Caption = 'Sales Original Amount';
            FieldClass = FlowField;
        }
        field(88; "Sales Depreciation Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(Disposal),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field(upperlimit("Taken Off Books Date"))));
            Caption = 'Sales Depreciation Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(89; "Total Depreciation Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Total Depreciation Amount';
            DecimalPlaces = 2 : 8;
            FieldClass = FlowField;
            MinValue = 0;
        }
        field(90; "FA Type"; Option)
        {
            Caption = 'FA Type';
            Editable = false;
            OptionCaption = 'Fixed Asset,Intangible Asset,Future Expense';
            OptionMembers = "Fixed Asset","Intangible Asset","Future Expense";
        }
        field(91; "Depr. Group Elimination"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = - sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                               "Depreciation Book Code" = field("Depreciation Book Code"),
                                                               "FA Posting Category" = const(" "),
                                                               "FA Posting Type" = const("Gain/Loss"),
                                                               "FA Posting Date" = field(upperlimit("Date Filter")),
                                                               "Depr. Group Elimination" = const(true)));
            Caption = 'Depr. Group Elimination';
            FieldClass = FlowField;
        }
        field(92; "Depreciation Bonus Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field("Date Filter"),
                                                              "Depr. Bonus" = const(true)));
            Caption = 'Depreciation Bonus Amount';
            FieldClass = FlowField;
        }
        field(93; "Depr. Bonus Recovery Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field("Date Filter"),
                                                              "Depr. Bonus" = const(true)));
            Caption = 'Depr. Bonus Recovery Amount';
            FieldClass = FlowField;
        }
        field(94; "Sold FA Qty"; Integer)
        {
            CalcFormula = count("FA Ledger Entry" where("FA No." = field("FA No."),
                                                         "Depreciation Book Code" = field("Depreciation Book Code"),
                                                         "FA Posting Category" = const(" "),
                                                         "FA Posting Type" = const("Proceeds on Disposal"),
                                                         "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Sold FA Qty';
            FieldClass = FlowField;
        }
        field(95; "Acquis. Cost for Released FA"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const("Acquisition Cost"),
                                                              "FA Posting Date" = field(upperlimit("Date Filter")),
                                                              "Reclassification Entry" = const(true),
                                                              Quantity = const(1)));
            Caption = 'Acquis. Cost for Released FA';
            Editable = false;
            FieldClass = FlowField;
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
        if FixedAsset.Get("FA No.") then
            exit(FixedAsset.Description);
    end;

    [Scope('OnPrem')]
    procedure CalcQtyMonthsUsefulLife(): Decimal
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
    procedure GetMonthYear(): Text[30]
    begin
        if "Ending Date" <> 0D then
            exit(Format("Ending Date", 0, '<Month Text> <Year4>'));
    end;

    [Scope('OnPrem')]
    procedure SetFieldFilter(FieldNumber: Integer) FieldInList: Boolean
    begin
        FieldInList :=
          FieldNumber in [
                          FieldNo("Sales Gain/Loss"),
                          FieldNo("Depreciation Amount"),
                          FieldNo("Acquisition Cost"),
                          FieldNo("Sales Amount"),
                          FieldNo("Valuation Changes"),
                          FieldNo("Depr. Group Elimination"),
                          FieldNo("Depreciation Bonus Amount"),
                          FieldNo("Depr. Bonus Recovery Amount"),
                          FieldNo("Acquis. Cost for Released FA"),
                          FieldNo("Sold FA Qty")
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
            if TaxRegName.Next() = 0 then
                exit(TaxRegName.Description);
    end;
}

