#pragma warning disable AA0247
page 17308 "Tax Calc. Section Card"
{
    Caption = 'Tax Calc. Section Card';
    PageType = Card;
    SourceTable = "Tax Calc. Section";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
                field("Last G/L Entries Date"; Rec."Last G/L Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the last general ledger entry associated with the tax calculation section.';
                }
                field("Last Item Entries Date"; Rec."Last Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the last item entry associated with the tax calculation section.';
                }
                field("Last FA Entries Date"; Rec."Last FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the last fixed asset entry associated with the tax calculation section.';
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
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was last updated.';
                }
                field("No G/L Entries Date"; Rec."No G/L Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger entry date associated with the tax calculation section.';
                }
                field("No Item Entries Date"; Rec."No Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item entry date associated with the tax calculation section.';
                }
                field("No FA Entries Date"; Rec."No FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset entry date associated with the tax calculation section.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 4 Code"; Rec."Dimension 4 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
            }
            group(System)
            {
                Caption = 'System';
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies the type associated with the tax differences ledger entry.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the form ID associated with the tax calculation section.';
                }
                field("Page Name"; Rec."Page Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the form name associated with the tax calculation section.';
                }
                field("Norm Jurisdiction Code"; Rec."Norm Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the norm jurisdiction code associated with the tax differences ledger entry.';
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
        area(navigation)
        {
            group(Registers)
            {
                Caption = 'Registers';
                action(Action129)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Registers';
                    Image = Register;
                    RunObject = Page "Tax Calc. List";
                    RunPageLink = "Section Code" = field(Code);
                    ShortCutKey = 'Shift+Ctrl+L';
                    ToolTip = 'View all related tax entries. Every register shows the first and last entry number of its entries.';
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Copy Section")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Section';
                    Ellipsis = true;
                    Image = Copy;

                    trigger OnAction()
                    var
                        CopyTaxCalcSection: Report "Copy Tax Calc. Section";
                    begin
                        Clear(CopyTaxCalcSection);
                        TaxCalcSection := Rec;
                        TaxCalcSection.SetRecFilter();
                        CopyTaxCalcSection.SetTableView(TaxCalcSection);
                        CopyTaxCalcSection.RunModal();
                        CurrPage.Update(false);
                    end;
                }
                separator(Action1210004)
                {
                }
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
                        TaxCalcSection := Rec;
                        TaxCalcSection.SetRecFilter();
                        CreateTaxCalc.SetPeriodStart(
                          TaxCalcMgt.GetNextAvailableBeginDate(Rec.Code, DATABASE::"Tax Calc. Accumulation", true));
                        CreateTaxCalc.SetTableView(TaxCalcSection);
                        CreateTaxCalc.RunModal();
                    end;
                }
                action("Clear Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Registers';
                    Image = ClearLog;

                    trigger OnAction()
                    begin
                        Rec.ValidateChange();
                    end;
                }
                separator(Action1210001)
                {
                }
                action("Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Settings';
                    Ellipsis = true;
                    Image = ExportFile;

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

                actionref(Action129_Promoted; Action129)
                {
                }
            }
        }
    }

    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
}

