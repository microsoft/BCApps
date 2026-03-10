// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

page 20436 "Qlty. Lookup Field Choose"
{
    Caption = 'Lookup Field Choose';
    Editable = false;
    PageType = List;
    SourceTable = "Qlty. Test Lookup Value";
    SourceTableTemporary = true;
    SourceTableView = sorting("Value");
    UsageCategory = None;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                ShowCaption = false;

                field(Code; Rec."Value")
                {
                    ToolTip = 'Specifies the initial code to lookup.';
                }
                field(Description; Rec.Description)
                {
                }
            }
        }
    }
}
