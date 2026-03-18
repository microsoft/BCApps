// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Service.Contract;
using Microsoft.Service.Setup;

report 5987 "Expired Contract Lines - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ExpiredContractLinesTest.rdlc';
    Caption = 'Expired Contract Lines - Test';

    dataset
    {
        dataitem("Service Contract Line"; "Service Contract Line")
        {
            DataItemTableView = sorting("Contract Type", "Contract No.", "Line No.") where("Contract Type" = const(Contract), "Contract Status" = const(Signed));
            RequestFilterFields = "Contract No.", "Service Item No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(DelToDate; Format(DelToDate))
            {
            }
            column(ReasonCode2_Code_________ReasonCode2_Description; ReasonCode2.Code + ' ' + ReasonCode2.Description)
            {
            }
            column(Service_Contract_Line__TABLECAPTION__________ServItemFilters; TableCaption + ': ' + ServItemFilters)
            {
            }
            column(ServItemFilters; ServItemFilters)
            {
            }
            column(DescriptionLine; DescriptionLine)
            {
            }
            column(Service_Contract_Line__Contract_No__; "Contract No.")
            {
            }
            column(Service_Contract_Line_Description; Description)
            {
            }
            column(Service_Contract_Line__Contract_Expiration_Date_; Format("Contract Expiration Date"))
            {
            }
            column(Service_Contract_Line__Service_Item_No__; "Service Item No.")
            {
            }
            column(Service_Contract_Line__Line_Amount_; "Line Amount")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Expired_Contract_Lines___TestCaption; Expired_Contract_Lines___TestCaptionLbl)
            {
            }
            column(Delete_Contract_Lines_toCaption; Delete_Contract_Lines_toCaptionLbl)
            {
            }
            column(Reason_CodeCaption; Reason_CodeCaptionLbl)
            {
            }
            column(Service_Contract_Line__Contract_No__Caption; FieldCaption("Contract No."))
            {
            }
            column(Service_Contract_Line__Service_Item_No__Caption; FieldCaption("Service Item No."))
            {
            }
            column(Service_Contract_Line_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Service_Contract_Line__Contract_Expiration_Date_Caption; Service_Contract_Line__Contract_Expiration_Date_CaptionLbl)
            {
            }
            column(Service_Contract_Line__Line_Amount_Caption; FieldCaption("Line Amount"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                DescriptionLine := Text002;
            end;

            trigger OnPreDataItem()
            begin
                if DelToDate = 0D then
                    Error(Text000);
                ServMgtSetup.Get();
                if ServMgtSetup."Use Contract Cancel Reason" then
                    if ReasonCode2.Code = '' then
                        Error(Text001);
                if GetFilter("Contract No.") = '' then
                    SetFilter("Contract No.", '<>%1', '');
                SetFilter("Contract Expiration Date", '<>%1&<=%2', 0D, DelToDate);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Expired Contract Lines - Test';
        AboutText = 'Find contract lines that are expired up to a date that you specify. Then remove them from the service contracts.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DelToDate; DelToDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Remove Lines to';
                        ToolTip = 'Specifies the date up to which you want to check for expired contract lines. The report includes contract lines with contract expiration dates on or before this date.';
                    }
                    field(ReasonCode; ReasonCode2.Code)
                    {
                        ApplicationArea = Service;
                        Caption = 'Reason Code';
                        ToolTip = 'Specifies the reason code for the removal of lines from the contract. To see the existing reason codes, choose the field.';
                        TableRelation = "Reason Code".Code;

                        trigger OnValidate()
                        begin
                            ReasonCode2.Get(ReasonCode2.Code);
                        end;
                    }
                    field("Reason Code"; ReasonCode2.Description)
                    {
                        ApplicationArea = Service;
                        Caption = 'Reason Code Description';
                        Editable = false;
                        ToolTip = 'Specifies a description for the reason code.';
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

    trigger OnInitReport()
    begin
        if DelToDate = 0D then
            DelToDate := WorkDate();
        ServMgtSetup.Get();
    end;

    trigger OnPreReport()
    begin
        ServItemFilters := "Service Contract Line".GetFilters();
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ReasonCode2: Record "Reason Code";
        DescriptionLine: Text[60];
        DelToDate: Date;
        ServItemFilters: Text;

#pragma warning disable AA0074
        Text000: Label 'You must fill in the Remove to field.';
        Text001: Label 'You must fill in the Reason Code field.';
        Text002: Label 'Would be removed';
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Expired_Contract_Lines___TestCaptionLbl: Label 'Expired Contract Lines - Test';
        Delete_Contract_Lines_toCaptionLbl: Label 'Delete Contract Lines to';
        Reason_CodeCaptionLbl: Label 'Reason Code';
        Service_Contract_Line__Contract_Expiration_Date_CaptionLbl: Label 'Contract Expiration Date';

    procedure InitVariables(LocalDelToDate: Date; NewReasonCode: Code[10])
    begin
        DelToDate := LocalDelToDate;
        Clear(ReasonCode2);
        if NewReasonCode <> '' then
            ReasonCode2.Get(NewReasonCode);
    end;
}

