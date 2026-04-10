// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;
page 6412 "ForNAV Peppol Roles"
{
    PageType = List;
    SourceTable = "Fornav Peppol Role";
    Caption = 'ForNAV Peppol Roles';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Role; Rec.Role)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}