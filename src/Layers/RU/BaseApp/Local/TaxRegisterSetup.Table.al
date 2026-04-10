#pragma warning disable AA0247
table 17236 "Tax Register Setup"
{
    Caption = 'Tax Register Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Condition Dimension Code"; Code[20])
        {
            Caption = 'Condition Dimension Code';
            TableRelation = Dimension;
        }
        field(3; "Kind Dimension Code"; Code[20])
        {
            Caption = 'Kind Dimension Code';
            TableRelation = Dimension;
        }
        field(4; "Create Acquis. FA Tax Ledger"; Boolean)
        {
            Caption = 'Create Acquis. FA Tax Ledger';

            trigger OnValidate()
            begin
                if "Create Acquis. FA Tax Ledger" = false then begin
                    "Create Reclass. FA Tax Ledger" := false;
                    "Create Disposal FA Tax Ledger" := false;
                end else
                    if "Tax Depreciation Book" <> '' then begin
                        DepreciationBook.Get("Tax Depreciation Book");
                        DepreciationBook.TestField("G/L Integration - Acq. Cost", false);
                    end;
            end;
        }
        field(5; "Tax Depreciation Book"; Code[10])
        {
            Caption = 'Tax Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(6; "Create Reclass. FA Tax Ledger"; Boolean)
        {
            Caption = 'Create Reclass. FA Tax Ledger';
        }
        field(7; "Create Disposal FA Tax Ledger"; Boolean)
        {
            Caption = 'Create Disposal FA Tax Ledger';

            trigger OnValidate()
            begin
                TestField("Use Group Depr. Method from", 0D);
                if "Create Disposal FA Tax Ledger" then
                    if "Tax Depreciation Book" <> '' then begin
                        DepreciationBook.Get("Tax Depreciation Book");
                        DepreciationBook.TestField("G/L Integration - Disposal", false);
                    end;
            end;
        }
        field(8; "Create Acquis. FE Tax Ledger"; Boolean)
        {
            Caption = 'Create Acquis. FE Tax Ledger';
        }
        field(12400; "Sales VAT Ledg. Template Code"; Code[10])
        {
            Caption = 'Sales VAT Ledg. Template Code';
            TableRelation = "Excel Template";
        }
        field(12401; "Sales Add. Sheet Templ. Code"; Code[10])
        {
            Caption = 'Sales Add. Sheet Templ. Code';
            TableRelation = "Excel Template";
        }
        field(12402; "Purch. VAT Ledg. Template Code"; Code[10])
        {
            Caption = 'Purch. VAT Ledg. Template Code';
            TableRelation = "Excel Template";
        }
        field(12403; "Purch. Add. Sheet Templ. Code"; Code[10])
        {
            Caption = 'Purch. Add. Sheet Templ. Code';
            TableRelation = "Excel Template";
        }
        field(12404; "VAT Iss./Rcvd. Jnl. Templ Code"; Code[10])
        {
            Caption = 'VAT Iss./Rcvd. Jnl. Templ Code';
            TableRelation = "Excel Template";
        }
        field(12405; "Tax Register Template Code"; Code[10])
        {
            Caption = 'Tax Register Template Code';
            TableRelation = "Excel Template";
        }
        field(17200; "Future Exp. Depreciation Book"; Code[10])
        {
            Caption = 'Future Exp. Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(17201; "Rel. Act as Depr. Bonus Base"; Boolean)
        {
            Caption = 'Rel. Act as Depr. Bonus Base';
        }
        field(17202; "Default Depr. Bonus %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default Depr. Bonus %';
            MaxValue = 100;
            MinValue = 0;
        }
        field(17214; "Use Group Depr. Method from"; Date)
        {
            Caption = 'Use Group Depr. Method from';

            trigger OnValidate()
            begin
                if "Use Group Depr. Method from" <> 0D then begin
                    if (Date2DMY("Use Group Depr. Method from", 1) <> 1) or
                       (Date2DMY("Use Group Depr. Method from", 2) <> 1)
                    then
                        Error(Text001, FieldCaption("Use Group Depr. Method from"));
                    TestField("Calculate TD for each FA", false);
                    DepreciationBook.Reset();
                    DepreciationBook.SetRange("Control FA Acquis. Cost", true);
                    if DepreciationBook.FindFirst() then
                        DepreciationBook.FieldError("Control FA Acquis. Cost");
                end else begin
                    "Min. Group Balance" := 0;
                    "Write-off in Charges" := false;
                end;
            end;
        }
        field(17215; "Min. Group Balance"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Min. Group Balance';
            MinValue = 0;
        }
        field(17216; "Write-off in Charges"; Boolean)
        {
            Caption = 'Write-off in Charges';
            InitValue = true;
        }
        field(17218; "Calculate TD for each FA"; Boolean)
        {
            Caption = 'Calculate TD for each FA';

            trigger OnValidate()
            begin
                if "Calculate TD for each FA" then
                    TestField("Use Group Depr. Method from", 0D);
            end;
        }
        field(17220; "Depr. Bonus TD Code"; Code[10])
        {
            Caption = 'Depr. Bonus TD Code';
            TableRelation = "Tax Difference" where(Type = const(Temporary),
                                                    "Depreciation Bonus" = const(true));
        }
        field(17222; "Default FA TD Code"; Code[10])
        {
            Caption = 'Default FA TD Code';
            TableRelation = "Tax Difference" where("Source Code Mandatory" = const(true),
                                                    "Depreciation Bonus" = const(false));
        }
        field(17223; "Depr. Bonus Recovery from"; Date)
        {
            Caption = 'Depr. Bonus Recovery from';
        }
        field(17224; "Depr. Bonus Recov. Per. (Year)"; Integer)
        {
            Caption = 'Depr. Bonus Recov. Per. (Year)';
            MinValue = 1;
        }
        field(17225; "Disposal TD Code"; Code[10])
        {
            Caption = 'Disposal TD Code';
            TableRelation = "Tax Difference" where("Source Code Mandatory" = const(true),
                                                    "Depreciation Bonus" = const(false),
                                                    Type = const(Constant));
        }
        field(17226; "Depr. Bonus Recovery TD Code"; Code[10])
        {
            Caption = 'Depr. Bonus Recovery TD Code';
            TableRelation = "Tax Difference" where("Source Code Mandatory" = const(true),
                                                    "Depreciation Bonus" = const(false),
                                                    Type = const(Constant));
        }
        field(17227; "Create Data for Printing Forms"; Boolean)
        {
            Caption = 'Create Data for Printing Forms';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TaxRegTemplate.GenerateProfile();
        TaxRegTermName.GenerateProfile();
    end;

    trigger OnModify()
    begin
        TaxRegTemplate.GenerateProfile();
        TaxRegTermName.GenerateProfile();
    end;

    var
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegTermName: Record "Tax Register Term";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Only 1 of January can be specified in the %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DepreciationBook: Record "Depreciation Book";

    [Scope('OnPrem')]
    procedure GetDimCode(Type: Option Condition,Kind) DimCode: Code[20]
    begin
        Get();
        case Type of
            Type::Condition:
                begin
                    TestField("Condition Dimension Code");
                    DimCode := "Condition Dimension Code";
                end;
            Type::Kind:
                begin
                    TestField("Kind Dimension Code");
                    DimCode := "Kind Dimension Code";
                end;
        end;
    end;
}

