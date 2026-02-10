// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using System.Device;

page 20431 "Qlty. Most Recent Picture"
{
    Caption = 'Most Recent Picture';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = "Qlty. Inspection Header";
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            field("Most Recent Picture"; Rec."Most Recent Picture")
            {
                ShowCaption = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TakePicture)
            {
                Caption = 'Take';
                Visible = IsCameraAvailable;
                Image = Camera;
                ToolTip = 'Take a picture using the camera on the device.';

                trigger OnAction()
                begin
                    Rec.TakeNewMostRecentPicture();
                end;
            }
            action(ImportPicture)
            {
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a picture from existing file.';

                trigger OnAction()
                begin
                    if Rec."Most Recent Picture".HasValue() then
                        if not Confirm(OverrideImageQst) then
                            exit;

                    Rec.ImportMostRecentPicture();
                end;
            }
            action(DeletePicture)
            {
                Caption = 'Delete';
                Enabled = DeleteExportEnabled;
                Image = Delete;
                ToolTip = 'Delete the most recent picture.';

                trigger OnAction()
                begin
                    if GuiAllowed() then
                        if not Confirm(DeleteImageQst) then
                            exit;

                    Rec.DeleteMostRecentPicture();
                end;
            }
        }
    }

    var
        IsCameraAvailable: Boolean;
        DeleteExportEnabled: Boolean;
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
        OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';

    trigger OnOpenPage()
    var
        Camera: Codeunit Camera;
    begin
        IsCameraAvailable := Camera.IsAvailable();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableOnPictureActions();
    end;

    local procedure SetEditableOnPictureActions()
    begin
        DeleteExportEnabled := Rec."Most Recent Picture".HasValue();
    end;
}
