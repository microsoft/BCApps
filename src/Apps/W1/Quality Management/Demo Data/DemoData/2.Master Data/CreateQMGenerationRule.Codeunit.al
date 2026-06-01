// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;

codeunit 5598 "Create QM Generation Rule"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        ContosoQualityManagement.InsertQualityInspectionGenRule(4, 40, Enum::"Qlty. Gen. Rule Intent"::Purchase, CreateQMInspTemplateHdr.Receive(), Database::"Purchase Line", '', CreateQMInspTemplateHdr.ReceiveDesc(), Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic");
    end;
}
