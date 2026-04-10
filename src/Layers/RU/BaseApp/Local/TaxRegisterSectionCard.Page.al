#pragma warning disable AA0247
page 17219 "Tax Register Section Card"
{
    Caption = 'Tax Register Section Card';
    PageType = Card;
    SourceTable = "Tax Register Section";

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
                    ToolTip = 'Specifies the code associated with the tax register section.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax register section.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status associated with the tax register section.';
                }
                field("Last GL Entries Date"; Rec."Last GL Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last general ledger entry date for the tax register section.';
                }
                field("Last CV Entries Date"; Rec."Last CV Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last creditor or debtor entry date for the tax register section.';
                }
                field("Last Item Entries Date"; Rec."Last Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last item entry date for the tax register section.';
                }
                field("Last FA Entries Date"; Rec."Last FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last fixed asset entry date for the tax register section.';
                }
                field("Last FE Entries Date"; Rec."Last FE Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last future expenses entry date for the tax register section.';
                }
                field("Last PR Entries Date"; Rec."Last PR Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last payroll entry date for the tax register section.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date associated with the tax register section.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date associated with the tax register section.';
                }
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was last updated.';
                }
                field("Absence GL Entries Date"; Rec."Absence GL Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when general ledger entries were not available for the tax register section.';
                }
                field("Absence CV Entries Date"; Rec."Absence CV Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when credit or debtor entries were not available for the tax register section.';
                }
                field("Absence Item Entries Date"; Rec."Absence Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when item entries were not available for the tax register section.';
                }
                field("Absence FA Entries Date"; Rec."Absence FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when fixed asset entries were not available for the tax register section.';
                }
                field("Absence FE Entries Date"; Rec."Absence FE Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when future expense entries were not available for the tax register section.';
                }
                field("Absence PR Entries Date"; Rec."Absence PR Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when payroll entries were not available for the tax register section.';
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensions';
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
                field("Dimension 4 Code"; Rec."Dimension 4 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies one of the four dimensions that you can include in an analysis view.';
                }
            }
            group(Balance)
            {
                Caption = 'Balance';
                field("Debit Balance Point 1"; Rec."Debit Balance Point 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
                field("Debit Balance Point 2"; Rec."Debit Balance Point 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
                field("Debit Balance Point 3"; Rec."Debit Balance Point 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
                field("Credit Balance Point 1"; Rec."Credit Balance Point 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deadlines for debtor and creditor liabilities that are applied in accordance with the current taxation period.';
                }
            }
            group(System)
            {
                Caption = 'System';
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type associated with the tax register section.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the form identifier associated with the tax register section.';
                }
                field("Page Name"; Rec."Page Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the form name associated with the tax register section.';
                }
                field("Norm Jurisdiction Code"; Rec."Norm Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the norm jurisdiction that is used to calculate taxable profits and losses for the tax difference.';
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
            action(Registers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Registers';
                Image = Register;
                RunObject = Page "Tax Register Worksheet";
                RunPageLink = "Section Code" = field(Code);
                ShortCutKey = 'Shift+Ctrl+L';
                ToolTip = 'View all related tax entries. Every register shows the first and last entry number of its entries.';
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
                    Image = CopyBudget;

                    trigger OnAction()
                    var
                        CopyTaxRegSection: Report "Copy Tax Register Section";
                    begin
                        Clear(CopyTaxRegSection);
                        TaxRegSection.SetRange(Code, Rec.Code);
                        CopyTaxRegSection.SetTableView(TaxRegSection);
                        CopyTaxRegSection.RunModal();
                        Clear(CopyTaxRegSection);
                    end;
                }
                separator(Action19)
                {
                }
                action("Create Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Registers';
                    Ellipsis = true;
                    Image = CalculateLines;

                    trigger OnAction()
                    begin
                        TaxRegSection.SetRange(Code, Rec.Code);
                        REPORT.Run(REPORT::"Create Tax Registers", true, true, TaxRegSection);
                    end;
                }
                action("Clear Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Registers';
                    Image = ClearLog;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        Rec.ValidateChangeDeclaration();
                    end;
                }
                separator(Action1210000)
                {
                }
                action("Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Settings';
                    Ellipsis = true;
                    Image = ExportFile;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        TaxRegSection.SetRange(Code, Rec.Code);
                        Rec.ExportSettings(TaxRegSection);
                    end;
                }
                action("Import Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Settings';
                    Ellipsis = true;
                    Image = Import;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'Import setup information.';

                    trigger OnAction()
                    begin
                        Rec.ValidateChangeDeclaration();
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

                actionref("Create Registers_Promoted"; "Create Registers")
                {
                }
                actionref(Registers_Promoted; Registers)
                {
                }
            }
        }
    }

    var
        TaxRegSection: Record "Tax Register Section";
}

