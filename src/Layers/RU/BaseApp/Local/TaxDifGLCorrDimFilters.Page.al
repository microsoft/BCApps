#pragma warning disable AA0247
page 17335 "Tax Dif G/L Corr. Dim. Filters"
{
    Caption = 'Tax Dif G/L Corr. Dim. Filters';
    PageType = Worksheet;
    SourceTable = "Tax Diff. Corr. Dim. Filter";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Filter Group"; Rec."Filter Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the filter group of the tax differences general ledger dimension filter.';
                }
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension code associated with the tax differences general ledger dimension filter.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupDimension(Text));
                    end;
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value that the data is filtered by.';
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension name associated with the tax differences general ledger dimension filter.';
                }
            }
        }
    }

    actions
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        TaxCalcHeader: Record "Tax Calc. Header";

    [Scope('OnPrem')]
    procedure LookupDimension(var Text: Text[1024]): Boolean
    var
        Dimension: Record Dimension;
        DimCodeFilter: Code[250];
    begin
        TaxCalcHeader.Get(Rec."Section Code", Rec."Tax Calc. No.");
        if TaxCalcHeader."G/L Corr. Analysis View Code" <> '' then begin
            GLCorrAnalysisView.Get(TaxCalcHeader."G/L Corr. Analysis View Code");
            case Rec."Filter Group" of
                Rec."Filter Group"::Debit:
                    begin
                        AddValue2Fiter(GLCorrAnalysisView."Debit Dimension 1 Code", DimCodeFilter);
                        AddValue2Fiter(GLCorrAnalysisView."Debit Dimension 2 Code", DimCodeFilter);
                        AddValue2Fiter(GLCorrAnalysisView."Debit Dimension 3 Code", DimCodeFilter);
                    end;
                Rec."Filter Group"::Credit:
                    begin
                        AddValue2Fiter(GLCorrAnalysisView."Credit Dimension 1 Code", DimCodeFilter);
                        AddValue2Fiter(GLCorrAnalysisView."Credit Dimension 2 Code", DimCodeFilter);
                        AddValue2Fiter(GLCorrAnalysisView."Credit Dimension 3 Code", DimCodeFilter);
                    end;
            end;
        end else begin
            GLSetup.Get();
            AddValue2Fiter(GLSetup."Global Dimension 1 Code", DimCodeFilter);
            AddValue2Fiter(GLSetup."Global Dimension 2 Code", DimCodeFilter);
        end;

        Dimension.FilterGroup(2);
        if DimCodeFilter <> '' then
            Dimension.SetFilter(Code, DimCodeFilter);
        Dimension.FilterGroup(0);
        if PAGE.RunModal(0, Dimension) = ACTION::LookupOK then begin
            Text := Dimension.Code;
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure AddValue2Fiter(DimCode: Code[20]; var DimCodeFilter: Code[250])
    begin
        if DimCode <> '' then
            if DimCodeFilter = '' then
                DimCodeFilter := DimCode
            else
                DimCodeFilter := DimCodeFilter + '|' + DimCode;
    end;
}

