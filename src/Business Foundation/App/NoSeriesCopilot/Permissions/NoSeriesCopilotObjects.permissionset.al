// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

permissionset 330 "No. Series Copilot - Objects"
{
    Access = Internal;
    Assignable = false;
    Permissions = 
        codeunit "No. Series Cop. Add Intent"=X,
        codeunit "No. Series Cop. Change Intent"=X,
        codeunit "No. Series Cop. Tools Impl."=X,
        codeunit "No. Series Copilot Impl."=X,
        codeunit "No. Series Copilot Install"=X,
        codeunit "No. Series Copilot Register"=X,
        codeunit "No. Series Copilot Upgr. Tags"=X,
        page "No. Series Copilot Setup"=X,
        tabledata "No. Series Copilot Setup"=RIMD;

}