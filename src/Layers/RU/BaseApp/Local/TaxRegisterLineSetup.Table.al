#pragma warning disable AA0247
table 17201 "Tax Register Line Setup"
{
    Caption = 'Tax Register Line Setup';
    LookupPageID = "Tax Register Line List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tax Register No."; Code[10])
        {
            Caption = 'Tax Register No.';
            TableRelation = "Tax Register"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Correspondence,G/L Account';
            OptionMembers = Correspondence,"G/L Account";

            trigger OnValidate()
            begin
                if "Check Exist Entry" <> "Check Exist Entry"::" " then
                    if "Account Type" <> "Account Type"::"G/L Account" then
                        FieldError("Account Type",
                          StrSubstNo(Text21000903, "Account Type", "Check Exist Entry"));

                if "Account Type" <> xRec."Account Type" then
                    case "Account Type" of
                        "Account Type"::Correspondence:
                            TestField("Amount Type", "Amount Type"::"Net Change");
                        "Account Type"::"G/L Account":
                            TestField("Bal. Account No.", '');
                    end;
            end;
        }
        field(6; "Account No."; Code[100])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = false;
        }
        field(7; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            InitValue = "Net Change";
            OptionCaption = 'Debit,Credit,Net Change';
            OptionMembers = Debit,Credit,"Net Change";

            trigger OnValidate()
            var
                SaveAccountNo: Code[100];
            begin
                if "Check Exist Entry" <> "Check Exist Entry"::" " then
                    if "Amount Type" = "Amount Type"::"Net Change" then
                        FieldError("Amount Type",
                          StrSubstNo(Text21000903, "Amount Type", "Check Exist Entry"));
                if "Amount Type" <> xRec."Amount Type" then begin
                    if ("Account Type" = "Account Type"::Correspondence) and
                       ("Amount Type" = "Amount Type"::Credit) and
                       (("Account No." <> '') or ("Bal. Account No." <> ''))
                    then
                        if Confirm(Text21000900, true) then begin
                            SaveAccountNo := "Bal. Account No.";
                            "Bal. Account No." := "Account No.";
                            "Account No." := SaveAccountNo;
                        end;
                    case "Amount Type" of
                        "Amount Type"::Debit,
                      "Amount Type"::Credit:
                            TestField("Account Type", "Account Type"::"G/L Account");
                    end;
                end;
            end;
        }
        field(8; "Bal. Account No."; Code[100])
        {
            Caption = 'Bal. Account No.';
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if ("Bal. Account No." <> xRec."Bal. Account No.") and ("Bal. Account No." <> '') then
                    TestField("Account Type", "Account Type"::Correspondence);
            end;
        }
        field(11; "Check Exist Entry"; Option)
        {
            Caption = 'Check Exist Entry';
            OptionCaption = ' ,Item,Payroll';
            OptionMembers = " ",Item,Payroll;

            trigger OnValidate()
            begin
                if "Check Exist Entry" = "Check Exist Entry"::Item then begin
                    TaxReg.Get("Section Code", "Tax Register No.");
                    if TaxReg."Table ID" <> DATABASE::"Tax Register Item Entry" then
                        FieldError("Check Exist Entry",
                          StrSubstNo(Text21000901, "Check Exist Entry", ItemlLedgEntry.TableCaption()));
                    "Account Type" := "Account Type"::"G/L Account";
                    if "Amount Type" > "Amount Type"::Credit then
                        "Amount Type" := "Amount Type"::Debit;
                    "Bal. Account No." := '';
                    "Payroll Source" := "Payroll Source"::" ";
                end;
            end;
        }
        field(12; "Line Code"; Code[10])
        {
            Caption = 'Line Code';
        }
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Register Section";
        }
        field(14; "Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Register Dim. Filter" where("Section Code" = field("Section Code"),
                                                                  "Tax Register No." = field("Tax Register No."),
                                                                  Define = const("Entry Setup"),
                                                                  "Line No." = field("Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "G/L Corr. Dimensions Filters"; Boolean)
        {
            CalcFormula = exist("Tax Reg. G/L Corr. Dim. Filter" where("Section Code" = field("Section Code"),
                                                                        "Tax Register No." = field("Tax Register No."),
                                                                        "Line No." = field("Line No."),
                                                                        Define = const("Entry Setup")));
            Caption = 'G/L Corr. Dimensions Filters';
            FieldClass = FlowField;
        }
        field(20; "Payroll Source"; Option)
        {
            Caption = 'Payroll Source';
            Editable = false;
            FieldClass = FlowFilter;
            OptionCaption = ' ,Cost,Profit,FSI,FOSI';
            OptionMembers = " ",Cost,Profit,FSI,FOSI;
        }
        field(23; "Employee Statistics Group Code"; Code[80])
        {
            Caption = 'Employee Statistics Group Code';
            TableRelation = "Employee Statistics Group";
            ValidateTableRelation = false;
        }
        field(24; "Employee Category Code"; Code[80])
        {
            Caption = 'Employee Category Code';
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
        field(25; "Payroll Posting Group"; Code[80])
        {
            Caption = 'Payroll Posting Group';
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Tax Register No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();

        TaxRegDimFilter.SetRange("Section Code", "Section Code");
        TaxRegDimFilter.SetRange("Tax Register No.", "Tax Register No.");
        TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::"Entry Setup");
        TaxRegDimFilter.SetRange("Line No.", "Line No.");
        TaxRegDimFilter.DeleteAll(true);

        TaxRegDimComb.SetRange("Section Code", "Section Code");
        TaxRegDimComb.SetRange("Tax Register No.", "Tax Register No.");
        TaxRegDimComb.SetRange("Line No.", "Line No.");
        TaxRegDimComb.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    trigger OnModify()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    var
        TaxRegSection: Record "Tax Register Section";
#pragma warning disable AA0074
        Text21000900: Label 'Exchange Account No. and Bal. Account No.?';
#pragma warning restore AA0074
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        ItemlLedgEntry: Record "Item Ledger Entry";
        TaxReg: Record "Tax Register";
        TaxRegDimComb: Record "Tax Register Dim. Comb.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000901: Label 'cannot be %1 if register is not linked to %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000903: Label 'cannot be %1 if Check Exist Entry =%2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure GetGLCorrDimFilter(DimCode: Code[20]; FilterGroup: Option Debit,Credit) DimFilter: Text[250]
    var
        TaxRegGLCorrDimFilter: Record "Tax Reg. G/L Corr. Dim. Filter";
    begin
        if TaxRegGLCorrDimFilter.Get("Section Code", "Tax Register No.", 1, "Line No.", FilterGroup, DimCode) then
            DimFilter := TaxRegGLCorrDimFilter."Dimension Value Filter";
    end;
}

