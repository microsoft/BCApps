// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using System.Device;
using System.IO;
using System.Text;

/// <summary>
/// Page Shpfy Item Variant Picture (ID 30414).
/// </summary>
page 30414 "Shpfy Item Variant Picture"
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
                Visible = this.CameraAvailable and (this.HideActions = false);

                trigger OnAction()
                begin
                    this.TakeNewPicture();
                end;
            }
            action(ImportPicture)
            {
                ApplicationArea = All;
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a picture file.';
                Visible = this.HideActions = false;

                trigger OnAction()
                begin
                    this.ImportFromDevice();
                end;
            }
            action(ExportFile)
            {
                ApplicationArea = All;
                Caption = 'Export';
                Enabled = this.DeleteExportEnabled;
                Image = Export;
                ToolTip = 'Export the picture to a file.';
                Visible = this.HideActions = false;

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
                    Rec.TestField("Code");
                    Rec.TestField(Description);
                    ConvertedCodeType := Format(Rec."Code");
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
                Enabled = this.DeleteExportEnabled;
                Image = Delete;
                ToolTip = 'Delete the record.';
                Visible = this.HideActions = false;

                trigger OnAction()
                begin
                    this.DeleteItemPicture();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        this.SetEditableOnPictureActions();
    end;

    trigger OnOpenPage()
    begin
        this.CameraAvailable := this.Camera.IsAvailable();
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

    procedure TakeNewPicture()
    begin
        Rec.Find();
        Rec.TestField("Item No.");
        Rec.TestField("Code");
        Rec.TestField(Description);

        this.OnAfterTakeNewPicture(Rec, this.DoTakeNewPicture());
    end;

    [Scope('OnPrem')]
    procedure ImportFromDevice()
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
        ClientFileName: Text;
    begin
        Rec.Find();
        Rec.TestField("Item No.");
        Rec.TestField("Code");
        if Rec.Description = '' then
            Error(this.MustSpecifyDescriptionErr);

        if Rec.Picture.Count > 0 then
            if not Confirm(this.OverrideImageQst) then
                Error('');

        ClientFileName := '';
        FileName := FileManagement.UploadFile(this.SelectPictureTxt, ClientFileName);
        if FileName = '' then
            Error('');

        Clear(Rec.Picture);
        Rec.Picture.ImportFile(FileName, ClientFileName);
        Rec.Modify(true);
        this.OnImportFromDeviceOnAfterModify(Rec);

        if FileManagement.DeleteServerFile(FileName) then;
    end;

    local procedure DoTakeNewPicture(): Boolean
    var
        PictureInstream: InStream;
        PictureDescription: Text;
    begin
        if Rec.Picture.Count() > 0 then
            if not Confirm(this.OverrideImageQst) then
                exit(false);

        if this.Camera.GetPicture(PictureInstream, PictureDescription) then begin
            Clear(Rec.Picture);
            Rec.Picture.ImportStream(PictureInstream, PictureDescription, this.MimeTypeTok);
            Rec.Modify(true);
            exit(true);
        end;

        exit(false);
    end;

    local procedure SetEditableOnPictureActions()
    begin
        this.DeleteExportEnabled := Rec.Picture.Count <> 0;
    end;

    procedure IsCameraAvailable(): Boolean
    begin
        exit(this.Camera.IsAvailable());
    end;

    procedure SetHideActions()
    begin
        this.HideActions := true;
    end;

    procedure DeleteItemPicture()
    begin
        Rec.TestField("Item No.");
        Rec.TestField("Code");

        if not Confirm(this.DeleteImageQst) then
            exit;

        Clear(Rec.Picture);
        Rec.Modify(true);

        this.OnAfterDeleteItemPicture(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteItemPicture(var ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTakeNewPicture(var ItemVariant: Record "Item Variant"; IsPictureAdded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportFromDeviceOnAfterModify(var ItemVariant: Record "Item Variant")
    begin
    end;
}
