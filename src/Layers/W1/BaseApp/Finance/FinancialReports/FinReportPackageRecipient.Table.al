// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Security.AccessControl;
using System.Security.User;

table 8374 "Fin. Report Package Recipient"
{
    Caption = 'Financial Report Package Recipient';
    DataClassification = CustomerContent;
    DrillDownPageId = "Fin. Report Package Recipients";
    LookupPageId = "Fin. Report Package Recipients";

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            NotBlank = true;
            TableRelation = "Fin. Report Package Schedule"."Package Code";
            ToolTip = 'Specifies the financial report package code.';
            DataClassification = CustomerContent;
        }
        field(2; "Schedule Code"; Code[20])
        {
            Caption = 'Schedule Code';
            NotBlank = true;
            TableRelation = "Fin. Report Package Schedule"."Schedule Code" where("Package Code" = field("Package Code"));
            ToolTip = 'Specifies the schedule code.';
            DataClassification = CustomerContent;
        }
        field(3; "User ID"; Text[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ToolTip = 'Specifies the user that will receive the financial report.';
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSetup: Record "User Setup";
                FinReportPackageSchedule: Record "Fin. Report Package Schedule";
            begin
                TestField("User ID");
                FinReportPackageSchedule.Get("Package Code", "Schedule Code");
                if FinReportPackageSchedule."Send Email" then begin
                    UserSetup.Get("User ID");
                    UserSetup.TestField("E-Mail");
                end;
                CalcFields("User Full Name", "User Email");
            end;
        }
        field(4; "User Full Name"; Text[80])
        {
            CalcFormula = lookup(User."Full Name" where("User Name" = field("User ID")));
            Caption = 'User Full Name';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the user''s full name.';
        }
        field(5; "User Email"; Text[100])
        {
            Caption = 'User Email';
            CalcFormula = lookup("User Setup"."E-Mail" where("User ID" = field("User ID")));
            FieldClass = FlowField;
            Editable = false;
            ToolTip = 'Specifies the user''s email.';
        }
    }

    keys
    {
        key(PK; "Package Code", "Schedule Code", "User ID")
        {
            Clustered = true;
        }
    }

}