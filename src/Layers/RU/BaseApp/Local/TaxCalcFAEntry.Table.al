#pragma warning disable AA0247
table 17318 "Tax Calc. FA Entry"
{
    Caption = 'Tax Calc. FA Entry';
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
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(6; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            TableRelation = "Fixed Asset";
        }
        field(10; "Depreciation Group"; Code[10])
        {
            Caption = 'Depreciation Group';
            Editable = false;
        }
        field(11; "Belonging to Manufacturing"; Option)
        {
            Caption = 'Belonging to Manufacturing';
            Editable = false;
            OptionCaption = ' ,Production,Nonproduction';
            OptionMembers = " ",Production,Nonproduction;
        }
        field(12; "FA Type"; Option)
        {
            Caption = 'FA Type';
            Editable = false;
            OptionCaption = 'Fixed Asset,Intangible Asset,Future Expense';
            OptionMembers = "Fixed Asset","Intangible Asset","Future Expense";
        }
        field(15; "Where Used Register IDs"; Code[61])
        {
            Caption = 'Where Used Register IDs';
            Description = 'FlowFilter !!';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(40; "Depreciation Book Code (Base)"; Code[10])
        {
            Caption = 'Depreciation Book Code (Base)';
            TableRelation = "Depreciation Book".Code;
        }
        field(41; "Acquisition Cost (Base)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code (Base)"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const("Acquisition Cost"),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Acquisition Cost (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; "Depreciation Method (Base)"; Enum "FA Depreciation Method")
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Method" where("FA No." = field("FA No."),
                                                                                     "Depreciation Book Code" = field("Depreciation Book Code (Base)")));
            Caption = 'Depreciation Method (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "No. of Depr. Months (Base)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = lookup("FA Depreciation Book"."No. of Depreciation Months" where("FA No." = field("FA No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code (Base)")));
            Caption = 'No. of Depr. Months (Base)';
            DecimalPlaces = 2 : 8;
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "Acquisition Date (Base)"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Acquisition Date" where("FA No." = field("FA No."),
                                                                                  "Depreciation Book Code" = field("Depreciation Book Code (Base)")));
            Caption = 'Acquisition Date (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; "Depr. Starting Date (Base)"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Starting Date" where("FA No." = field("FA No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code (Base)")));
            Caption = 'Depr. Starting Date (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Depreciation Amount (Base)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code (Base)"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field("Date Filter")));
            Caption = 'Depreciation Amount (Base)';
            FieldClass = FlowField;
        }
        field(48; "Depr. Ending Date (Base)"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Ending Date" where("FA No." = field("FA No."),
                                                                                          "Depreciation Book Code" = field("Depreciation Book Code (Base)")));
            Caption = 'Depr. Ending Date (Base)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; "Total Depr. Amount (Base)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code (Base)"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Total Depr. Amount (Base)';
            DecimalPlaces = 2 : 8;
            FieldClass = FlowField;
            MinValue = 0;
        }
        field(50; "Depreciation Book Code (Tax)"; Code[10])
        {
            Caption = 'Depreciation Book Code (Tax)';
            TableRelation = "Depreciation Book".Code;
        }
        field(51; "Acquisition Cost (Tax)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code (Tax)"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const("Acquisition Cost"),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Acquisition Cost (Tax)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; Disposed; Boolean)
        {
            Caption = 'Disposed';
        }
        field(53; "Depreciation Method (Tax)"; Enum "FA Depreciation Method")
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Method" where("FA No." = field("FA No."),
                                                                                     "Depreciation Book Code" = field("Depreciation Book Code (Tax)"),
                                                                                     "Acquisition Date" = field(upperlimit("Date Filter"))));
            Caption = 'Depreciation Method (Tax)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "No. of Depr. Months (Tax)"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = lookup("FA Depreciation Book"."No. of Depreciation Months" where("FA No." = field("FA No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code (Tax)")));
            Caption = 'No. of Depr. Months (Tax)';
            DecimalPlaces = 2 : 8;
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "Acquisition Date (Tax)"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Acquisition Date" where("FA No." = field("FA No."),
                                                                                  "Depreciation Book Code" = field("Depreciation Book Code (Tax)")));
            Caption = 'Acquisition Date (Tax)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Depr. Starting Date (Tax)"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Starting Date" where("FA No." = field("FA No."),
                                                                                            "Depreciation Book Code" = field("Depreciation Book Code (Tax)")));
            Caption = 'Depr. Starting Date (Tax)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Depreciation Amount (Tax)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code (Tax)"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field("Date Filter")));
            Caption = 'Depreciation Amount (Tax)';
            FieldClass = FlowField;
        }
        field(58; "Depr. Ending Date (Tax)"; Date)
        {
            CalcFormula = lookup("FA Depreciation Book"."Depreciation Ending Date" where("FA No." = field("FA No."),
                                                                                          "Depreciation Book Code" = field("Depreciation Book Code (Tax)")));
            Caption = 'Depr. Ending Date (Tax)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Total Depr. Amount (Tax)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                              "Depreciation Book Code" = field("Depreciation Book Code (Tax)"),
                                                              "FA Posting Category" = const(" "),
                                                              "FA Posting Type" = const(Depreciation),
                                                              "FA Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Total Depr. Amount (Tax)';
            DecimalPlaces = 2 : 8;
            FieldClass = FlowField;
            MinValue = 0;
        }
        field(60; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(91; "Depr. Group Elimination"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = - sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                               "Depreciation Book Code" = field("Depreciation Book Code (Tax)"),
                                                               "FA Posting Category" = const(" "),
                                                               "FA Posting Type" = const("Gain/Loss"),
                                                               "FA Posting Date" = field(upperlimit("Date Filter")),
                                                               "Depr. Group Elimination" = const(true)));
            Caption = 'Depr. Group Elimination';
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

    [Scope('OnPrem')]
    procedure ObjectName(): Text[100]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if FixedAsset.Get("FA No.") then
            exit(FixedAsset.Description);
    end;

    [Scope('OnPrem')]
    procedure GetMonthYear(): Text[30]
    begin
        if "Ending Date" <> 0D then
            exit(Format("Ending Date", 0, '<Month Text> <Year4>'));
    end;

    [Scope('OnPrem')]
    procedure SetFieldFilter(FieldNumber: Integer; TypeField: Option SumFields,CalcFields) FieldInList: Boolean
    begin
        case TypeField of
            TypeField::SumFields:
                FieldInList :=
                  FieldNumber in [FieldNo("Total Depr. Amount (Base)"),
                                  FieldNo("Total Depr. Amount (Tax)"),
                                  FieldNo("Depreciation Amount (Base)"),
                                  FieldNo("Depreciation Amount (Tax)"),
                                  FieldNo("Depr. Group Elimination")];
            TypeField::CalcFields:
                FieldInList := FieldNumber = -1;
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
        if TaxRegName.FindSet() then
            if TaxRegName.Next() = 0 then
                exit(TaxRegName.Description);
    end;
}

