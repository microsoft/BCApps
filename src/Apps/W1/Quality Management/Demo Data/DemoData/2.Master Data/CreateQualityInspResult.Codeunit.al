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

    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
    begin
        ContosoQualityManagement.InsertQualityInspectionResult(Fail(), FailDescription(), 1, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::"Configuration only", '<>0', '<>""', 'No', Enum::"Qlty. Result Category"::"Not acceptable", Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
        ContosoQualityManagement.InsertQualityInspectionResult(InProgress(), InProgressDescription(), 0, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::"Configuration only", '', '', '', Enum::"Qlty. Result Category"::Uncategorized, Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
        ContosoQualityManagement.InsertQualityInspectionResult(Pass(), PassDescription(), 2, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::Promoted, '<>0', '<>""', 'Yes', Enum::"Qlty. Result Category"::Acceptable, Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
    end;

    procedure Fail(): Code[20]
    begin
        exit(CopyStr(QltyAutoConfigure.GetDefaultFailResult(), 1, 20));
    end;

    procedure FailDescription(): Text[100]
    begin
        exit(CopyStr(QltyAutoConfigure.GetDefaultFailResultDescription(), 1, 100));
    end;

    procedure InProgress(): Code[20]
    begin
        exit(CopyStr(QltyAutoConfigure.GetDefaultInProgressResult(), 1, 20));
    end;

    procedure InProgressDescription(): Text[100]
    begin
        exit(CopyStr(QltyAutoConfigure.GetDefaultInProgressResultDescription(), 1, 100));
    end;

    procedure Pass(): Code[20]
    begin
        exit(CopyStr(QltyAutoConfigure.GetDefaultPassResult(), 1, 20));
    end;

    procedure PassDescription(): Text[100]
    begin
        exit(CopyStr(QltyAutoConfigure.GetDefaultPassResultDescription(), 1, 100));
    end;

}
