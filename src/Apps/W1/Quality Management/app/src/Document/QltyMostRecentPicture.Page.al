// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.QualityManagement.Utilities;
using System.Device;

page 20431 "Qlty. Most Recent Picture"
{
    Caption = 'Quality Most Recent Picture';
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
                Image = Camera;
                ToolTip = 'Activate the camera on the device.';
                Visible = IsCameraAvailable and (not HideActions);

                trigger OnAction()
                begin
                    Rec.TakeNewPicture();
                end;
            }
            action(ImportPicture)
            {
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a picture file.';
                Visible = not HideActions;

                trigger OnAction()
                var
                    QltyFileImport: Codeunit "Qlty. File Import";
                    InStream: InStream;
                begin
                    if Rec."Most Recent Picture".HasValue() then
                        if not Confirm(OverrideImageQst) then
                            exit;
                    Clear(Rec."Most Recent Picture");
                    if QltyFileImport.PromptAndImportIntoInStream(FileFilterTok, InStream) then begin
                        Rec."Most Recent Picture".ImportStream(InStream, ImageTok);
                        Rec.Modify();
                    end;
                end;
            }
            action(DeletePicture)
            {
                Caption = 'Delete';
                Enabled = DeleteExportEnabled;
                Image = Delete;
                ToolTip = 'Delete the record.';
                Visible = not HideActions;

                trigger OnAction()
                begin
                    DeleteMostRecentPicture();
                end;
            }
        }
    }

    var
        Camera: Codeunit Camera;
        IsCameraAvailable: Boolean;
        DeleteExportEnabled: Boolean;
        HideActions: Boolean;
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
        OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';
        FileFilterTok: Label 'Pictures |*.jpg;*.png;*.jpeg;*.bmp', Locked = true;
        ImageTok: Label 'Image', Locked = true;

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableOnPictureActions();
    end;

    trigger OnOpenPage()
    begin
        IsCameraAvailable := Camera.IsAvailable();
    end;

    local procedure SetEditableOnPictureActions()
    begin
        DeleteExportEnabled := Rec."Most Recent Picture".HasValue();
    end;

    /// <summary>
    /// Deletes the most recent picture.
    /// </summary>
    procedure DeleteMostRecentPicture()
    begin
        if GuiAllowed() then
            if not Confirm(DeleteImageQst) then
                exit;

        Clear(Rec."Most Recent Picture");
        Rec.Modify(true);
    end;
}
