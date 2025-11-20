namespace Microsoft.API.Upgrade;

using Microsoft.Integration.Graph;
using System.Upgrade;

page 9994 "API Data Upgrade List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "API Data Upgrade";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control2)
            {
                field("Upgrade Tag"; Rec."Upgrade Tag")
                {
                    ApplicationArea = All;
                    Caption = 'Entity Name';
                    ToolTip = 'Name of the entity.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Endpoints';
                    ToolTip = 'API endpoints of the entity.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Status of the API data upgrade.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Schedule Upgrades")
            {
                ApplicationArea = All;
                Image = CreateLinesFromTimesheet;
                ToolTip = 'Schedules an upgrade job queue entry for selected API data upgrades.';

                trigger OnAction();
                var
                    APIDataUpgrade: Record "API Data Upgrade";
                    GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                begin
                    APIDataUpgrade.Copy(Rec);
                    CurrPage.SetSelectionFilter(APIDataUpgrade);
                    APIDataUpgrade.SetRange(Status, APIDataUpgrade.Status::" ");
                    APIDataUpgrade.ModifyAll(Status, APIDataUpgrade.Status::Scheduled);
                    GraphMgtGeneralTools.ScheduleUpdateAPIRecordsJob(Codeunit::"API Data Upgrade");
                    CurrPage.Update();
                end;
            }
            action(Reset)
            {
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Reset status of selected scheduled API data upgrade.';

                trigger OnAction();
                begin
                    Clear(Rec.Status);
                    Rec.Modify();
                    CurrPage.Update();
                end;
            }
            action("Disable API Data Upgrades")
            {
                ApplicationArea = All;
                Image = CancelIndent;
                ToolTip = 'Disables data upgrade for all API data upgrade functions. Use Enable API Upgrade action to enable it again.';

                trigger OnAction();
                var
                    UpgradeTag: Codeunit "Upgrade Tag";
                    APIDataUpgrade: Codeunit "API Data Upgrade";
                begin
                    if not UpgradeTag.HasUpgradeTag(APIDataUpgrade.GetDisableAPIDataUpgradesTag()) then
                        UpgradeTag.SetUpgradeTag(APIDataUpgrade.GetDisableAPIDataUpgradesTag());

                    UpgradeTag.SetSkippedUpgrade(APIDataUpgrade.GetDisableAPIDataUpgradesTag(), true);
                    Message(APIUpgradeIsDisabledMsg);
                end;
            }
            action(EnableAPIUpgrade)
            {
                ApplicationArea = All;
                Caption = 'Enable API Upgrade';
                ToolTip = 'Enables the API Upgrade again.';
                Image = Completed;

                trigger OnAction();
                var
                    UpgradeTag: Codeunit "Upgrade Tag";
                    APIDataUpgrade: Codeunit "API Data Upgrade";
                begin
                    if not UpgradeTag.HasUpgradeTag(APIDataUpgrade.GetDisableAPIDataUpgradesTag()) then
                        Error(APIUpgradeWasNotSkippedErr);

                    UpgradeTag.SetSkippedUpgrade(APIDataUpgrade.GetDisableAPIDataUpgradesTag(), false);
                    Message(APIUpgradeIsEnabledMsg);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Schedule Upgrades_Promoted"; "Schedule Upgrades")
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
                group(Category_Process_DisableAPIUpgrade)
                {
                    Caption = 'Configure';
                    ShowAs = SplitButton;

                    actionref("Promoted_Disable API Data Upgrades"; "Disable API Data Upgrades")
                    {
                    }
                    actionref(Promoted_EnableAPIUpgrade; EnableAPIUpgrade)
                    {
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Load();
    end;

    var
        APIUpgradeWasNotSkippedErr: Label 'API upgrade was not skipped.';
        APIUpgradeIsDisabledMsg: Label 'API upgrade is disabled.';
        APIUpgradeIsEnabledMsg: Label 'API upgrade is enabled.';
}