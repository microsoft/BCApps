// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

report 10043 "Customer Comment List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerCommentList.rdlc';
    Caption = 'Customer Comment List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Comment Line"; "Comment Line")
        {
            DataItemTableView = sorting("Table Name", "No.", "Line No.") where("Table Name" = const(Customer));
            RequestFilterFields = "No.", Date, "Code";
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
            column(FilterString_Control1400000; FilterString)
            {
            }
            column(NewPagePer; NewPagePer)
            {
            }
            column(Comment_Line__No__; "No.")
            {
            }
            column(Customer_Name; Customer.Name)
            {
            }
            column(Customer__Phone_No__; Customer."Phone No.")
            {
            }
            column(Customer_Contact; Customer.Contact)
            {
            }
            column(Comment_Line_Date; Date)
            {
            }
            column(Comment_Line_Comment; Comment)
            {
            }
            column(Comment_Line_Table_Name; "Table Name")
            {
            }
            column(Comment_Line_Line_No_; "Line No.")
            {
            }
            column(Customer_Comment_ListCaption; Customer_Comment_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Comment_Line__No__Caption; Comment_Line__No__CaptionLbl)
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
                CommentLine2 := "Comment Line";
                CommentLine2.Find('=');

                if not Customer.Get("No.") then begin
                    Clear(Customer);
                    Customer.Name := 'No Name';
                end;
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
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies that each customer begins on a new page.';
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
        Customer: Record Customer;
        CommentLine2: Record "Comment Line";
        CompanyInformation: Record "Company Information";
        Customer_Comment_ListCaptionLbl: Label 'Customer Comment List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Comment_Line__No__CaptionLbl: Label 'Customer';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
}

