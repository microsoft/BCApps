page 6378 "Activation List"
{
    ApplicationArea = All;
    Caption = 'Activations';
    PageType = List;
    SourceTable = "Activation Header";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'Activation ID';
                    ToolTip = 'Activation ID';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Company Name field.';
                }
                field("Company Id"; Rec."Company Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Company Id field.';
                }
                field(Identifier; Rec.Identifier)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Identifier field.';
                }
                field("Is Active ID"; Rec."Is Active ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Is Active ID field.';
                }
                field(Jurisdiction; Rec.Jurisdiction)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Jurisdiction field.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status Code field.';
                }
                field("Status Message"; Rec."Status Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status Message field.';
                }
                field("Last Modified"; Rec."Last Modified")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Last Modified field.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Refresh Data")

            {
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Executes the Refresh Data action.';
                trigger OnAction()

                begin
                    GetRegistrations();
                end;
            }

            action("View Details")
            {
                ApplicationArea = All;
                Image = ViewDetails;
                ToolTip = 'Executes the View Details action.';
                trigger OnAction()
                var
                    ActivationMandate: Record "Activation Mandate";
                begin
                    ActivationMandate.SetRange("Activation ID", Rec.ID);
                    if ActivationMandate.FindFirst() then
                        Error('No Mandate found!');

                    Page.RunModal(Page::"Activation Card", ActivationMandate);
                end;
            }
        }
    }

    local procedure GetRegistrations()
    var
        Processing: Codeunit Processing;
        ResponseContent: Text;
    begin
        ResponseContent := Processing.GetRegistrationList();
        LoadFromJson(ResponseContent);
    end;

    local procedure LoadFromJson(JsonText: Text)
    var
        Activation: Codeunit Activation;
    begin
        Activation.PopulateFromJson(JsonText);
    end;
}