// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

codeunit 10985 "FR E-Invoice Lifecycle Error"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "FR E-Invoice Lifecycle" = m;
    TableNo = "FR E-Invoice Lifecycle";

    trigger OnRun()
    begin
        Rec."Processing Status" := Rec."Processing Status"::Failed;
        Rec."Last Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Rec."Last Error"));
        Rec.Modify();
    end;
}