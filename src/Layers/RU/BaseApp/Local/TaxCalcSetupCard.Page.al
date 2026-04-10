#pragma warning disable AA0247
page 17311 "Tax Calc. Setup Card"
{
    Caption = 'Tax Calc. Setup Card';
    DataCaptionExpression = Rec."No." + ' ' + Rec.Description;
    Description = '"No."+'' ''+COPYSTR(Description,1,30-STRLEN("No."))';
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Tax Calc. Header";

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
                    ToolTip = 'Specifies the register ID associated with the tax calculation header.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax calculation header.';
                }
                field(Check; Rec.Check)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'This field is used internally.';
                }
                field("Used in Statutory Report"; Rec."Used in Statutory Report")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax calculation header is used in statutory reports.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the parent/child relationship between the tax registers associated with the tax calculation header.';
                }
                field("Tax Diff. Code"; Rec."Tax Diff. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences code associated with the tax calculation header.';
                }
                field("G/L Corr. Analysis View Code"; Rec."G/L Corr. Analysis View Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger corresponding analysis view code.';
                }
            }
            part(CalcTemplSubform; "Tax Calc. Line Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              Code = field("No.");
                Visible = CalcTemplSubformVisible;
            }
            part(EntrySubform; "Tax Calc. Select Setup Subf")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              "Register No." = field("No.");
                Visible = EntrySubformVisible;
            }
            part(TemplateFASubf; "Tax Calc. Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              Code = field("No.");
                Visible = TemplateFASubfVisible;
            }
            part(EntrTemplSubform; "Tax Calc. Line Select Subf")
            {
                ApplicationArea = All;
                SubPageLink = "Section Code" = field("Section Code"),
                              Code = field("No.");
                Visible = EntrTemplSubformVisible;
            }
            group(Objects)
            {
                Caption = 'Objects';
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the table ID associated with the tax calculation header.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the form ID associated with the tax calculation header.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the table name associated with the tax calculation header.';
                }
                field("Form Name"; Rec."Form Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the form name associated with the tax calculation header.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Register)
            {
                Caption = 'Register';
                Image = Register;
                action("Show Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Data';
                    Image = ShowMatrix;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = false;
                    RunObject = Page "Tax Calc. Accumulation";
                    RunPageLink = "Section Code" = field("Section Code"),
                                  "No." = field("No.");
                    ToolTip = 'View the related details.';
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Check Links")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check Links';
                    Image = CheckList;

                    trigger OnAction()
                    begin
                        TaxRegTermMgt.CheckTaxRegLink(false, Rec."Section Code", DATABASE::"Tax Calc. Line");
                    end;
                }
            }
        }
        area(Promoted)
        {
        }
    }

    trigger OnAfterGetRecord()
    begin
        case true of
            Rec."Table ID" = DATABASE::"Tax Calc. FA Entry":
                begin
                    EntrySubformVisible := false;
                    EntrTemplSubformVisible := false;
                    CalcTemplSubformVisible := false;
                    TemplateFASubfVisible := true;
                end;
            Rec."Storing Method" = Rec."Storing Method"::"Build Entry":
                begin
                    CalcTemplSubformVisible := false;
                    TemplateFASubfVisible := false;
                    EntrySubformVisible := true;
                    EntrTemplSubformVisible := true;
                end;
            else begin
                EntrySubformVisible := false;
                EntrTemplSubformVisible := false;
                TemplateFASubfVisible := false;
                CalcTemplSubformVisible := true;
            end;
        end;
    end;

    trigger OnInit()
    begin
        TemplateFASubfVisible := true;
        CalcTemplSubformVisible := true;
        EntrTemplSubformVisible := true;
        EntrySubformVisible := true;
    end;

    var
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        EntrySubformVisible: Boolean;
        EntrTemplSubformVisible: Boolean;
        CalcTemplSubformVisible: Boolean;
        TemplateFASubfVisible: Boolean;
}

