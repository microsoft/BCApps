// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System.Integration;
using System.IO;

page 1610 "Office Add-in Management"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Outlook Add-in Management';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Office Add-in";
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Outlook, Office, O365, Add-in, AddIn, M365, Microsoft 365, Addon, App, Plugin, Manifest';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Application ID"; Rec."Application ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the application that is being added. ';
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field(Version; Rec.Version)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the version of the record';
                }
                field("Manifest Codeunit"; Rec."Manifest Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit where the Office add-in is defined for deployment.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Upload Default Add-in Manifest")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Upload Add-in', Comment = 'Action - Uploads a default XML manifest definition';
                Image = Import;
                ToolTip = 'Import an XML manifest file to the add-in. The manifest determines how an add-in is activated in Office applications where it is deployed.';

                trigger OnAction()
                begin
                    UploadManifest();
                end;
            }
            action("Download Add-in Manifest")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download Add-in', Comment = 'Action - downloads the XML manifest document for the add-in';
                Image = Export;
                Scope = Repeater;
                ToolTip = 'Export the add-in''s manifest to an XML file. You can then modify the manifest and upload it again.';

                trigger OnAction()
                begin
                    CheckManifest(Rec);
                    AddinManifestManagement.DownloadManifestToClient(Rec, StrSubstNo('%1.xml', Rec.Name));
                end;
            }
            action("Outlook add-in centralized deployment")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set up Centralized Deployment';
                Image = Setup;
                ToolTip = 'Deploy Business Central Outlook Add-ins for specific users, groups, or the entire organization.';
                RunObject = Page "Outlook Centralized Deployment";
                RunPageMode = Edit;
            }
            action("Reset Default Add-ins")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset Default Add-ins';
                Image = Restore;
                ToolTip = 'Reset the system add-ins to their default state.';

                trigger OnAction()
                begin
                    if Confirm(ResetWarningQst) then
                        AddinManifestManagement.CreateDefaultAddins(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Upload Default Add-in Manifest_Promoted"; "Upload Default Add-in Manifest")
                {
                }
                actionref("Download Add-in Manifest_Promoted"; "Download Add-in Manifest")
                {
                }
                actionref("Outlook add-in centralized deployment_Promoted"; "Outlook add-in centralized deployment")
                {
                }
                actionref("Reset Default Add-ins_Promoted"; "Reset Default Add-ins")
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        if Rec.IsEmpty() then
            AddinManifestManagement.CreateDefaultAddins(Rec);
    end;

    var
        UploadManifestTxt: Label 'Upload default manifest';
        MissingManifestErr: Label 'Cannot find a default manifest for add-in %1. To upload an XML file with the manifest, choose Upload Default Add-in Manifest.', Comment = '%1=The name of an office add-in.';
        OverwriteManifestQst: Label 'The uploaded manifest matches the existing item with name %1, would you like to overwrite it with the values from the uploaded manifest?', Comment = '%1: An Office Add-in name.';
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        ResetWarningQst: Label 'This will restore the original add-in manifest for each of the default add-ins. Are you sure you want to continue?';

    local procedure CheckManifest(var OfficeAddin: Record "Office Add-in")
    begin
        if not OfficeAddin."Default Manifest".HasValue and (OfficeAddin."Manifest Codeunit" = 0) then
            Error(MissingManifestErr, OfficeAddin.Name);
    end;

    local procedure UploadManifest()
    var
        OfficeAddin: Record "Office Add-in";
        TempOfficeAddin: Record "Office Add-in" temporary;
        FileManagement: Codeunit "File Management";
        ManifestLocation: Text;
    begin
        // Insert into a temp record so we can do some comparisons
        TempOfficeAddin.Init();
        TempOfficeAddin.Insert();

        ManifestLocation := FileManagement.UploadFile(UploadManifestTxt, '*.xml');

        // If the selected record is new, use that one - otherwise create a new one
        AddinManifestManagement.UploadDefaultManifest(TempOfficeAddin, ManifestLocation);

        // If the uploaded item already exists, overwrite, otherwise insert a new one.
        if not OfficeAddin.Get(TempOfficeAddin."Application ID") then begin
            OfficeAddin.Copy(TempOfficeAddin);
            OfficeAddin.Insert();
        end else
            if DIALOG.Confirm(OverwriteManifestQst, true, OfficeAddin.Name) then begin
                // Persist codeunit and company values when overwriting
                TempOfficeAddin."Manifest Codeunit" := OfficeAddin."Manifest Codeunit";
                OfficeAddin.Copy(TempOfficeAddin);
                OfficeAddin.Modify();
            end;
    end;
}

