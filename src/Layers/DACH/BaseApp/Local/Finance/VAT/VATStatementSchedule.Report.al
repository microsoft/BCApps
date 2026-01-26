// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

report 11010 "VAT Statement Schedule"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/VATStatementSchedule.rdlc';
    Caption = 'VAT Statement Schedule';

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            RequestFilterFields = "Statement Template Name", Name;
            column(VAT_Statement_Name_Statement_Template_Name; "Statement Template Name")
            {
            }
            column(VAT_Statement_Name_Name; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                column(FORMAT_TODAY_0_0______FORMAT_TIME_0_0_; Format(Today, 0, 0) + ' ' + Format(Time, 0, 0))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(USERID; UserId)
                {
                }
                column(VAT_Statement_Name___Statement_Template_Name_; "VAT Statement Name"."Statement Template Name")
                {
                }
                column(VAT_Statement_Name__Name; "VAT Statement Name".Name)
                {
                }
                column(VAT_Statement_Line__New_Page_; "New Page")
                {
                }
                column(VAT_Statement_Line_Print; Print)
                {
                }
                column(Totaling; Totaling)
                {
                }
                column(VAT_Statement_Line_Type; Type)
                {
                }
                column(VAT_Statement_Line_Description; Description)
                {
                }
                column(VAT_Statement_Line__Row_No__; "Row No.")
                {
                }
                column(VAT_Statement_Line__Gen__Posting_Type_; "Gen. Posting Type")
                {
                }
                column(VAT_Statement_Line__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
                {
                }
                column(VAT_Statement_Line__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
                {
                }
                column(VAT_Statement_Line__Amount_Type_; "Amount Type")
                {
                }
                column(PRINT_ML; Format(Print))
                {
                }
                column(NEWPAGE_ML; Format("New Page"))
                {
                }
                column(VAT_Statement_Line_Statement_Template_Name; "Statement Template Name")
                {
                }
                column(VAT_Statement_Line_Statement_Name; "Statement Name")
                {
                }
                column(VAT_Statement_Line_Line_No_; "Line No.")
                {
                }
                column(VAT_Statement_ScheduleCaption; VAT_Statement_ScheduleCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(VAT_Statement_Name___Statement_Template_Name_Caption; VAT_Statement_Name___Statement_Template_Name_CaptionLbl)
                {
                }
                column(VAT_Statement_Name__NameCaption; VAT_Statement_Name__NameCaptionLbl)
                {
                }
                column(VAT_Statement_Line__New_Page_Caption; FieldCaption("New Page"))
                {
                }
                column(VAT_Statement_Line_PrintCaption; FieldCaption(Print))
                {
                }
                column(TotalingCaption; TotalingCaptionLbl)
                {
                }
                column(VAT_Statement_Line_TypeCaption; FieldCaption(Type))
                {
                }
                column(VAT_Statement_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(VAT_Statement_Line__Row_No__Caption; FieldCaption("Row No."))
                {
                }
                column(VAT_Statement_Line__VAT_Prod__Posting_Group_Caption; FieldCaption("VAT Prod. Posting Group"))
                {
                }
                column(VAT_Statement_Line__VAT_Bus__Posting_Group_Caption; FieldCaption("VAT Bus. Posting Group"))
                {
                }
                column(VAT_Statement_Line__Gen__Posting_Type_Caption; FieldCaption("Gen. Posting Type"))
                {
                }
                column(VAT_Statement_Line__Amount_Type_Caption; FieldCaption("Amount Type"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    case Type of
                        Type::"Row Totaling":
                            Totaling := "Row Totaling";
                        Type::"Account Totaling":
                            Totaling := "Account Totaling"
                        else
                            Totaling := '';
                    end;
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

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
        Totaling: Text[30];
        VAT_Statement_ScheduleCaptionLbl: Label 'VAT Statement Schedule';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VAT_Statement_Name___Statement_Template_Name_CaptionLbl: Label 'VAT Statement Template';
        VAT_Statement_Name__NameCaptionLbl: Label 'VAT Statement Name';
        TotalingCaptionLbl: Label 'Totaling';
}

