// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 8371 "Financial Report Package"
{
    Caption = 'Financial Report Package';
    DataClassification = CustomerContent;
    DrillDownPageId = "Financial Report Packages";
    LookupPageId = "Financial Report Packages";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the unique code for the financial report package.';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the financial report package.';
            DataClassification = CustomerContent;
        }
        field(3; InternalDescription; Text[500])
        {
            Caption = 'Internal Description';
            ToolTip = 'Specifies the internal description of the financial report package.';
            DataClassification = CustomerContent;
        }
        field(4; "No. of Schedules"; Integer)
        {
            CalcFormula = count("Fin. Report Package Schedule" where("Package Code" = field(Code)));
            Caption = 'No. of Schedules';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of schedules associated with this financial report package.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        FinReportPackageReport: Record "Fin. Report Package Report";
        FinReportPackageSchedule: Record "Fin. Report Package Schedule";
    begin
        FinReportPackageReport.SetRange("Package Code", Code);
        FinReportPackageReport.DeleteAll(true);

        FinReportPackageSchedule.SetRange("Package Code", Code);
        FinReportPackageSchedule.DeleteAll(true);
    end;
}