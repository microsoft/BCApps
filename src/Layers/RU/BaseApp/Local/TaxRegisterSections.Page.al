#pragma warning disable AA0247
page 17218 "Tax Register Sections"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Registers';
    CardPageID = "Tax Register Section Card";
    Editable = false;
    PageType = List;
    SourceTable = "Tax Register Section";
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
                    ToolTip = 'Specifies the code associated with the tax register section.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax register section.';
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
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status associated with the tax register section.';
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
                RunObject = Page "Tax Register Worksheet";
                RunPageLink = "Section Code" = field(Code);
                ToolTip = 'View all related tax entries. Every register shows the first and last entry number of its entries.';
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
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
                separator(Action1210008)
                {
                }
                action("&Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export Settings';
                    Ellipsis = true;
                    Image = ExportFile;
                    ToolTip = 'Export an XML file that contains information about the tax register section.';

                    trigger OnAction()
                    begin
                        TaxRegSection.SetRange(Code, Rec.Code);
                        Rec.ExportSettings(TaxRegSection);
                    end;
                }
                action("&Import Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import Settings';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import an XML file that contains settings for tax register sections.';

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

                actionref(Registers_Promoted; Registers)
                {
                }
            }
        }
    }

    var
        TaxRegSection: Record "Tax Register Section";
}

