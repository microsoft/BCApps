#pragma warning disable AA0247
table 17303 "Tax Diff. Journal Template"
{
    Caption = 'Tax Diff. Journal Template';
    LookupPageID = "Tax Diff. Jnl. Template List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        field(9; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'General';
            OptionMembers = General;

            trigger OnValidate()
            begin
                SourceCodeSetup.Get();
                case Type of
                    Type::General:
                        begin
                            "Source Code" := SourceCodeSetup."Tax Difference Journal";
                            "Page ID" := PAGE::"Tax Difference Journal";
                        end;
                end;
            end;
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                TaxDiffJnlLine.SetRange("Journal Template Name", Name);
                TaxDiffJnlLine.ModifyAll("Source Code", "Source Code");
                Modify();
            end;
        }
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(16; "Page Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxDiffJnlLine.SetRange("Journal Template Name", Name);
        TaxDiffJnlLine.DeleteAll(true);
        TaxDiffJnlBatch.SetRange("Journal Template Name", Name);
        TaxDiffJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
}

