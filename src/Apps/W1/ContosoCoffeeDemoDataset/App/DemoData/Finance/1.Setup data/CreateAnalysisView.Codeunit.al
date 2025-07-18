// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Finance;

using Microsoft.DemoTool.Helpers;

codeunit 5536 "Create Analysis View"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoAnalysis: Codeunit "Contoso Analysis";
        ContosoUtilities: Codeunit "Contoso Utilities";
        Dimension: Codeunit "Create Dimension";
    begin
        ContosoAnalysis.InsertAnalysisView(GeneralLedger(), GeneralLedgerLbl, '', ContosoUtilities.AdjustDate(19020101D), 1, '', '', '');
        ContosoAnalysis.InsertAnalysisView(SalesRevenue(), SalesRevenueLbl, '40000..49999', ContosoUtilities.AdjustDate(19020101D), 1, Dimension.AreaDimension(), Dimension.DepartmentDimension(), Dimension.CustomerGroupDimension());
    end;

    procedure GeneralLedger(): Code[10]
    begin
        exit(GeneralLedgerTok);
    end;

    procedure SalesRevenue(): Code[10]
    begin
        exit(SalesRevenueTok);
    end;

    var
        GeneralLedgerTok: Label 'GEN_LEDGER', MaxLength = 10;
        SalesRevenueTok: Label 'REVENUE', MaxLength = 10;
        GeneralLedgerLbl: Label 'General Ledger', MaxLength = 50;
        SalesRevenueLbl: Label 'Sales Revenue', MaxLength = 50;
}
