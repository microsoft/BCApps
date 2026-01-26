// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

report 28092 "PDC Acknowledgement Receipt"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Journal/PDCAcknowledgementReceipt.rdlc';
    Caption = 'PDC Acknowledgement Receipt';

    dataset
    {
        dataitem("Post Dated Check Line 2"; "Post Dated Check Line")
        {
            column(Addr_2_; Addr[2])
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(Addr_1_; Addr[1])
            {
            }
            column(Addr_3_; Addr[3])
            {
            }
            column(Addr_4_; Addr[4])
            {
            }
            column(Addr_5_; Addr[5])
            {
            }
            column(Addr_6_; Addr[6])
            {
            }
            column(Addr_7_; Addr[7])
            {
            }
            column(Addr_8_; Addr[8])
            {
            }
            column(Title; Title)
            {
            }
            column(Post_Dated_Check_Line_2__Check_Date_; Format("Check Date"))
            {
            }
            column(Post_Dated_Check_Line_2__Check_No__; "Check No.")
            {
            }
            column(Post_Dated_Check_Line_2_Amount; Amount)
            {
            }
            column(Post_Dated_Check_Line_2__Applies_to_Doc__Type_; "Applies-to Doc. Type")
            {
            }
            column(Post_Dated_Check_Line_2__Applies_to_Doc__No__; "Applies-to Doc. No.")
            {
            }
            column(CurrencyCode; CurrencyCode)
            {
            }
            column(RecordNum; RecordNum)
            {
            }
            column(Post_Dated_Check_Line_2_Comment; Comment)
            {
            }
            column(CheckCount; CheckCount)
            {
            }
            column(Post_Dated_Check_Line_2_Template_Name; "Template Name")
            {
            }
            column(Post_Dated_Check_Line_2_Batch_Name; "Batch Name")
            {
            }
            column(Post_Dated_Check_Line_2_Account_Type; "Account Type")
            {
            }
            column(Post_Dated_Check_Line_2_Account_No_; "Account No.")
            {
            }
            column(Post_Dated_Check_Line_2_Line_Number; "Line Number")
            {
            }
            column(Post_Dated_Checks_Acknowledgement_ReceiptCaption; Post_Dated_Checks_Acknowledgement_ReceiptCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Post_Dated_Check_Line_2_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Post_Dated_Check_Line_2__Check_Date_Caption; Post_Dated_Check_Line_2__Check_Date_CaptionLbl)
            {
            }
            column(Post_Dated_Check_Line_2__Check_No__Caption; FieldCaption("Check No."))
            {
            }
            column(Post_Dated_Check_Line_2__Applies_to_Doc__Type_Caption; FieldCaption("Applies-to Doc. Type"))
            {
            }
            column(Post_Dated_Check_Line_2__Applies_to_Doc__No__Caption; FieldCaption("Applies-to Doc. No."))
            {
            }
            column(Comments_Caption; Comments_CaptionLbl)
            {
            }
            column(Signature_over_the_Printed_NameCaption; Signature_over_the_Printed_NameCaptionLbl)
            {
            }
            column(Total_No__of_Checks_Caption; Total_No__of_Checks_CaptionLbl)
            {
            }
            column(Received_By_Caption; Received_By_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if "Check Date" <= WorkDate() then
                    Marked := 'BANK'
                else
                    Marked := '';
                if "Currency Code" <> '' then
                    CurrencyCode := "Currency Code"
                else begin
                    GLSetup.Get();
                    CurrencyCode := GLSetup."LCY Code";
                end;
                RecordNum += 1;
                if "Account Type" = "Account Type"::Customer then begin
                    Title := 'Customer Name';
                    if Cust.Get("Account No.") then
                        FormatAddr.Customer(Addr, Cust);
                end else
                    if "Account Type" = "Account Type"::Vendor then begin
                        Title := 'Vendor Name';
                        if Vend.Get("Account No.") then
                            FormatAddr.Vendor(Addr, Vend);
                    end;
            end;

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("Check Date");
                CheckCount := Count;
                RecordNum := 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        LastFieldNo: Integer;
        Marked: Text[10];
        CurrencyCode: Code[3];
        Addr: array[8] of Text[100];
        FormatAddr: Codeunit "Format Address";
        Cust: Record Customer;
        Vend: Record Vendor;
        GLSetup: Record "General Ledger Setup";
        Title: Text[30];
        CheckCount: Integer;
        RecordNum: Integer;
        Post_Dated_Checks_Acknowledgement_ReceiptCaptionLbl: Label 'Post Dated Checks Acknowledgement Receipt';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Post_Dated_Check_Line_2__Check_Date_CaptionLbl: Label 'Check Date';
        Comments_CaptionLbl: Label 'Comments:';
        Signature_over_the_Printed_NameCaptionLbl: Label 'Signature over the Printed Name';
        Total_No__of_Checks_CaptionLbl: Label 'Total No. of Checks:';
        Received_By_CaptionLbl: Label 'Received By:';
}

