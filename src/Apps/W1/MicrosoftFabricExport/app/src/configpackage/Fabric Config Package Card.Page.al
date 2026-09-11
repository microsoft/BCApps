namespace Microsoft.FabricExport;

using System.Utilities;

page 150006 "Fabric Config Package Card"
{
    Caption = 'Fabric Config Package';
    PageType = Card;
    SourceTable = "Fabric Config Package";
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    AboutTitle = 'Review a configuration package';
    AboutText = 'See which tables this configuration package adds, and activate, deactivate, or reapply it to keep your synchronized tables in sync with the latest version.';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    Editable = IsNew;
                    ToolTip = 'Specifies the unique code for the configuration package.';
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
                    Editable = false;
                    ToolTip = 'Specifies whether this configuration package is currently active.';
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
            part(Lines; "Fabric Config Package Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Package Code" = field("Code");
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
            action(ExportPackage)
            {
                Caption = 'Export package';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Exports this configuration package definition to a JSON file.';
                trigger OnAction()
                var
                    FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
                    TempBlob: Codeunit "Temp Blob";
                    OutStream: OutStream;
                    InStream: InStream;
                    FileName: Text;
                begin
                    TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
                    FabricConfigPkgMgt.ExportPackageToStream(Rec, OutStream);
                    TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
                    FileName := Rec."Code" + '.json';
                    DownloadFromStream(InStream, '', '', '', FileName);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Activate_Promoted; Activate) { }
                actionref(Deactivate_Promoted; Deactivate) { }
                actionref(Reapply_Promoted; Reapply) { }
            }
        }
    }

    var
        IsNew: Boolean;
        ReapplyAvailable: Boolean;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsNew := true;
    end;

    trigger OnAfterGetRecord()
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        IsNew := false;
        ReapplyAvailable := FabricConfigPkgMgt.IsReapplyAvailable(Rec);
    end;
}
