// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Document;

codeunit 137299 "SCM Prod. Whse. Pick Runner"
{
    Access = Internal;
    TableNo = "Production Order";

    trigger OnRun()
    begin
        Rec.SetHideValidationDialog(true);
        Rec.CreatePick(CopyStr(UserId(), 1, 50), 0, false, false, false);
    end;
}
