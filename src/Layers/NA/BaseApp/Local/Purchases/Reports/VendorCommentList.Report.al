// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;

report 10104 "Vendor Comment List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorCommentList.rdlc';
    Caption = 'Vendor Comment List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Comment Line"; "Comment Line")
        {
            DataItemTableView = sorting("Table Name", "No.", "Line No.") where("Table Name" = const(Vendor));
            RequestFilterFields = "No.", Date, "Code";
            column(Vendor_Comment_List_; 'Vendor Comment List')
            {
            }
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
            column(FilterString; FilterString)
            {
            }
            column(Vendor__No__; Vendor."No.")
            {
            }
            column(Vendor_Name; Vendor.Name)
            {
            }
            column(Vendor__Phone_No__; Vendor."Phone No.")
            {
            }
            column(Vendor_Contact; Vendor.Contact)
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
            column(Comment_Line___No__; "Comment Line"."No.")
            {
            }
            column(CommentLine2_NEXT; CommentLine2.Next())
            {
            }
            column(Comment_Line_Table_Name; "Table Name")
            {
            }
            column(Comment_Line_Line_No_; "Line No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(Comment_Line_DateCaption; FieldCaption(Date))
            {
            }
            column(Comment_Line_CommentCaption; FieldCaption(Comment))
            {
            }
            column(Phone_Caption; Phone_CaptionLbl)
            {
            }
            column(Contact_Caption; Contact_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not Vendor.Get("No.") then begin
                    Clear(Vendor);
                    Vendor.Name := 'No Name';
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
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies that each vendor begins on a new page.';
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
        FilterString := "Comment Line".GetFilters();
    end;

    var
        NewPagePer: Boolean;
        FilterString: Text;
        Vendor: Record Vendor;
        CommentLine2: Record "Comment Line";
        CompanyInformation: Record "Company Information";
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vendor__No__CaptionLbl: Label 'Vendor';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
}

