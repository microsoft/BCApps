#pragma warning disable AA0247
page 17247 "Tax Register Norm Groups"
{
    Caption = 'Norm Groups';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Register Norm Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the norm group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code description associated with the norm group.';
                }
                field("Has Details"; Rec."Has Details")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    HideValue = HasDetailsHideValue;
                    ToolTip = 'Specifies if the norm jurisdiction group has details.';
                }
                field("Search Detail"; Rec."Search Detail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the search detail associated with the norm group.';
                }
                field("Storing Method"; Rec."Storing Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the norm jurisdiction is calculated with a specific formula.';
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
            group("&Group")
            {
                Caption = '&Group';
                Image = Group;
                action(Details)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Details';
                    Image = ViewDetails;

                    trigger OnAction()
                    begin
                        ShowDetails();
                    end;
                }
                action("Template Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Template Setup';
                    Image = Setup;

                    trigger OnAction()
                    begin
                        SetupCalculationNorm();
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Calculate Details")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate Details';
                    Image = CalculateLines;
                    ToolTip = 'Create norm jurisdiction details. Norm details are used to define a constant tax rate for the norm.';

                    trigger OnAction()
                    begin
                        CalculateDetails();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Calculate Details_Promoted"; "Calculate Details")
                {
                }
                actionref(Details_Promoted; Details)
                {
                }
                actionref("Template Setup_Promoted"; "Template Setup")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        HasDetailsHideValue := false;
        HasDetailsOnFormat(Format(Rec."Has Details"));
    end;

    var
#pragma warning disable AA0074
        Text1000: Label 'Nothing to calculate';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1001: Label 'Present';
#pragma warning restore AA0074
        HasDetailsHideValue: Boolean;

    [Scope('OnPrem')]
    procedure CalculateDetails()
    var
        NormJurisdiction: Record "Tax Register Norm Jurisdiction";
        NormGroup: Record "Tax Register Norm Group";
    begin
        CurrPage.SaveRecord();
        Commit();
        NormGroup.SetRange("Norm Jurisdiction Code", Rec."Norm Jurisdiction Code");
        NormGroup.SetRange("Storing Method", Rec."Storing Method"::Calculation);
        if not NormGroup.FindFirst() then
            Error(Text1000);
        NormJurisdiction.FilterGroup(2);
        NormJurisdiction.SetRange(Code, Rec."Norm Jurisdiction Code");
        NormJurisdiction.FilterGroup(0);
        NormJurisdiction.SetRange(Code, Rec."Norm Jurisdiction Code");
        REPORT.RunModal(REPORT::"Create Norm Details", true, true, NormJurisdiction);
    end;

    [Scope('OnPrem')]
    procedure ShowDetails()
    var
        NormDetail: Record "Tax Register Norm Detail";
    begin
        NormDetail.FilterGroup(2);
        NormDetail.SetRange("Norm Jurisdiction Code", Rec."Norm Jurisdiction Code");
        NormDetail.SetRange("Norm Group Code", Rec.Code);
        NormDetail.FilterGroup(0);
        if Rec."Storing Method" = Rec."Storing Method"::" " then
            PAGE.RunModal(0, NormDetail)
        else
            PAGE.RunModal(PAGE::"Tax Reg. Norm Details (Calc)", NormDetail);
    end;

    [Scope('OnPrem')]
    procedure SetupCalculationNorm()
    var
        NormTemplateLine: Record "Tax Reg. Norm Template Line";
    begin
        if Rec."Storing Method" = Rec."Storing Method"::" " then
            exit;
        NormTemplateLine.FilterGroup(2);
        NormTemplateLine.SetRange("Norm Jurisdiction Code", Rec."Norm Jurisdiction Code");
        NormTemplateLine.SetRange("Norm Group Code", Rec.Code);
        NormTemplateLine.FilterGroup(0);
        PAGE.Run(PAGE::"Tax Reg. Norm Template Setup", NormTemplateLine);
    end;

    local procedure HasDetailsOnFormat(Text: Text[1024])
    begin
        if Rec."Has Details" then
            Text := Text1001
        else
            HasDetailsHideValue := true;
    end;
}

