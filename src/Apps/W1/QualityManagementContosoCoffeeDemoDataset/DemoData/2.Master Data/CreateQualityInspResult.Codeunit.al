// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DemoData.QualityManagement;

using Microsoft.DemoTool.Helpers;
using Microsoft.QualityManagement.Configuration.Result;

codeunit 5595 "Create Quality Insp. Result"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoQualityManagement: Codeunit "Contoso Quality Management";
    begin
        ContosoQualityManagement.InsertQualityInspectionResult(Fail(), FailDescLbl, 1, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::"Configuration only", '<>0', '<>""', 'No', Enum::"Qlty. Result Category"::"Not acceptable", Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
        ContosoQualityManagement.InsertQualityInspectionResult(InProgress(), InProgressDescLbl, 0, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::"Configuration only", '', '', '', Enum::"Qlty. Result Category"::Uncategorized, Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
        ContosoQualityManagement.InsertQualityInspectionResult(Pass(), PassDescLbl, 2, Enum::"Qlty. Result Copy Behavior"::"Automatically copy the result", Enum::"Qlty. Result Visibility"::Promoted, '<>0', '<>""', 'Yes', Enum::"Qlty. Result Category"::Acceptable, Enum::"Qlty. Result Finish Allowed"::"Allow Finish");
    end;

    procedure Fail(): Code[20]
    begin
        exit(FailTok);
    end;

    procedure InProgress(): Code[20]
    begin
        exit(InProgressTok);
    end;

    procedure Pass(): Code[20]
    begin
        exit(PassTok);
    end;

    var
        FailTok: Label 'FAIL', MaxLength = 20;
        InProgressTok: Label 'INPROGRESS', MaxLength = 20;
        PassTok: Label 'PASS', MaxLength = 20;

        FailDescLbl: Label 'Fail', MaxLength = 100;
        InProgressDescLbl: Label 'In Progress', MaxLength = 100;
        PassDescLbl: Label 'Pass', MaxLength = 100;
}
