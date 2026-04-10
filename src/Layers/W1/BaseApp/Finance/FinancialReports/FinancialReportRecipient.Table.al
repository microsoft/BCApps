// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Security.AccessControl;
using System.Security.User;

table 8362 "Financial Report Recipient"
{
    Caption = 'Financial Report Recipient';
    DataClassification = CustomerContent;
    LookupPageId = "Financial Report Recipients";
    DrillDownPageId = "Financial Report Recipients";

    fields
    {
        field(1; "Financial Report Name"; Code[10])
        {
            Caption = 'Financial Report Name';
            TableRelation = "Financial Report";
            ToolTip = 'Specifies the name of the financial report.';
        }
        field(2; "Financial Report Schedule Code"; Code[20])
        {
            Caption = 'Financial Report Schedule Code';
            TableRelation = "Financial Report Schedule".Code where("Financial Report Name" = field("Financial Report Name"));
            ToolTip = 'Specifies the financial report schedule code.';
        }
        field(3; "User ID"; Text[65])
        {
            Caption = 'User ID';
            NotBlank = true;
            TableRelation = User."User Name";
            ToolTip = 'Specifies the user that will receive the financial report.';
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                FinancialReportSchedule: Record "Financial Report Schedule";
                UserSetup: Record "User Setup";
            begin
                TestField("User ID");
                FinancialReportSchedule.Get("Financial Report Name", "Financial Report Schedule Code");
                if FinancialReportSchedule."Send Email" then begin
                    UserSetup.Get("User ID");
                    UserSetup.TestField("E-Mail");
                end;
                CalcFields("User Full Name");
            end;
        }
        field(4; "User Full Name"; Text[100])
        {
            CalcFormula = lookup(User."Full Name" where("User Name" = field("User ID")));
            Caption = 'User Full Name';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the full name of the user.';
        }
    }

    keys
    {
        key(PK; "Financial Report Name", "Financial Report Schedule Code", "User ID")
        {
            Clustered = true;
        }
    }
}