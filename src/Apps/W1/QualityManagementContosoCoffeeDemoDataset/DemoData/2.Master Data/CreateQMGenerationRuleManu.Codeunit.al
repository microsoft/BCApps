// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;
using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;

codeunit 5711 "Create QM Generation Rule Manu"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        ContosoQualityManagement.InsertQualityInspectionGenRule(5, 50, Enum::"Qlty. Gen. Rule Intent"::Production, CreateQMInspTemplateHdr.Production(), Database::"Prod. Order Routing Line", '', CreateQMInspTemplateHdr.BicycleChecklistDesc(), Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic");
    end;
}
