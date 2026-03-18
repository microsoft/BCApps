// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Utilities;

pageextension 9177 "Accessible Companies" extends "Accessible Companies"
{
    layout
    {
        modify(CompanyDisplayName)
        {
            ApplicationArea = All;
            Caption = 'Name';
            StyleExpr = NameStyleExpr;
            ToolTip = 'Specifies the display name that is defined for the company. If a display name is not defined, then the company name is used.';
        }
        addafter("Evaluation Company")
        {
            field(SetupStatus; CompanySetupStatuses.Get(Rec.Name))
            {
                ApplicationArea = All;
                Caption = 'Setup Status';
                ToolTip = 'Specifies the setup status of the company.';

                trigger OnDrillDown()
                var
                    AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
                begin
                    AssistedCompanySetupStatus.DrillDownSetupStatus(Rec.Name);
                end;
            }
        }
    }
    actions
    {
        modify("Create New Company")
        {
            Visible = true;
        }
    }

    trigger OnAfterGetRecord()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        CompanySetupStatuses.Set(Rec.Name, AssistedCompanySetupStatus.GetCompanySetupStatusValue(Rec.Name));
        if CompanySetupStatuses.Get(Rec.Name) = Enum::"Company Setup Status"::"In Progress" then
            NameStyleExpr := 'Subordinate'
        else
            NameStyleExpr := '';
    end;

    var
        CompanySetupStatuses: Dictionary of [Text, Enum "Company Setup Status"];
        NameStyleExpr: Text;
}
