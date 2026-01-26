// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.History;
using System.Utilities;

report 3010533 "ESR Coupon"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/ESRCoupon.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales ESR Coupon';
    Permissions =;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Head; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed", "Payment Method Code";
            RequestFilterHeading = 'Sales Invoice Header';
            column(HeadNo; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(EsrSetupESRMemberName1; EsrSetup."ESR Member Name 1")
                {
                }
                column(EsrSetupESRMemberName2; EsrSetup."ESR Member Name 2")
                {
                }
                column(EsrSetupESRMemberName3; EsrSetup."ESR Member Name 3")
                {
                }
                column(EsrSetupBeneficiaryText; EsrSetup."Beneficiary Text")
                {
                }
                column(EsrSetupBeneficiary; EsrSetup.Beneficiary)
                {
                }
                column(EsrSetupBeneficiary2; EsrSetup."Beneficiary 2")
                {
                }
                column(EsrSetupBeneficiary3; EsrSetup."Beneficiary 3")
                {
                }
                column(EsrSetupBeneficiary4; EsrSetup."Beneficiary 4")
                {
                }
                column(EsrSetupESRAccountNo; EsrSetup."ESR Account No.")
                {
                }
                column(CurrencyCode; CurrencyCode)
                {
                }
                column(RefNo; RefNo)
                {
                }
                column(EsrAdr1; EsrAdr[1])
                {
                }
                column(EsrAdr2; EsrAdr[2])
                {
                }
                column(EsrAdr3; EsrAdr[3])
                {
                }
                column(EsrAdr4; EsrAdr[4])
                {
                }
                column(EsrAdr5; EsrAdr[5])
                {
                }
                column(DocType; DocType)
                {
                }
                column(CodingLine; CodingLine)
                {
                }
                column(COPYSTRAmtTxt101; CopyStr(AmtTxt, 10, 1))
                {
                }
                column(COPYSTRAmtTxt91; CopyStr(AmtTxt, 9, 1))
                {
                }
                column(COPYSTRAmtTxt81; CopyStr(AmtTxt, 8, 1))
                {
                }
                column(COPYSTRAmtTxt71; CopyStr(AmtTxt, 7, 1))
                {
                }
                column(COPYSTRAmtTxt61; CopyStr(AmtTxt, 6, 1))
                {
                }
                column(COPYSTRAmtTxt51; CopyStr(AmtTxt, 5, 1))
                {
                }
                column(COPYSTRAmtTxt41; CopyStr(AmtTxt, 4, 1))
                {
                }
                column(COPYSTRAmtTxt31; CopyStr(AmtTxt, 3, 1))
                {
                }
                column(COPYSTRAmtTxt21; CopyStr(AmtTxt, 2, 1))
                {
                }
                column(COPYSTRAmtTxt11; CopyStr(AmtTxt, 1, 1))
                {
                }
                column(OutputNo; OutputNo)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    OutputNo += 1;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ReqCopies + 1);  // On integer table
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                EsrSetup := ESRSetupRequestForm;
                CHMgt.PrepareEsr(Head, EsrSetup, EsrType, EsrAdr, AmtTxt, CurrencyCode, DocType, RefNo, CodingLine);
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
                    field(ReqCopies; ReqCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field("ESRSetupRequestForm.""Bank Code"""; ESRSetupRequestForm."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ESR Bank';
                        TableRelation = "ESR Setup";
                        ToolTip = 'Specifies the code of the ESR bank.';
                    }
                    field(EsrType; EsrType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ESR System';
                        OptionCaption = 'Based on ESR Bank,ESR,ESR+';
                        ToolTip = 'Specifies which ESR system to apply to the transaction. ESR systems include Based on ESR Bank, ESR, and ESR+.';
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

    var
        EsrSetup: Record "ESR Setup";
        ESRSetupRequestForm: Record "ESR Setup";
        CHMgt: Codeunit CHMgt;
        EsrAdr: array[8] of Text[100];
        ReqCopies: Integer;
        EsrType: Option "Based on ESR Bank",ESR,"ESR+";
        AmtTxt: Text[30];
        CurrencyCode: Code[10];
        DocType: Text[10];
        RefNo: Text[35];
        CodingLine: Text[100];
        OutputNo: Integer;
}

