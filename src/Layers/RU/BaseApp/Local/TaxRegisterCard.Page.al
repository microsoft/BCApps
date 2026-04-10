#pragma warning disable AA0247
page 17203 "Tax Register Card"
{
    Caption = 'Tax Register Card';
    DataCaptionExpression = Rec."No." + ' ' + Rec.Description;
    Description = '"No."+'' ''+Description';
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Tax Register";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Register ID"; Rec."Register ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the register identifier of the tax register name.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the tax register name.';
                }
                field(Check; Rec.Check)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the tax register name will be printed on reports.';
                }
                field("Used in Statutory Report"; Rec."Used in Statutory Report")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax register name will be used in a statutory report.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the level associated with the tax register name.';
                }
                field("Costing Method"; Rec."Costing Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the costing method associated with the tax register name.';
                }
                field("G/L Corr. Analysis View Code"; Rec."G/L Corr. Analysis View Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger corresponding analysis view code associated with the tax register name.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
            part(TaxRegFATemplateSubform; "Tax Reg. FA Template Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              Code = field("No.");
                Visible = TaxRegFATemplateSubformVisible;
            }
            part(TaxRegLineSubform; "Tax Register Line Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              "Tax Register No." = field("No.");
                Visible = TaxRegLineSubformVisible;
            }
            part(TaxRegCalcTemplSubform; "Tax Register Calc. Templ. Subf")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              Code = field("No.");
                Visible = TaxRegCalcTemplSubformVisible;
            }
            part(TaxRegTemplateSubform; "Tax Register Template Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              Code = field("No.");
                Visible = TaxRegTemplateSubformVisible;
            }
            part(TaxRegEntryTemplSubform; "Tax Register Entr. Templ. Subf")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              Code = field("No.");
                Visible = TaxRegEntryTemplSubformVisible;
            }
            group(Objects)
            {
                Caption = 'Objects';
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the table identifier of the tax register name.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the form identifier of the tax register name.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the table name associated with the tax register.';
                }
                field("Page Name"; Rec."Page Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the form name associated with the tax register name.';
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
            action("Show Data")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Data';
                Image = ShowMatrix;
                RunObject = Page "Tax Register Accumulation";
                RunPageLink = "Section Code" = field("Section Code"),
                              "No." = field("No.");
                ToolTip = 'View the related details.';
            }
            action("Check Links")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Links';
                Image = CheckList;

                trigger OnAction()
                begin
                    TaxRegTermMgt.CheckTaxRegLink(false, Rec."Section Code", DATABASE::"Tax Register Template");
                end;
            }
            action("Show Entries")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Entries';
                Image = Entries;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                //PromotedIsBig = false;

                trigger OnAction()
                begin
                    if Rec."Page ID" <> 0 then
                        CheckPageID();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Data_Promoted"; "Show Data")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TaxRegLineSubformVisible := false;
        TaxRegEntryTemplSubformVisible := false;
        TaxRegCalcTemplSubformVisible := false;
        TaxRegTemplateSubformVisible := false;
        TaxRegFATemplateSubformVisible := false;
        TaxRegPayrollTemplateSubformVisible := false;
        TaxRegPayrollLineSubformVisible := false;

        case true of
            Rec."Table ID" = DATABASE::"Tax Register CV Entry",
          Rec."Table ID" = DATABASE::"Tax Register FE Entry":
                TaxRegTemplateSubformVisible := true;
            Rec."Table ID" = DATABASE::"Tax Register FA Entry":
                TaxRegFATemplateSubformVisible := true;
            Rec."Storing Method" = Rec."Storing Method"::"Build Entry":
                begin
                    TaxRegLineSubformVisible := true;
                    TaxRegEntryTemplSubformVisible := true;
                end;
            else
                TaxRegCalcTemplSubformVisible := true;
        end;
    end;

    trigger OnInit()
    begin
        TaxRegPayrollLineSubformVisible := true;
        TaxRegPayrollTemplateSubformVisible := true;
        TaxRegFATemplateSubformVisible := true;
        TaxRegTemplateSubformVisible := true;
        TaxRegCalcTemplSubformVisible := true;
        TaxRegEntryTemplSubformVisible := true;
        TaxRegLineSubformVisible := true;
    end;

    var
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        TaxRegLineSubformVisible: Boolean;
        TaxRegEntryTemplSubformVisible: Boolean;
        TaxRegCalcTemplSubformVisible: Boolean;
        TaxRegTemplateSubformVisible: Boolean;
        TaxRegFATemplateSubformVisible: Boolean;
        TaxRegPayrollTemplateSubformVisible: Boolean;
        TaxRegPayrollLineSubformVisible: Boolean;

    [Scope('OnPrem')]
    procedure CheckPageID()
    var
        TaxRegAccumulEntry: Record "Tax Register Accumulation";
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegFEEntry: Record "Tax Register FE Entry";
    begin
        case Rec."Table ID" of
            DATABASE::"Tax Register Accumulation":
                begin
                    TaxRegAccumulEntry.FilterGroup := 2;
                    TaxRegAccumulEntry.SetRange("Section Code", Rec."Section Code");
                    TaxRegAccumulEntry.FilterGroup := 0;
                    PAGE.RunModal(Rec."Page ID", TaxRegAccumulEntry);
                end;
            DATABASE::"Tax Register G/L Entry":
                begin
                    TaxRegGLEntry.FilterGroup := 2;
                    TaxRegGLEntry.SetRange("Section Code", Rec."Section Code");
                    TaxRegGLEntry.FilterGroup := 0;
                    PAGE.RunModal(Rec."Page ID", TaxRegGLEntry);
                end;
            DATABASE::"Tax Register CV Entry":
                begin
                    TaxRegCVEntry.FilterGroup := 2;
                    TaxRegCVEntry.SetRange("Section Code", Rec."Section Code");
                    TaxRegCVEntry.FilterGroup := 0;
                    PAGE.RunModal(Rec."Page ID", TaxRegCVEntry);
                end;
            DATABASE::"Tax Register FA Entry":
                begin
                    TaxRegFAEntry.FilterGroup := 2;
                    TaxRegFAEntry.SetRange("Section Code", Rec."Section Code");
                    TaxRegFAEntry.FilterGroup := 0;
                    PAGE.RunModal(Rec."Page ID", TaxRegFAEntry);
                end;
            DATABASE::"Tax Register Item Entry":
                begin
                    TaxRegItemEntry.FilterGroup := 2;
                    TaxRegItemEntry.SetRange("Section Code", Rec."Section Code");
                    TaxRegItemEntry.FilterGroup := 0;
                    PAGE.RunModal(Rec."Page ID", TaxRegItemEntry);
                end;
            DATABASE::"Tax Register FE Entry":
                begin
                    TaxRegFEEntry.FilterGroup := 2;
                    TaxRegFEEntry.SetRange("Section Code", Rec."Section Code");
                    TaxRegFEEntry.FilterGroup := 0;
                    PAGE.RunModal(Rec."Page ID", TaxRegFEEntry);
                end;
        end;
    end;
}

