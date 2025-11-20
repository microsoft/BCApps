// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Picture;

page 348 "Import Item Pictures"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Import Item Pictures';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Item Picture Buffer";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control6)
            {
                ShowCaption = false;
                field(ZipFileName; ZipFileName)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Select a ZIP File';
                    Editable = false;
                    ToolTip = 'Specifies a ZIP file with pictures for upload.';
                    Width = 60;

                    trigger OnAssistEdit()
                    begin
                        if ZipFileName <> '' then begin
                            Rec.DeleteAll();
                            ZipFileName := '';
                        end;
                        ZipFileName := Rec.LoadZIPFile('', TotalCount, ReplaceMode);
                        ReplaceModeEditable := ZipFileName <> '';
                        Rec.FindFirst();

                        UpdateCounters();
                    end;
                }
                field(ReplaceMode; ReplaceMode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Replace Pictures';
                    Editable = ReplaceModeEditable;
                    ToolTip = 'Specifies if existing item pictures are replaced during import.';

                    trigger OnValidate()
                    begin
                        if ZipFileName = '' then
                            Error(SelectZIPFilenameErr);

                        Rec.Reset();
                        Rec.SetRange("Picture Already Exists", true);
                        if ReplaceMode then
                            Rec.ModifyAll("Import Status", Rec."Import Status"::Pending)
                        else
                            Rec.ModifyAll("Import Status", Rec."Import Status"::Skip);
                        Rec.SetRange("Picture Already Exists");

                        UpdateCounters();
                        CurrPage.Update();
                    end;
                }
            }
            group(Control23)
            {
                ShowCaption = false;
                field(AddCount; AddCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pictures to Add';
                    Editable = false;
                    ToolTip = 'Specifies the number of item pictures that can be added with the selected ZIP file.';
                }
                field(ReplaceCount; ReplaceCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pictures to Replace';
                    Editable = false;
                    ToolTip = 'Specifies the number of existing item pictures that can be replaced with the selected ZIP file.';
                }
                field(TotalCount; TotalCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Pictures';
                    Editable = false;
                    ToolTip = 'Specifies the total number of item pictures that can be imported from the selected ZIP file.';
                }
                field(AddedCount; AddedCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Added Pictures';
                    Editable = false;
                    ToolTip = 'Specifies how many item pictures were added last time you used the Import Pictures action.';
                }
                field(ReplacedCount; ReplacedCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Replaced Pictures';
                    Editable = false;
                    ToolTip = 'Specifies how many item pictures were replaced last time you used the Import Pictures action.';
                }
            }
            repeater(Group)
            {
                Caption = 'Pictures';
                Editable = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item that the picture is for.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the item that the picture is for.';
                }
                field("Picture Already Exists"; Rec."Picture Already Exists")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a picture already exists for the item card.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the picture file. It must be the same as the item number.';
                    Width = 20;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the picture file.';
                    Width = 10;
                }
                field("File Size (KB)"; Rec."File Size (KB)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the picture file.';
                    Width = 10;
                }
                field("Modified Date"; Rec."Modified Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Modified Time"; Rec."Modified Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the picture was last modified.';
                    Visible = false;
                }
                field("Import Status"; Rec."Import Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the last import of the picture was been skipped, is pending, or is completed.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                action(ImportPictures)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Pictures';
                    Image = ImportExport;
                    ToolTip = 'Import pictures into items cards. Existing pictures will be replaced if the Replace Pictures check box is selected.';

                    trigger OnAction()
                    begin
                        Rec.ImportPictures(ReplaceMode);
                        AddedCount := Rec.GetAddedCount();
                        ReplacedCount := Rec.GetReplacedCount();
                    end;
                }
                action(ShowItemCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Item Card';
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    ToolTip = 'Open the item card that contains the picture.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ImportPictures_Promoted; ImportPictures)
                {
                }
                actionref(ShowItemCard_Promoted; ShowItemCard)
                {
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Rec.SetRange("Import Status", Rec."Import Status"::Pending);
        if not Rec.IsEmpty() then
            if not Confirm(ImportIncompleteQst, false) then begin
                Rec.SetRange("Import Status");
                exit(false);
            end;

        exit(true);
    end;

    var
        ZipFileName: Text;
        TotalCount: Integer;
        AddCount: Integer;
        SelectZIPFilenameErr: Label 'You must select the ZIP file first.';
        ImportIncompleteQst: Label 'One or more pictures have not been imported yet. If you leave the page, you must upload the ZIP file again to import remaining pictures.\\Do you want to leave this page?';
        AddedCount: Integer;
        ReplaceCount: Integer;
        ReplacedCount: Integer;
        ReplaceMode: Boolean;
        ReplaceModeEditable: Boolean;

    local procedure UpdateCounters()
    begin
        AddCount := Rec.GetAddCount();
        ReplaceCount := Rec.GetReplaceCount();
        AddedCount := Rec.GetAddedCount();
        ReplacedCount := Rec.GetReplacedCount();
    end;
}

