// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using Microsoft.HumanResources.Employee;

report 6850 "Spend Request Document"
{
    Caption = 'Spend Request';
    DefaultRenderingLayout = WordLayout;
    PreviewMode = PrintLayout;
    WordMergeDataItem = SpendRequest;

    dataset
    {
        dataitem(SpendRequest; "Spend Request")
        {
            RequestFilterFields = "No.", Status, "Requested By";

            column(No; "No.")
            {
                IncludeCaption = true;
            }
            column(Purpose; Purpose)
            {
                IncludeCaption = true;
            }
            column(RequestedBy; "Requested By")
            {
                IncludeCaption = true;
            }
            column(EmployeeName; EmployeeFullName)
            {
            }
            column(Status; Status)
            {
                IncludeCaption = true;
            }
            column(GLAccountNo; "G/L Account No.")
            {
                IncludeCaption = true;
            }
            column(CurrencyCode; "Currency Code")
            {
                IncludeCaption = true;
            }
            column(TotalExpectedAmount; "Total Expected Amount")
            {
                IncludeCaption = true;
            }
            column(TotalExpectedAmountLCY; "Total Expected Amount (LCY)")
            {
                IncludeCaption = true;
            }
            column(TotalSpentAmount; "Total Spent Amount (LCY)")
            {
                IncludeCaption = true;
            }
            column(ExpectedStartDate; "Expected Start Date")
            {
                IncludeCaption = true;
            }
            column(ExpectedEndDate; "Expected End Date")
            {
                IncludeCaption = true;
            }
            column(ApprovedByUserName; "Approved/Rejected by User Name")
            {
                IncludeCaption = true;
            }
            column(ApprovedAt; "Approved/Rejected At")
            {
                IncludeCaption = true;
            }
            dataitem(SpendRequestDetail; "Spend Request Detail")
            {
                DataItemLink = "Spend Request No." = field("No.");
                DataItemLinkReference = SpendRequest;

                column(LineNo; "Line No.")
                {
                    IncludeCaption = true;
                }
                column(Description; Description)
                {
                    IncludeCaption = true;
                }
                column(LineCurrencyCode; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(ExpectedAmount; "Expected Amount")
                {
                    IncludeCaption = true;
                }
                column(ExpectedAmountLCY; "Expected Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(DetailGLAccountNo; "G/L Account No.")
                {
                    IncludeCaption = true;
                }
            }
            dataitem(SpendRequestGLEntries; "Spend Request to G/L Link")
            {
                DataItemLink = "Spend Request No." = field("No.");
                DataItemLinkReference = SpendRequest;

                column(GLAccount; "G/L Account No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDescription; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(PostingDate; "Posting Date")
                {
                    IncludeCaption = true;
                }
                column(PostedDocumentNo; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(PostedAmount; "Amount")
                {
                    IncludeCaption = true;
                }
            }

            trigger OnAfterGetRecord()
            var
                Employee: Record Employee;
            begin
                Employee.SetLoadFields("First Name", "Last Name");
                if Employee.Get("Requested By") then
                    EmployeeFullName := Employee."First Name" + ' ' + Employee."Last Name"
                else
                    EmployeeFullName := '';
            end;
        }
    }
    rendering
    {
        layout(WordLayout)
        {
            Type = Word;
            LayoutFile = './Finance/SpendRequest/SpendRequestDocument.docx';
            Caption = 'Spend Request Document';
        }
    }
    labels
    {
        ReportLbl = 'Spend Request';
        EmployeeFullNameLbl = 'Employee Name';
        DetailsHeaderLbl = 'Details';
        PostedEntriesHeaderLbl = 'Posted Entries';
    }

    var
        EmployeeFullName: Text;
}
