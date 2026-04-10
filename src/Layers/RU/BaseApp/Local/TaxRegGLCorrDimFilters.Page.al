#pragma warning disable AA0247
page 17288 "Tax Reg G/L Corr. Dim. Filters"
{
    Caption = 'Tax Reg G/L Corr. Dim. Filters';
    PageType = Worksheet;
    SourceTable = "Tax Reg. G/L Corr. Dim. Filter";

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
                    ToolTip = 'Specifies the filter group associated with this filter.';
                }
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension code associated with this filter.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupDimension(Text));
                    end;
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value that the data is filtered by.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                        DimensionValueList: Page "Dimension Value List";
                    begin
                        DimensionValue.FilterGroup(2);
                        DimensionValue.SetRange("Dimension Code", Rec."Dimension Code");
                        DimensionValue.FilterGroup(0);
                        DimensionValueList.SetTableView(DimensionValue);
                        DimensionValueList.LookupMode(true);
                        if not (DimensionValueList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := DimensionValueList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension name associated with this filter.';
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
        TaxRegisterName: Record "Tax Register";

    [Scope('OnPrem')]
    procedure LookupDimension(var Text: Text[1024]): Boolean
    var
        Dimension: Record Dimension;
        DimCodeFilter: Code[250];
    begin
        TaxRegisterName.Get(Rec."Section Code", Rec."Tax Register No.");
        if TaxRegisterName."G/L Corr. Analysis View Code" <> '' then begin
            GLCorrAnalysisView.Get(TaxRegisterName."G/L Corr. Analysis View Code");
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

