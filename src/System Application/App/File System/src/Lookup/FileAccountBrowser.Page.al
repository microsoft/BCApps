// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

page 9455 "File Account Browser"
{
    Caption = 'File Account Browser';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "File Account Content";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(content)
        {
            field(CurrPathField; CurrPath)
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
                            (Rec.Name = '..'):
                                BrowseFolder(Rec."Parent Directory");
                            (Rec.Type = Rec.Type::Directory):
                                BrowseFolder(Rec);
                            (not IsInLookupMode):
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
                Caption = '', Locked = true;
                ShowCaption = false;
                Visible = ShowFileName;

                field(SaveFileNameField; SaveFileName)
                {
                    Caption = 'Filename';
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

                trigger OnAction()
                begin
                    FileAccountBrowserMgt.UploadFile(CurrPath);
                    BrowseFolder(CurrPath);
                end;
            }
            action("Create Directory")
            {
                Caption = 'Create Directory';
                Image = Bin;
                Ellipsis = true;
                Visible = not IsInLookupMode;
                Enabled = not IsInLookupMode;

                trigger OnAction()
                begin
                    FileAccountBrowserMgt.CreateDirectory(CurrPath);
                    BrowseFolder(CurrPath);
                end;
            }
            action(Delete)
            {
                Caption = 'Delete';
                Image = Delete;
                Ellipsis = true;
                Visible = not IsInLookupMode;
                Enabled = not IsInLookupMode;

                trigger OnAction()
                begin
                    FileAccountBrowserMgt.DeleteFileOrDirectory(Rec);
                    BrowseFolder(CurrPath);
                end;
            }
        }
    }

    var
        FileAccountBrowserMgt: Codeunit "File Account Browser Mgt.";
        CurrPath, CurrFileFilter, SaveFileName, CurrPageCaption : Text;
        DoNotLoadFiles, IsInLookupMode, ShowFileName : Boolean;

    trigger OnOpenPage()
    begin
        if CurrPageCaption <> '' then
            CurrPage.Caption(CurrPageCaption);
    end;

    internal procedure SetFileAccount(FileAccount: Record "File Account")
    begin
        FileAccountBrowserMgt.SetFileAccount(FileAccount);
    end;

    internal procedure BrowseFileAccount(Path: Text)
    begin
        BrowseFolder('');
    end;

    internal procedure EnableFileLookupMode(Path: Text; FileFilter: Text)
    begin
        CurrFileFilter := FileFilter;
        EnableLookupMode();
        BrowseFolder(Path);
    end;

    internal procedure EnableDirectoryLookupMode(Path: Text)
    begin
        DoNotLoadFiles := true;
        EnableLookupMode();
        BrowseFolder(Path);
    end;

    internal procedure EnableSaveFileLookupMode(Path: Text; FileExtension: Text)
    var
        FileFilterTok: Label '*.%1', Locked = true;
    begin
        ShowFileName := true;
        CurrFileFilter := StrSubstNo(FileFilterTok, FileExtension);
        EnableLookupMode();
        BrowseFolder(Path);
    end;

    internal procedure GetCurrentDirectory(): Text
    begin
        exit(CurrPath);
    end;

    internal procedure GetFileName(): Text
    begin
        exit(SaveFileName);
    end;

    internal procedure SetPageCaption(NewCaption: Text)
    begin
        CurrPageCaption := NewCaption;
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
        FileAccountBrowserMgt.BrowseFolder(Rec, Path, CurrPath, DoNotLoadFiles, CurrFileFilter);
    end;
}
