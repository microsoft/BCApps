namespace System.AI;

using System.Privacy;

page 2023 "Image Analysis Scenarios Part"
{
    PageType = ListPart;
    Caption = 'Image Analysis Scenarios';
    ApplicationArea = All;
    SourceTable = "Image Analysis Scenario";
    Permissions = tabledata "Image Analysis Scenario" = Rimd;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ScenarioName; Rec."Scenario Name")
                {
                    Caption = 'Scenario Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier for a scenario where Image Analysis can be used inside Business Central.';
                }
                field(CompanyName; Rec."Company Name")
                {
                    Caption = 'Company Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company where this setting applies (empty means all companies).';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Enabled';
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Image Analysis can be used or not for this scenario.';

                    trigger OnValidate()
                    var
                        PrivacyNotice: Codeunit "Privacy Notice";
                        PrivacyNoticeText: Text;
                    begin
                        if not Rec.Status then
                            exit;

                        PrivacyNoticeText := StrSubstNo(PrivacyNotice.GetDefaultPrivacyAgreementTxt(), AcsServiceNameTxt, ProductName.Full());

                        if not Confirm(ConfirmPrivacyNoticeQst, false, PrivacyNoticeText, PrivacyStatementLinkTxt) then
                            Error('');
                    end;
                }
            }
        }
    }

    var
        AcsServiceNameTxt: Label 'Azure Cognitive Services', Comment = 'The product name of Azure Cognitive Services';
        PrivacyStatementLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=831305', Locked = true;
        ConfirmPrivacyNoticeQst: Label '%1\\%2\\Do you want to enable this scenario?', Comment = '%1 = a long text describing the privacy notice for this feature. %2 = a link to the privacy notice';
}