namespace Microsoft.API.Upgrade;

using System.Environment;
using System.Upgrade;

page 9998 "API Data Upgrade Companies"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'API upgrade overview';
    SourceTable = Company;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the name of the company.';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Hyperlink(GetUrl(ClientType::Web, Rec.Name, ObjectType::Page, Page::"API Data Upgrade List"));
                    end;
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the display name of the company.';
                    Editable = false;
                }
                field(UpgradeEnabled; Status)
                {
                    ApplicationArea = All;
                    Caption = 'API Upgrade Status';
                    ToolTip = 'Specifies if the API data upgrade is enabled for this company.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateStatusText();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateStatusText();
    end;

    local procedure UpdateStatusText()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        APIDataUpgrade: Codeunit "API Data Upgrade";
    begin
        Status := EnabledTok;
        if not UpgradeTag.HasUpgradeTag(APIDataUpgrade.GetDisableAPIDataUpgradesTag(), Rec.Name) then
            exit;

        if UpgradeTag.HasUpgradeTagSkipped(APIDataUpgrade.GetDisableAPIDataUpgradesTag(), Rec.Name) then
            Status := DisabledTok;
    end;

    var
        Status: Text;
        DisabledTok: Label 'Disabled';
        EnabledTok: Label 'Enabled';
}