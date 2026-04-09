// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using System.Environment;

codeunit 695 "Payment Period Mgt."
{
    Access = Internal;

    procedure DetectReportingScheme(): Enum "Paym. Prac. Reporting Scheme"
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ReportingScheme: Enum "Paym. Prac. Reporting Scheme";
        IsHandled: Boolean;
    begin
        OnBeforeDetectReportingScheme(ReportingScheme, IsHandled);
        if IsHandled then
            exit(ReportingScheme);

        case EnvironmentInformation.GetApplicationFamily() of
            'GB':
                exit("Paym. Prac. Reporting Scheme"::"Dispute & Retention");
            'AU', 'NZ':
                exit("Paym. Prac. Reporting Scheme"::"Small Business");
            else
                exit("Paym. Prac. Reporting Scheme"::Standard);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDetectReportingScheme(var ReportingScheme: Enum "Paym. Prac. Reporting Scheme"; var IsHandled: Boolean)
    begin
    end;
}
