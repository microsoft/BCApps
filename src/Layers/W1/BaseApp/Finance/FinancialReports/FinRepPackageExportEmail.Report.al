// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Utilities;

report 8371 "Fin. Rep. Package Export Email"
{
    Caption = 'Financial Report Export Email';
    DefaultRenderingLayout = Email;

    dataset
    {
        dataitem(Root; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(GreetingTxt; GreetingTxt) { }
            column(ReportContext; ReportContext) { }
            column(AutomatedEmailTxt; AutomatedEmailTxt) { }
            column(Link_UrlText; LinkLbl) { }
            column(Link_Url; LinkUrl) { }

            trigger OnAfterGetRecord()
            begin
                ReportContext := StrSubstNo(ReportContextTxt, ReportDescription);
                FinRepPackageSchedule.SetRecFilter();
                LinkUrl := GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"Fin. Report Package Schedules", FinRepPackageSchedule, true);
            end;
        }
    }

    rendering
    {
        layout(Email)
        {
            Caption = 'Fin. Rep. Package Export Email (Word)';
            LayoutFile = './Finance/FinancialReports/FinRepPackageExportEmail.docx';
            Summary = 'The Fin. Rep. Package Export Email (Word) provides an email body layout.';
            Type = Word;
        }
    }

    var
        FinRepPackageSchedule: Record "Fin. Report Package Schedule";
        AutomatedEmailTxt: Label 'Financial report packages are sent automatically and cannot be replied to. You can change when and how you receive financial report packages:';
        GreetingTxt: Label 'Hello,';
        LinkLbl: Label 'Financial Report Package Schedules';
        ReportContextTxt: Label 'You are registered to receive the financial report package %1. Please find the financial reports attached.', Comment = '%1 = Financial Report Package Code';
        LinkUrl: Text;
        ReportContext: Text;
        ReportDescription: Text;

    procedure SetContext(var FinRepPackageScheduleIn: Record "Fin. Report Package Schedule"; ReportDescriptionIn: Text)
    begin
        FinRepPackageSchedule := FinRepPackageScheduleIn;
        ReportDescription := ReportDescriptionIn;
    end;
}