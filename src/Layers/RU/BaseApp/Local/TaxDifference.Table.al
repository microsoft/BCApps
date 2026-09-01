#pragma warning disable AA0247
table 17300 "Tax Difference"
{
    Caption = 'Tax Difference';
    LookupPageID = "Tax Differences";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; Category; Option)
        {
            Caption = 'Category';
            OptionCaption = 'Expense,Income';
            OptionMembers = Expense,Income;
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Constant,Temporary';
            OptionMembers = Constant,"Temporary";
        }
        field(7; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            TableRelation = "Tax Register Norm Jurisdiction".Code;
        }
        field(8; "Norm Code"; Code[10])
        {
            Caption = 'Norm Code';
            TableRelation = "Tax Register Norm Group".Code where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"));
        }
        field(9; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = "Tax Diff. Posting Group";
        }
        field(10; "Tax Period Limited"; Option)
        {
            Caption = 'Tax Period Limited';
            OptionCaption = ' ,Year';
            OptionMembers = " ",Year;
        }
        field(11; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Tax Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            CalcFormula = sum("Tax Diff. Ledger Entry"."Tax Amount" where("Tax Diff. Code" = field(Code),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Tax Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Calculation Mode"; Option)
        {
            Caption = 'Calculation Mode';
            OptionCaption = ' ,Balance';
            OptionMembers = " ",Balance;
        }
        field(14; "Calc. Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Calc. Norm Jurisdiction Code';
            TableRelation = "Tax Register Norm Jurisdiction".Code;
        }
        field(15; "Calc. Norm Code"; Code[10])
        {
            Caption = 'Calc. Norm Code';
            TableRelation = "Tax Register Norm Group".Code where("Norm Jurisdiction Code" = field("Calc. Norm Jurisdiction Code"));

            trigger OnValidate()
            begin
                if "Calc. Norm Code" <> '' then begin
                    TaxDiff.Reset();
                    TaxDiff.SetRange("Calc. Norm Jurisdiction Code", "Calc. Norm Jurisdiction Code");
                    TaxDiff.SetRange("Calc. Norm Code", "Calc. Norm Code");
                    TaxDiff.SetFilter(Code, '<>%1', Code);
                    if TaxDiff.FindFirst() then
                        Error(Text1001,
                          "Calc. Norm Jurisdiction Code", "Calc. Norm Code", TaxDiff.Code);
                end;
            end;
        }
        field(16; "Source Code Mandatory"; Boolean)
        {
            Caption = 'Source Code Mandatory';
        }
        field(17; "Depreciation Bonus"; Boolean)
        {
            Caption = 'Depreciation Bonus';

            trigger OnValidate()
            begin
                TaxDiffLedgerEntry.SetCurrentKey("Tax Diff. Code");
                TaxDiffLedgerEntry.SetRange("Tax Diff. Code", Code);
                if not TaxDiffLedgerEntry.IsEmpty() then
                    Error(Text1002);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    var
        TaxDiff: Record "Tax Difference";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'Norm %1 %2 already used in tax difference %3.', Comment = '%1 = Jurisdiction Code, %2 = Norm Code';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";
#pragma warning disable AA0074
        Text1002: Label 'You cannot change Depreciation Bonus because there is at least one ledger entry for this tax difference.';
#pragma warning restore AA0074
}

