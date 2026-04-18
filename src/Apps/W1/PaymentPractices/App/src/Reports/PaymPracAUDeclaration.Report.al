// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

report 680 "Paym. Prac. AU Declaration"
{
    Caption = 'Payment Times Declaration';
    DefaultLayout = Word;
    WordLayout = 'src/Reports/PaymPracAUDeclaration.docx';

    dataset
    {
        dataitem(Header; "Payment Practice Header")
        {
            column(No; "No.")
            {
            }
            column(StartingDate; "Starting Date")
            {
            }
            column(EndingDate; "Ending Date")
            {
            }
            column(TotalNumberOfPayments; "Total Number of Payments")
            {
            }
            column(TotalAmountOfPayments; "Total Amount of Payments")
            {
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(OfficerName; OfficerNameValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Officer Name';
                        ToolTip = 'Specifies the name of the officer signing the declaration.';
                    }
                    field(ABN; ABNValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ABN';
                        ToolTip = 'Specifies the Australian Business Number.';
                    }
                }
            }
        }
    }

    var
        OfficerNameValue: Text[100];
        ABNValue: Text[20];
}
