// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

pageextension 8700 "Table Information Ext." extends "Table Information"
{

    actions
    {
        addlast(Navigation)
        {
            action("Data Administration")
            {
                Caption = 'Data Administration';
                ToolTip = 'Navigate to the Data Administration page to manage settings for deleting and compressing data.';
                ApplicationArea = All;
                Image = SetupList;

                trigger OnAction()
                begin
                    Page.run(Page::"Data Administration");
                end;
            }
        }
        addfirst(Category_Process)
        {
            actionref("Data Administration_Promoted"; "Data Administration")
            {
            }
        }
        modify(Category_Category4)
        {
            Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
        }
        modify(Category_New)
        {
            Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';
        }
        modify(Category_Process)
        {
            Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
        }
        modify(Category_Report)
        {
            Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
        }
    }
}
