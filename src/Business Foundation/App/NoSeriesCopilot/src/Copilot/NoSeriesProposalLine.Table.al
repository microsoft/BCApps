table 392 "No. Series Proposal Line"
{
    TableType = Temporary;
    fields
    {
        field(1; "Proposal No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
        }

        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Starting No."; Code[20])
        {
            Caption = 'Starting No.';
            trigger OnValidate()
            begin
                UpdateProposalNoSeriesLine(Rec.FieldNo("Starting No."));
            end;
        }
        field(6; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';

            trigger OnValidate()
            begin
                UpdateProposalNoSeriesLine(Rec.FieldNo("Ending No."));
            end;
        }
        field(7; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';

            trigger OnValidate()
            begin
                UpdateProposalNoSeriesLine(Rec.FieldNo("Warning No."));
            end;
        }
        field(8; "Increment-by No."; Integer)
        {
            Caption = 'Increment-by No.';
        }
        field(9; "Setup Table No."; Integer)
        {
            Caption = 'Setup Table No.';
        }
        field(10; "Setup Field No."; Integer)
        {
            Caption = 'Setup Field No.';
        }
    }

    keys
    {
        key(PK; "Proposal No.", "Series Code")
        {
            Clustered = true;
        }
    }

    local procedure UpdateProposalNoSeriesLine(ChangedField: Integer)
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        Initialize(TempNoSeriesLine);

        case ChangedField of
            Rec.FieldNo("Starting No."):
                TempNoSeriesLine.Validate("Starting No.", Rec."Starting No.");
            Rec.FieldNo("Ending No."):
                TempNoSeriesLine.Validate("Ending No.", Rec."Ending No.");
            Rec.FieldNo("Warning No."):
                TempNoSeriesLine.Validate("Warning No.", Rec."Warning No.");
        end;

        ApplyChanges(TempNoSeriesLine);
    end;

    local procedure Initialize(var TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        TempNoSeriesLine.Init();
        TempNoSeriesLine."Series Code" := Rec."Series Code";
        TempNoSeriesLine."Starting No." := Rec."Starting No.";
        TempNoSeriesLine."Ending No." := Rec."Ending No.";
        TempNoSeriesLine."Warning No." := Rec."Warning No.";
        TempNoSeriesLine."Increment-by No." := Rec."Increment-by No.";
        TempNoSeriesLine.Insert()
    end;

    local procedure ApplyChanges(var TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        Rec."Starting No." := TempNoSeriesLine."Starting No.";
        Rec."Ending No." := TempNoSeriesLine."Ending No.";
        Rec."Warning No." := TempNoSeriesLine."Warning No.";
    end;
}