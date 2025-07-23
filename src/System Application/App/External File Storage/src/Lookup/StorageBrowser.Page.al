// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

page 9455 "Storage Browser"
{
    Caption = 'External Storage Browser';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "File Account Content";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentPermissions = X;
    InherentEntitlements = X;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CurrentPathField; CurrentPath)
            {
                Caption = 'Path';
                ShowCaption = false;
                Editable = false;
            }
            repeater(General)
            {
                field(Name; Rec.Name)
                {
                    DrillDown = true;
                    ToolTip = 'Specifies the value of the Name field.';

                    trigger OnDrillDown()
                    begin
                        case true of
                            Rec.Name = '..':
                                BrowseFolder(Rec."Parent Directory");
                            Rec.Type = Rec.Type::Directory:
                                BrowseFolder(Rec);
                            not IsInLookupMode:
                                FileAccountBrowserMgt.DownloadFile(Rec);
                        end;
                    end;
                }
                field("Type"; Rec."Type")
                {
                    ToolTip = 'Specifies the value of the Type field.';
                }
            }

            group(SaveFileNameGroup)
            {
                ShowCaption = false;
                Visible = ShowFileName;

                field(SaveFileNameField; SaveFileName)
                {
                    Caption = 'Filename';
                    ToolTip = 'Specifies the Name of the File.';
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(UploadRef; Upload) { }
            actionref(CreateDirectoryRef; "Create Directory") { }
            actionref(DeleteRef; Delete) { }
        }
        area(Processing)
        {
            action(Upload)
            {
                Caption = 'Upload';
                Image = Import;
                Ellipsis = true;
                Visible = not IsInLookupMode;
                Enabled = not IsInLookupMode;
                ToolTip = 'Uploads a file to the current directory.';

                trigger OnAction()
                begin
                    FileAccountBrowserMgt.UploadFile(CurrentPath);
                    BrowseFolder(CurrentPath);
                end;
            }
            action("Create Directory")
            {
                Caption = 'Create Directory';
                Image = Bin;
                Ellipsis = true;
                Visible = not IsInLookupMode;
                Enabled = not IsInLookupMode;
                ToolTip = 'Creates a new directory in the current directory.';

                trigger OnAction()
                begin
                    FileAccountBrowserMgt.CreateDirectory(CurrentPath);
                    BrowseFolder(CurrentPath);
                end;
            }
            action(Delete)
            {
                Caption = 'Delete';
                Image = Delete;
                Ellipsis = true;
                Visible = not IsInLookupMode;
                Enabled = not IsInLookupMode;
                ToolTip = 'Deletes the selected file or directory.';

                trigger OnAction()
                begin
                    FileAccountBrowserMgt.DeleteFileOrDirectory(Rec);
                    BrowseFolder(CurrentPath);
                end;
            }
        }
    }

    var
        FileAccountBrowserMgt: Codeunit "File Account Browser Mgt.";
        CurrentPath, FileFilter, SaveFileName, CurrentPageCaption : Text;
        DoNotLoadFiles, IsInLookupMode, ShowFileName : Boolean;

    trigger OnOpenPage()
    begin
        if CurrentPageCaption <> '' then
            CurrPage.Caption(CurrentPageCaption);
    end;

    internal procedure SetFileAccount(TempFileAccount: Record "File Account" temporary)
    begin
        FileAccountBrowserMgt.SetFileAccount(TempFileAccount);
    end;

    internal procedure BrowseFileAccount(Path: Text)
    begin
        BrowseFolder('');
    end;

    internal procedure EnableFileLookupMode(Path: Text; PassedFileFilter: Text)
    begin
        FileFilter := PassedFileFilter;
        EnableLookupMode();
        BrowseFolder(Path);
    end;

    internal procedure EnableDirectoryLookupMode(Path: Text)
    begin
        DoNotLoadFiles := true;
        EnableLookupMode();
        BrowseFolder(Path);
    end;

    internal procedure EnableSaveFileLookupMode(Path: Text; FileNameSuggestion: Text; FileExtension: Text)
    var
        FileFilterTok: Label '*.%1', Locked = true;
    begin
        ShowFileName := true;
        FileFilter := StrSubstNo(FileFilterTok, FileExtension);
        SaveFileName := FileNameSuggestion;
        EnableLookupMode();
        BrowseFolder(Path);
    end;

    internal procedure GetCurrentDirectory(): Text
    begin
        exit(CurrentPath);
    end;

    internal procedure GetFileName(): Text
    begin
        exit(SaveFileName);
    end;

    internal procedure SetPageCaption(NewCaption: Text)
    begin
        CurrentPageCaption := NewCaption;
    end;

    local procedure EnableLookupMode()
    begin
        IsInLookupMode := true;
        CurrPage.LookupMode(true);
    end;

    local procedure BrowseFolder(var TempFileAccountContent: Record "File Account Content" temporary)
    var
        Path: Text;
    begin
        Path := FileAccountBrowserMgt.CombinePath(TempFileAccountContent."Parent Directory", TempFileAccountContent.Name);
        BrowseFolder(Path);
    end;

    local procedure BrowseFolder(Path: Text)
    begin
        FileAccountBrowserMgt.BrowseFolder(Rec, Path, CurrentPath, DoNotLoadFiles, FileFilter);
    end;
}