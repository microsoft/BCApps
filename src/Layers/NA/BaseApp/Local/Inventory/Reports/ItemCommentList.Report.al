// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;

report 10141 "Item Comment List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemCommentList.rdlc';
    Caption = 'Item Comment List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Comment Line"; "Comment Line")
        {
            DataItemTableView = sorting("Table Name", "No.", "Line No.") where("Table Name" = const(Item));
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Comment_Line__TABLECAPTION__________CommentFilter; "Comment Line".TableCaption + ': ' + CommentFilter)
            {
            }
            column(CommentFilter; CommentFilter)
            {
            }
            column(Comment_Line___Table_Name_; "Comment Line"."Table Name")
            {
            }
            column(Comment_Line__No__; "No.")
            {
            }
            column(Item_Description; Item.Description)
            {
            }
            column(Item_FIELDCAPTION__Vendor_No_____________Item__Vendor_No__; Item.FieldCaption("Vendor No.") + ': ' + Item."Vendor No.")
            {
            }
            column(Comment_Line_Date; Date)
            {
            }
            column(Comment_Line_Comment; Comment)
            {
            }
            column(NewPagePer; NewPagePer)
            {
            }
            column(Comment_Line_Line_No_; "Line No.")
            {
            }
            column(Item_Comment_ListCaption; Item_Comment_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not Item.Get("No.") then begin
                    Item.Init();
                    Item.Description := Text000;
                end;

                CommentLine2 := "Comment Line";
                CommentLine2.Find('=');
            end;

            trigger OnPreDataItem()
            begin
                CommentLine2.CopyFilters("Comment Line");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPagePer; NewPagePer)
                    {
                        Caption = 'New Page per Item';
                        ToolTip = 'Specifies that each item begins on a new page.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        CommentFilter := "Comment Line".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        Item: Record Item;
        CommentLine2: Record "Comment Line";
        NewPagePer: Boolean;
        CommentFilter: Text;
        Text000: Label 'No Item Description';
        Item_Comment_ListCaptionLbl: Label 'Item Comment List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
}

