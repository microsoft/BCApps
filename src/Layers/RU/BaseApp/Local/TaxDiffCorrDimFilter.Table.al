#pragma warning disable AA0247
table 17322 "Tax Diff. Corr. Dim. Filter"
{
    Caption = 'Tax Diff. Corr. Dim. Filter';
    LookupPageID = "Tax Dif G/L Corr. Dim. Filters";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Section";
        }
        field(2; "Tax Calc. No."; Code[10])
        {
            Caption = 'Tax Calc. No.';
            NotBlank = true;
            TableRelation = "Tax Calc. Header"."No." where("Section Code" = field("Section Code"));
        }
        field(3; Define; Option)
        {
            Caption = 'Define';
            OptionCaption = 'Template,Entry Setup';
            OptionMembers = Template,"Entry Setup";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Filter Group"; Option)
        {
            Caption = 'Filter Group';
            OptionCaption = 'Debit,Credit';
            OptionMembers = Debit,Credit;
        }
        field(6; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnLookup()
            begin
                Dimension.Reset();
                Dimension.FilterGroup(2);
                FilterGroup(2);
                CopyFilter("Dimension Code", Dimension.Code);
                Dimension.FilterGroup(0);
                FilterGroup(0);
                if ACTION::LookupOK = PAGE.RunModal(0, Dimension) then
                    "Dimension Code" := Dimension.Code;
            end;
        }
        field(7; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
            ValidateTableRelation = false;
        }
        field(10; "Dimension Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Filter")));
            Caption = 'Dimension Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Tax Calc. No.", Define, "Line No.", "Filter Group", "Dimension Code")
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
    end;

    trigger OnInsert()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    trigger OnModify()
    begin
        if "Dimension Value Filter" <> xRec."Dimension Value Filter" then begin
            TaxRegSection.Get("Section Code");
            TaxRegSection.ValidateChangeDeclaration();
        end;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Dimension: Record Dimension;
        TaxRegSection: Record "Tax Register Section";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure TaxRegDescription(): Text[250]
    var
        TaxCalcHeader: Record "Tax Calc. Header";
    begin
        if TaxCalcHeader.Get("Section Code", "Tax Calc. No.") then
            exit(TaxCalcHeader.Description);
    end;
}

