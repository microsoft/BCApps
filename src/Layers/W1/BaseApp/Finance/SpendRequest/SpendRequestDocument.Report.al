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
    WordMergeDataItem = SpendRequest;

    dataset
    {
        dataitem(SpendRequest; "Spend Request")
        {
            RequestFilterFields = "No.", Status, "Requested By";

            column(No; "No.")
            {
            }
            column(DocumentType; Type)
            {
            }
            column(Purpose; Purpose)
            {
            }
            column(RequestedBy; "Requested By")
            {
            }
            column(EmployeeName; EmployeeFullName)
            {
            }
            column(Status; Status)
            {
            }
            column(GLAccountNo; "G/L Account No.")
            {
            }
            column(CurrencyCode; "Currency Code")
            {
            }
            column(TotalExpectedAmount; "Total Expected Amount")
            {
            }
            column(TotalExpectedAmountLCY; "Total Expected Amount (LCY)")
            {
            }
            column(TotalSpentAmount; "Total Spent Amount (LCY)")
            {
            }
            column(ExpectedStartDate; "Expected Start Date")
            {
            }
            column(ExpectedEndDate; "Expected End Date")
            {
            }
            column(ApprovedByUserName; "Approved/Rejected by User Name")
            {
            }
            column(ApprovedAt; "Approved/Rejected At")
            {
            }

            dataitem(SpendRequestDetail; "Spend Request Detail")
            {
                DataItemLink = "Spend Request No." = field("No.");
                DataItemLinkReference = SpendRequest;

                column(LineNo; "Line No.")
                {
                }
                column(Description; Description)
                {
                }
                column(LineCurrencyCode; "Currency Code")
                {
                }
                column(ExpectedAmount; "Expected Amount")
                {
                }
                column(ExpectedAmountLCY; "Expected Amount (LCY)")
                {
                }
                column(DetailGLAccountNo; "G/L Account No.")
                {
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
            LayoutFile = 'SpendRequestDocument.docx';
            Caption = 'Spend Request Document';
        }
    }

    var
        EmployeeFullName: Text[200];
}
