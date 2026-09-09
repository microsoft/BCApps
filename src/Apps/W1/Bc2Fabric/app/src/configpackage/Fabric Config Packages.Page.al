namespace Microsoft.FabricExport;

using System.Utilities;

#if not PTE
page 150008 "Fabric Config Packages"
#else
page 50108 "Fabric Config Packages"
#endif
{
    Caption = 'Fabric Configuration Packages';
    PageType = List;
    SourceTable = "Fabric Config Package";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = true;
    CardPageId = "Fabric Config Package Card";
    AboutTitle = 'Activate curated table sets';
    AboutText = 'Import or select a configuration package to quickly add a curated set of tables to your Fabric synchronization, instead of selecting tables one by one.';

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
            action(DeletePackage)
            {
                Caption = 'Delete';
                ApplicationArea = All;
                Image = Delete;
                Enabled = not Rec.Active;
                ToolTip = 'Deletes the selected configuration package. The package must be deactivated first.';
                trigger OnAction()
                begin
                    if not Confirm(DeleteConfirmQst, false, Rec."Code") then
                        exit;
                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
            group(ImportExport)
            {
                Caption = 'Import/Export';

                action(ImportPackage)
                {
                    Caption = 'Import package';
                    ApplicationArea = All;
                    Image = Import;
                    ToolTip = 'Imports a configuration package definition from a JSON file.';
                    trigger OnAction()
                    var
                        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
                        InStream: InStream;
                        FileName: Text;
                    begin
                        if not UploadIntoStream('', '', '', FileName, InStream) then
                            exit;
                        FabricConfigPkgMgt.ImportPackageFromStream(InStream);
                        CurrPage.Update(false);
                    end;
                }
                action(ExportPackage)
                {
                    Caption = 'Export package';
                    ApplicationArea = All;
                    Image = Export;
                    ToolTip = 'Exports the selected configuration package definition to a JSON file.';
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
        ReapplyAvailable: Boolean;
        DeleteConfirmQst: Label 'Delete configuration package ''%1''?', Comment = '%1 = package code';

    trigger OnAfterGetRecord()
    var
        FabricConfigPkgMgt: Codeunit "Fabric Config Package Mgt";
    begin
        ReapplyAvailable := FabricConfigPkgMgt.IsReapplyAvailable(Rec);
    end;
}
