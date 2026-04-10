// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

// Wrapper for providing report parameters.
codeunit 2846 "Post Inventory Cost to G/L"
{
    trigger OnRun()
    begin
        PostInvToGL.InitializeRequest(PostMethod::"per Entry", '', true);
        PostInvToGL.UseRequestPage(false);
        PostInvToGL.Run();
    end;

    var
        PostInvToGL: Report "Post Inventory Cost to G/L";
        PostMethod: Option "per Posting Group","per Entry";
}
