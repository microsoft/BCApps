namespace Microsoft.Bc2Fabric;

page 150008 "Fabric Config Packages"
{
    Caption = 'Fabric Config Packages';
    PageType = List;
    SourceTable = "Fabric Config Package";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;
    CardPageId = "Fabric Config Package Card";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the configuration package.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the configuration package.';
                }
                field(Version; Rec.Version)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the version of the configuration package.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this package is currently active.';
                }
                field("Activated On"; Rec."Activated On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this package was last activated.';
                }
                field("Activated By"; Rec."Activated By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who activated this package.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Activate)
            {
                Caption = 'Activate';
                ApplicationArea = All;
                Image = Approve;
                Enabled = not Rec.Active;
                ToolTip = 'Activates the selected configuration package, adding its tables to the Fabric Tables list.';
                trigger OnAction()
                var
                    FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
                begin
                    FabricConfigPkgMgt.Activate(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Deactivate)
            {
                Caption = 'Deactivate';
                ApplicationArea = All;
                Image = Cancel;
                Enabled = Rec.Active;
                ToolTip = 'Deactivates the selected configuration package, removing its tables from the Fabric Tables list.';
                trigger OnAction()
                var
                    FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
                begin
                    FabricConfigPkgMgt.Deactivate(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reapply)
            {
                Caption = 'Reapply';
                ApplicationArea = All;
                Image = Restore;
                Enabled = ReapplyAvailable;
                ToolTip = 'Reapplies the configuration package to sync table additions or removals from the latest version.';
                trigger OnAction()
                var
                    FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
                begin
                    FabricConfigPkgMgt.Reapply(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ReapplyAvailable: Boolean;

    trigger OnAfterGetRecord()
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        ReapplyAvailable := FabricConfigPkgMgt.IsReapplyAvailable(Rec);
    end;
}
