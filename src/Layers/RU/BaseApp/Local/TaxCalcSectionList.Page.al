#pragma warning disable AA0247
page 17309 "Tax Calc. Section List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Calculation Sections';
    CardPageID = "Tax Calc. Section Card";
    Editable = false;
    PageType = List;
    SourceTable = "Tax Calc. Section";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the tax calculation section.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax calculation section code description associated with the tax calculation section.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the tax calculation section.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date associated with the tax calculation section.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date associated with the tax calculation section.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Registers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Registers';
                Image = Register;
                RunObject = Page "Tax Calc. List";
                RunPageLink = "Section Code" = field(Code);
                ToolTip = 'View all related tax entries. Every register shows the first and last entry number of its entries.';
            }
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Create Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Registers';
                    Ellipsis = true;
                    Image = CalculateLines;

                    trigger OnAction()
                    var
                        CreateTaxCalc: Report "Create Tax Calculation";
                    begin
                        CurrPage.SetSelectionFilter(TaxCalcSection);
                        CreateTaxCalc.SetPeriodStart(
                          TaxCalcMgt.GetNextAvailableBeginDate(Rec.Code, DATABASE::"Tax Calc. Accumulation", true));
                        CreateTaxCalc.SetTableView(TaxCalcSection);
                        CreateTaxCalc.RunModal();
                    end;
                }
                separator(Action1210009)
                {
                }
                action("Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Settings';
                    Ellipsis = true;
                    Image = ExportFile;
                    ToolTip = 'Export the setup information.';

                    trigger OnAction()
                    begin
                        TaxCalcSection := Rec;
                        TaxCalcSection.SetRecFilter();
                        Rec.ExportSettings(TaxCalcSection);
                    end;
                }
                action("Import Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Settings';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import setup information.';

                    trigger OnAction()
                    begin
                        Rec.ValidateChange();
                        Rec.PromptImportSettings();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Registers_Promoted; Registers)
                {
                }
            }
        }
    }

    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
}

