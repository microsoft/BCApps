#pragma warning disable AA0247
table 17218 "Tax Register Dim. Filter"
{
    Caption = 'Tax Register Dim. Filter';
    LookupPageID = "Tax Reg Dimension Filters";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Register Section";
        }
        field(2; "Tax Register No."; Code[10])
        {
            Caption = 'Tax Register No.';
            NotBlank = true;
            TableRelation = "Tax Register"."No.";
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
        field(5; "Dimension Code"; Code[20])
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
        field(6; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
            ValidateTableRelation = false;
        }
        field(7; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(8; "If No Value"; Option)
        {
            Caption = 'If No Value';
            OptionCaption = 'Ignore,Skip,Confirm,Error';
            OptionMembers = Ignore,Skip,Confirm,Error;

            trigger OnValidate()
            begin
                if Define = Define::Template then
                    "If No Value" := "If No Value"::Ignore;
            end;
        }
        field(9; "Dimension Name"; Text[50])
        {
            CalcFormula = lookup(Dimension.Name where(Code = field("Dimension Code")));
            Caption = 'Dimension Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Tax Register No.", Define, "Line No.", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Section Code", "Entry No.")
        {
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

        TaxRegDimFilter.SetCurrentKey("Section Code", "Entry No.");
        TaxRegDimFilter.SetRange("Section Code", "Section Code");
        if TaxRegDimFilter.FindLast() then
            "Entry No." := TaxRegDimFilter."Entry No." + 1
        else
            "Entry No." := 1;
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
        Error(Text1001, TableCaption);
    end;

    var
        Dimension: Record Dimension;
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'You can''t rename an %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxRegSection: Record "Tax Register Section";

    [Scope('OnPrem')]
    procedure TaxRegDescription(): Text[250]
    var
        TaxRegName: Record "Tax Register";
    begin
        if TaxRegName.Get("Section Code", "Tax Register No.") then
            exit(TaxRegName.Description);
    end;
}

