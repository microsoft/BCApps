// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Finance;

using Microsoft.Finance.FinancialReports;
using System.Upgrade;

codeunit 5188 "Periods Definition Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Column Layout" = rm;

    trigger OnUpgradePerCompany()
    begin
        UpdatePeriodsColumnHeaders();
    end;

    local procedure UpdatePeriodsColumnHeaders()
    var
        CreateColumnLayoutName: Codeunit "Create Column Layout Name";
        UpgradeTag: Codeunit "Upgrade Tag";
        PeriodsName: Code[10];
    begin
        if UpgradeTag.HasUpgradeTag(GetPeriodsDynamicDateHeaderUpgradeTag()) then
            exit;

        PeriodsName := CreateColumnLayoutName.PeriodsDefinition();

        UpdatePeriodsColumnLine(PeriodsName, 10000, CurrentPeriodLbl);
        UpdatePeriodsColumnLine(PeriodsName, 20000, '');
        UpdatePeriodsColumnLine(PeriodsName, 30000, '');

        UpgradeTag.SetUpgradeTag(GetPeriodsDynamicDateHeaderUpgradeTag());
    end;

    local procedure UpdatePeriodsColumnLine(ColumnLayoutName: Code[10]; LineNo: Integer; NewHeader: Text[30])
    var
        ColumnLayout: Record "Column Layout";
    begin
        if not ColumnLayout.Get(ColumnLayoutName, LineNo) then
            exit;

        ColumnLayout.Validate("Column Header", NewHeader);
        ColumnLayout.Validate("Include Date In Header", Enum::ColumnHeaderDateType::MonthAndYear);
        ColumnLayout.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetPeriodsDynamicDateHeaderUpgradeTag());
    end;

    local procedure GetPeriodsDynamicDateHeaderUpgradeTag(): Code[250]
    begin
        exit('MS-636218-PeriodsDefinitionDynamicDateHeader-20260522');
    end;

    var
        CurrentPeriodLbl: Label 'Current period', MaxLength = 30;
}
