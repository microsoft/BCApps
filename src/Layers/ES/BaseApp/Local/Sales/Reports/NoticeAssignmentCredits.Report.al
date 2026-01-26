// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

report 7000050 "Notice Assignment Credits"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/NoticeAssignmentCredits.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Notice Assignement Credits';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = false;
            RequestFilterFields = "No.";
            column(CompanyAddr_1_; CompanyAddr[1])
            {
            }
            column(CompanyAddr_2_; CompanyAddr[2])
            {
            }
            column(CompanyAddr_3_; CompanyAddr[3])
            {
            }
            column(CompanyAddr_4_; CompanyAddr[4])
            {
            }
            column(CompanyAddr_5_; CompanyAddr[5])
            {
            }
            column(CompanyAddr_6_; CompanyAddr[6])
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CustAddr_1_; CustAddr[1])
            {
            }
            column(CustAddr_2_; CustAddr[2])
            {
            }
            column(CustAddr_3_; CustAddr[3])
            {
            }
            column(CustAddr_4_; CustAddr[4])
            {
            }
            column(CustAddr_5_; CustAddr[5])
            {
            }
            column(CustAddr_6_; CustAddr[6])
            {
            }
            column(CustAddr_7_; CustAddr[7])
            {
            }
            column(CustAddr_8_; CustAddr[8])
            {
            }
            column(USERID; UserId)
            {
            }
            column(STRSUBSTNO_Text1100000_BankAddress2_1__; StrSubstNo(Text1100000, BankAddress2[1]))
            {
            }
            column(STRSUBSTNO_Text1100001_BankAddress2_1__; StrSubstNo(Text1100001, BankAddress2[1]))
            {
            }
            column(BankAddress2_1_____; BankAddress2[1] + '.')
            {
            }
            column(CompanyInfo_City_Text1100002_FORMAT_DeliveryDate; CompanyInfo.City + Text1100002 + Format(DeliveryDate, 0, Text1100003) + Text1100004 + Format(DeliveryDate, 0, Text1100005) + Text1100004 + Format(DeliveryDate, 0, Text1100006))
            {
            }
            column(BankAddress2_2_; BankAddress2[2])
            {
            }
            column(BankAddress2_3_; BankAddress2[3])
            {
            }
            column(BankAddress2_4_; BankAddress2[4])
            {
            }
            column(BankAddress2_5_; BankAddress2[5])
            {
            }
            column(BankAddress2_6_; BankAddress2[6])
            {
            }
            column(BankAddress2_7_; BankAddress2[7])
            {
            }
            column(BankAddress2_8_; BankAddress2[8])
            {
            }
            column(BankAddress2_1_; BankAddress2[1])
            {
            }
            column(BankAddress2_9_; BankAddress2[9])
            {
            }
            column(Customer_Customer__No__; Customer."No.")
            {
            }
            column(DeliveryDate; DeliveryDate)
            {
            }
            column(BankAccNo; BankAccNo)
            {
            }
            column(BankAccName; BankAccName)
            {
            }
            column(FactorCCCNo; FactorCCCNo)
            {
            }
            column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(Notice_Assignment_CreditsCaption; Notice_Assignment_CreditsCaptionLbl)
            {
            }
            column(Dear_Sirs_Caption; Dear_Sirs_CaptionLbl)
            {
            }
            column(We_are_pleased_to_inform_you_that_as_of_the_effective_date_below_Caption; We_are_pleased_to_inform_you_that_as_of_the_effective_date_below_CaptionLbl)
            {
            }
            column(invoices__we_have_created_and_the_ones_we_may_create_in_the_futureCaption; invoices__we_have_created_and_the_ones_we_may_create_in_the_futureCaptionLbl)
            {
            }
            column(As_a_result_of_this__the_ownership_of_all_the_creditsCaption; As_a_result_of_this__the_ownership_of_all_the_creditsCaptionLbl)
            {
            }
            column(Yours_faithfully_Caption; Yours_faithfully_CaptionLbl)
            {
            }
            column(of_the_previous_details_stated__will_only_be_possible_if_authorized_byCaption; of_the_previous_details_stated__will_only_be_possible_if_authorized_byCaptionLbl)
            {
            }
            column(Finally__we_would_like_to_highlight_that_any_changeCaption; Finally__we_would_like_to_highlight_that_any_changeCaptionLbl)
            {
            }
            column(must_be_paid_by_bank_wire_transfer_or_check_to_Caption; must_be_paid_by_bank_wire_transfer_or_check_to_CaptionLbl)
            {
            }
            column(Consequently__every_payment_for_any_invoiceCaption; Consequently__every_payment_for_any_invoiceCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.Customer(CustAddr, Customer);
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompanyInfo.TestField(City);
                FormatAddr.Company(CompanyAddr, CompanyInfo);

                if BankAccNo <> '' then begin
                    BankAcc.Get(BankAccNo);
                    BankAccName := BankAcc.Name;
                    FormatAddr.BankAcc(BankAddress, BankAcc);
                end;

                for i := 1 to 8 do
                    BankAddress2[i] := BankAddress[i];
                BankAddress2[9] := Text1100007 + FactorCCCNo;
                CompressArray(BankAddress2);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeliveryDate; DeliveryDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delivery date';
                        ToolTip = 'Specifies a number to identify the operations declaration.';
                    }
                    field(BankAccNo; BankAccNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the number of the bank account.';

                        trigger OnValidate()
                        begin
                            BankAccNoOnAfterValidate();
                        end;
                    }
                    field(BankAccName; BankAccName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account Name';
                        Editable = false;
                        Enabled = true;
                        ToolTip = 'Specifies the name of the bank account.';
                    }
                    field(FactorCCCNo; FactorCCCNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Factor CCC No.';
                        NotBlank = true;
                        ToolTip = 'Specifies the current account number for the factoring (factor) entity where the client must pay the invoices.';

                        trigger OnValidate()
                        begin
                            for i := 1 to 8 do
                                BankAddress2[i] := BankAddress[i];
                            BankAddress2[9] := Text1100007 + FactorCCCNo;
                            CompressArray(BankAddress2);
                        end;
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
        Text1100000: Label 'we have signed a Factoring Agreement with %1.';
        Text1100001: Label 'in which your company may be involved, have been assigned irrevocably to %1.';
        Text1100002: Label ', a ';
        Text1100003: Label '<Day>', Locked = true;
        Text1100004: Label ' de ';
        Text1100005: Label '<Month text>', Locked = true;
        Text1100006: Label '<Year4>', Locked = true;
        Text1100007: Label 'Nú CCC del Factor: ', Locked = true;
        CompanyInfo: Record "Company Information";
        BankAcc: Record "Bank Account";
        DeliveryDate: Date;
        CustAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        FormatAddr: Codeunit "Format Address";
        BankAccName: Text[100];
        BankAccNo: Code[20];
        FactorCCCNo: Text[20];
        BankAddress: array[8] of Text[100];
        BankAddress2: array[9] of Text[100];
        i: Integer;
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        Notice_Assignment_CreditsCaptionLbl: Label 'Notice Assignment Credits';
        Dear_Sirs_CaptionLbl: Label 'Dear Sirs,';
        We_are_pleased_to_inform_you_that_as_of_the_effective_date_below_CaptionLbl: Label 'We are pleased to inform you that as of the effective date below,';
        invoices__we_have_created_and_the_ones_we_may_create_in_the_futureCaptionLbl: Label '(invoices) we have created and the ones we may create in the future';
        As_a_result_of_this__the_ownership_of_all_the_creditsCaptionLbl: Label 'As a result of this, the ownership of all the credits';
        Yours_faithfully_CaptionLbl: Label 'Yours faithfully,';
        of_the_previous_details_stated__will_only_be_possible_if_authorized_byCaptionLbl: Label 'of the previous details stated, will only be possible if authorized by';
        Finally__we_would_like_to_highlight_that_any_changeCaptionLbl: Label 'Finally, we would like to highlight that any change';
        must_be_paid_by_bank_wire_transfer_or_check_to_CaptionLbl: Label 'must be paid by bank/wire transfer or check to:';
        Consequently__every_payment_for_any_invoiceCaptionLbl: Label 'Consequently, every payment for any invoice';

    local procedure BankAccNoOnAfterValidate()
    begin
        if BankAccNo <> '' then begin
            BankAcc.Get(BankAccNo);
            BankAccName := BankAcc.Name;
            FormatAddr.BankAcc(BankAddress, BankAcc);
        end;
    end;
}

