// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Picture;

using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using System.Device;
using System.IO;
using System.Text;

page 409 "Item Variant Picture"
{
    Caption = 'Item Variant Picture';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = "Item Variant";

    layout
    {
        area(content)
        {
            field(Picture; Rec.Picture)
            {
                ApplicationArea = Basic, Suite;
                ShowCaption = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(TakePicture)
            {
                ApplicationArea = All;
                Caption = 'Take';
                Image = Camera;
                ToolTip = 'Activate the camera on the device.';
                Visible = CameraAvailable and (not HideActions);

                trigger OnAction()
                begin
                    TakeNewPicture();
                end;
            }
            action(ImportPicture)
            {
                ApplicationArea = All;
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a picture file.';
                Visible = not HideActions;

                trigger OnAction()
                begin
                    ImportFromDevice();
                end;
            }
            action(ExportFile)
            {
                ApplicationArea = All;
                Caption = 'Export';
                Enabled = DeleteExportEnabled;
                Image = Export;
                ToolTip = 'Export the picture to a file.';
                Visible = not HideActions;

                trigger OnAction()
                var
                    DummyPictureEntity: Record "Picture Entity";
                    FileManagement: Codeunit "File Management";
                    StringConversionManager: Codeunit StringConversionManagement;
                    ToFile: Text;
                    ConvertedCodeType: Text;
                    ExportPath: Text;
                begin
                    Rec.TestField("Item No.");
                    Rec.TestField(Code);
                    Rec.TestField(Description);
                    ConvertedCodeType := Format(Rec.Code);
                    ToFile := DummyPictureEntity.GetDefaultMediaDescription(Rec);
                    ConvertedCodeType := StringConversionManager.RemoveNonAlphaNumericCharacters(ConvertedCodeType);
                    ExportPath := TemporaryPath + ConvertedCodeType + Format(Rec.Picture.MediaId);
                    Rec.Picture.ExportFile(ExportPath + '.' + DummyPictureEntity.GetDefaultExtension());

                    FileManagement.ExportImage(ExportPath, ToFile);
                end;
            }
            action(DeletePicture)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Enabled = DeleteExportEnabled;
                Image = Delete;
                ToolTip = 'Delete the record.';
                Visible = not HideActions;

                trigger OnAction()
                begin
                    DeleteItemVariantPicture();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableOnPictureActions();
    end;

    trigger OnOpenPage()
    begin
        CameraAvailable := Camera.IsAvailable();
    end;

    var
        Camera: Codeunit Camera;
        CameraAvailable: Boolean;
        OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
        SelectPictureTxt: Label 'Select a picture to upload';
        DeleteExportEnabled: Boolean;
        HideActions: Boolean;
        MustSpecifyDescriptionErr: Label 'You must add a description to the item variant before you can import a picture.';
        MimeTypeTok: Label 'image/jpeg', Locked = true;

    local procedure TakeNewPicture()
    begin
        Rec.Find();
        Rec.TestField("Item No.");
        Rec.TestField(Code);
        Rec.TestField(Description);

        Rec.OnAfterTakeNewPicture(Rec, DoTakeNewPicture());
    end;

    [Scope('OnPrem')]
    local procedure ImportFromDevice()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
        ClientFileName: Text;
    begin
        Rec.Find();
        Rec.TestField("Item No.");
        Rec.TestField(Code);
        if Rec.Description = '' then
            Error(MustSpecifyDescriptionErr);

        if Rec.Picture.Count > 0 then
            if not Confirm(OverrideImageQst) then
                Error('');

        ClientFileName := '';
        FileName := FileManagement.UploadFile(SelectPictureTxt, ClientFileName);
        if FileName = '' then
            Error('');

        Clear(Rec.Picture);
        Rec.Picture.ImportFile(FileName, ClientFileName);
        Rec.Modify(true);
        Rec.OnImportFromDeviceOnAfterModify(Rec);

        if FileManagement.DeleteServerFile(FileName) then;
    end;

    local procedure DoTakeNewPicture(): Boolean
    var
        PictureInstream: InStream;
        PictureDescription: Text;
    begin
        if Rec.Picture.Count() > 0 then
            if not Confirm(OverrideImageQst) then
                exit(false);

        if Camera.GetPicture(PictureInstream, PictureDescription) then begin
            Clear(Rec.Picture);
            Rec.Picture.ImportStream(PictureInstream, PictureDescription, MimeTypeTok);
            Rec.Modify(true);
            exit(true);
        end;

        exit(false);
    end;

    local procedure SetEditableOnPictureActions()
    begin
        DeleteExportEnabled := Rec.Picture.Count <> 0;
    end;

    local procedure DeleteItemVariantPicture()
    begin
        Rec.TestField("Item No.");
        Rec.TestField(Code);

        if not Confirm(DeleteImageQst) then
            exit;

        Clear(Rec.Picture);
        Rec.Modify(true);

        Rec.OnAfterDeleteItemVariantPicture(Rec);
    end;
}
