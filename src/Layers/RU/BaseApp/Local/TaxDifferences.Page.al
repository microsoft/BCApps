#pragma warning disable AA0247
page 17300 "Tax Differences"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Differences';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Difference";
    UsageCategory = Lists;

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
                    ToolTip = 'Specifies an identifying income or expense code that defines the source of the tax difference.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the tax difference code.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference represents Income or Expense for your organization.';
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference amount is a Constant or Temporary.';
                }
                field("Calculation Mode"; Rec."Calculation Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference balance is calculated.';
                }
                field("Calc. Norm Jurisdiction Code"; Rec."Calc. Norm Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a tax jurisdiction code that is used to calculate taxable profits and losses for the tax period.';
                }
                field("Calc. Norm Code"; Rec."Calc. Norm Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an income or expense code that is used to calculate taxable profits and losses for the tax difference.';
                }
                field("Tax Period Limited"; Rec."Tax Period Limited")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference period is temporary and limited by a contract or legal requirements.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting group that is used for tax difference amounts.';
                }
                field("Norm Jurisdiction Code"; Rec."Norm Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the norm jurisdiction that is used to calculate taxable profits and losses for the tax difference.';
                }
                field("Norm Code"; Rec."Norm Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an income or expense code that is used to calculate taxable profits and losses for the tax period.';
                }
                field("Tax Amount"; Rec."Tax Amount")
                {
                    ToolTip = 'Specifies the tax difference amount that is calculated for the tax period.';
                    Visible = false;
                }
                field("Source Code Mandatory"; Rec."Source Code Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the source code is a required component for calculating tax differences.';
                }
                field("Depreciation Bonus"; Rec."Depreciation Bonus")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference amount is reported as a fixed asset depreciation bonus.';
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
            group("Tax Difference")
            {
                Caption = 'Tax Difference';
                action("Tax Diff. Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Diff. Ledger Entries';
                    Image = LedgerEntries;
                    RunObject = Page "Tax Diff. Ledger Entries";
                    RunPageLink = "Tax Diff. Code" = field(Code);
                    RunPageView = sorting("Tax Diff. Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View entries resulting from posting variations in tax amounts caused by the different rules for recognizing income and expenses between entries for book accounting and tax accounting.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

