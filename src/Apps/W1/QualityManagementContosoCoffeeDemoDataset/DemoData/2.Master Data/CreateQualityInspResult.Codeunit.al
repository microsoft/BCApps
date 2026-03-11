// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.Result;

codeunit 5595 "Create Quality Insp. Result"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        ContosoQualityManagement.InsertQualityInspectionResult(Fail(), QltyAutoConfigure.GetDefaultFailResultDescription(), 1, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::"Configuration only", '<>0', '<>""', 'No', Enum::"Qlty. Result Category"::"Not acceptable", Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
        ContosoQualityManagement.InsertQualityInspectionResult(InProgress(), QltyAutoConfigure.GetDefaultInProgressResultDescription(), 0, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::"Configuration only", '', '', '', Enum::"Qlty. Result Category"::Uncategorized, Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
        ContosoQualityManagement.InsertQualityInspectionResult(Pass(), QltyAutoConfigure.GetDefaultPassResultDescription(), 2, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::Promoted, '<>0', '<>""', 'Yes', Enum::"Qlty. Result Category"::Acceptable, Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
    end;

    procedure Fail(): Code[20]
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        exit(QltyAutoConfigure.GetDefaultFailResult());
    end;

    procedure InProgress(): Code[20]
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        exit(QltyAutoConfigure.GetDefaultInProgressResult());
    end;

    procedure Pass(): Code[20]
    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
    begin
        exit(QltyAutoConfigure.GetDefaultPassResult());
    end;
}
