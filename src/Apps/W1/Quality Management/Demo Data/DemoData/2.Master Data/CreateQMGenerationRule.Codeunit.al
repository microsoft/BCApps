// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoData.Warehousing;
using Microsoft.DemoTool.Helpers;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;

codeunit 5598 "Create QM Generation Rule"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        Item: Record Item;
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
        CreateWhseItemCategory: Codeunit "Create Whse Item Category";
        ItemFilter: Text[2048];
    begin
        Item.SetRange("Item Category Code", CreateWhseItemCategory.Beans());
        ItemFilter := CopyStr(Item.GetView(false), 1, MaxStrLen(ItemFilter));
        ContosoQualityManagement.InsertQualityInspectionGenRule(3, 30, Enum::"Qlty. Gen. Rule Intent"::Purchase, CreateQMInspTemplateHdr.Beans(), Database::"Purchase Line", '', CreateQMInspTemplateHdr.BeansDesc(), Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic", ItemFilter);
        ContosoQualityManagement.InsertQualityInspectionGenRule(4, 40, Enum::"Qlty. Gen. Rule Intent"::Purchase, CreateQMInspTemplateHdr.Receive(), Database::"Purchase Line", '', CreateQMInspTemplateHdr.ReceiveDesc(), Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic");
    end;
}
