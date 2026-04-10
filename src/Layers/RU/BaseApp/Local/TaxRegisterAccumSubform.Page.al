#pragma warning disable AA0247
page 17210 "Tax Register Accum. Subform"
{
    Caption = 'Lines';
    DataCaptionFields = "Tax Register No.";
    Editable = false;
    PageType = ListPart;
    SourceTable = "Tax Register Accumulation";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Template Line Code"; Rec."Template Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the template line code associated with the tax register accumulation.';
                }
                field("Report Line Code"; Rec."Report Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report line code associated with the tax register accumulation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax register accumulation.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount associated with the tax register accumulation.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownAmount();
                    end;
                }
                field("Dimensions Filters"; Rec."Dimensions Filters")
                {
                    ToolTip = 'Specifies the dimension that the data is filtered by.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        DimensionsFilters();
                    end;
                }
            }
            group(Register)
            {
                Caption = 'Register';
                Image = Register;
                action(Entries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries';
                    Image = Entries;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the entries for the tax register.';

                    trigger OnAction()
                    begin
                        ShowTaxRegEntries();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    var
        TaxReg: Record "Tax Register";
        DescriptionIndent: Integer;

    local procedure ShowTaxRegEntries()
    var
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        TaxRegFEEntry: Record "Tax Register FE Entry";
    begin
        TaxReg.Get(Rec."Section Code", Rec."Tax Register No.");
        if (TaxReg."Page ID" = 0) or (TaxReg."Table ID" = 0) or
           (TaxReg."Storing Method" = TaxReg."Storing Method"::Calculation)
        then
            exit;

        case TaxReg."Table ID" of
            DATABASE::"Tax Register G/L Entry":
                begin
                    TaxRegGLEntry.SetFilter("Where Used Register IDs", '*~' + TaxReg."Register ID" + '~*');
                    PAGE.RunModal(TaxReg."Page ID", TaxRegGLEntry);
                end;
            DATABASE::"Tax Register CV Entry":
                begin
                    TaxRegCVEntry.SetFilter("Where Used Register IDs", '*~' + TaxReg."Register ID" + '~*');
                    PAGE.RunModal(TaxReg."Page ID", TaxRegCVEntry);
                end;
            DATABASE::"Tax Register Item Entry":
                begin
                    TaxRegItemEntry.SetFilter("Where Used Register IDs", '*~' + TaxReg."Register ID" + '~*');
                    PAGE.RunModal(TaxReg."Page ID", TaxRegItemEntry);
                end;
            DATABASE::"Tax Register FA Entry":
                begin
                    TaxRegFAEntry.SetFilter("Where Used Register IDs", '*~' + TaxReg."Register ID" + '~*');
                    PAGE.RunModal(TaxReg."Page ID", TaxRegFAEntry);
                end;
            DATABASE::"Tax Register FE Entry":
                begin
                    TaxRegFEEntry.SetFilter("Where Used Register IDs", '*~' + TaxReg."Register ID" + '~*');
                    PAGE.RunModal(TaxReg."Page ID", TaxRegFEEntry);
                end;
        end;
    end;

    local procedure DimensionsFilters()
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        Rec.CalcFields("Dimensions Filters");
        if Rec."Dimensions Filters" then begin
            TaxRegDimFilter.FilterGroup(2);
            TaxRegDimFilter.SetRange("Section Code", Rec."Section Code");
            TaxRegDimFilter.SetRange("Tax Register No.", Rec."Tax Register No.");
            TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
            TaxRegDimFilter.FilterGroup(0);
            TaxRegDimFilter.SetRange("Line No.", Rec."Template Line No.");
            PAGE.RunModal(0, TaxRegDimFilter);
        end;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Indentation;
    end;

    [Scope('OnPrem')]
    procedure UpdatePage(NewDateFilter: Text[80])
    begin
        Rec.FilterGroup(4);
        Rec.SetFilter("Date Filter", NewDateFilter);
        Rec.SetFilter("Ending Date", NewDateFilter);
        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;
}

