#pragma warning disable AA0247
table 14941 "G/L Corr. Analysis View Filter"
{
    Caption = 'G/L Corr. Analysis View Filter';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Corr. Analysis View Code"; Code[10])
        {
            Caption = 'G/L Corr. Analysis View Code';
            NotBlank = true;
            TableRelation = "G/L Corr. Analysis View";
        }
        field(2; "Filter Group"; Option)
        {
            Caption = 'Filter Group';
            OptionCaption = 'Debit,Credit';
            OptionMembers = Debit,Credit;
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;
        }
        field(4; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "G/L Corr. Analysis View Code", "Filter Group", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewFilter: Record "G/L Corr. Analysis View Filter";
    begin
        GLCorrAnalysisView.Get("G/L Corr. Analysis View Code");
        GLCorrAnalysisView.TestField(Blocked, false);
        GLCorrAnalysisView.ValidateDelete(GLCorrAnalysisViewFilter.FieldCaption("Dimension Code"));
        GLCorrAnalysisView.AnalysisViewReset();
        GLCorrAnalysisView.Modify();
    end;

    trigger OnInsert()
    begin
        ValidateModifyFilter();
    end;

    trigger OnModify()
    begin
        ValidateModifyFilter();
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ValidateModifyFilter()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewFilter: Record "G/L Corr. Analysis View Filter";
    begin
        GLCorrAnalysisView.Get("G/L Corr. Analysis View Code");
        GLCorrAnalysisView.TestField(Blocked, false);
        if (GLCorrAnalysisView."Last Entry No." <> 0) and
           (xRec."Dimension Code" <> "Dimension Code")
        then begin
            GLCorrAnalysisView.ValidateDelete(GLCorrAnalysisViewFilter.FieldCaption("Dimension Code"));
            GLCorrAnalysisView.AnalysisViewReset();
            GLCorrAnalysisView.Modify();
            "Dimension Value Filter" := '';
        end;

        if (GLCorrAnalysisView."Last Entry No." <> 0) and
           (xRec."Dimension Value Filter" <> "Dimension Value Filter")
        then begin
            GLCorrAnalysisView.ValidateDelete(GLCorrAnalysisViewFilter.FieldCaption("Dimension Value Filter"));
            GLCorrAnalysisView.AnalysisViewReset();
            GLCorrAnalysisView.Modify();
        end;
    end;
}

