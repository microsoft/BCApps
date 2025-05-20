// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

page 9456 "Folder Name Input"
{
    ApplicationArea = All;
    Caption = 'Create Folder...';
    PageType = StandardDialog;
    Extensible = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(Content)
        {
            field(FolderNameField; FolderName)
            {
                Caption = 'Folder Name';
                ToolTip = 'Specifies the Name of the directory.';
            }
        }
    }

    var
        FolderName: Text;

    internal procedure GetFolderName(): Text
    begin
        exit(FolderName);
    end;
}
