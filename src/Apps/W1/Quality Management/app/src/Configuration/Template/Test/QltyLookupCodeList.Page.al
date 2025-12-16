// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
/// A list of available codes that can be used as a lookup.
/// </summary>
page 20409 "Qlty. Lookup Code List"
{
    Caption = 'Quality Lookup Codes';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Qlty. Lookup Code";
    SourceTableView = sorting("Group Code", Code);
    UsageCategory = Administration;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(GroupLookupCodes)
            {
                ShowCaption = false;

                field("Group Code"; Rec."Group Code")
                {
                }
                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Custom 1"; Rec."Custom 1")
                {
                }
                field("Custom 2"; Rec."Custom 2")
                {
                }
                field("Custom 3"; Rec."Custom 3")
                {
                }
                field("Custom 4"; Rec."Custom 4")
                {
                }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }
}
